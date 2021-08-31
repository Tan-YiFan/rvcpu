//==========================================================
// MIPS CPU binary executable file loader
//
// Main Function:
// 1. Loads binary excutable file into distributed memory
// 2. Waits MIPS CPU for finishing program execution
//
// Author:
// Yisong Chang (changyisong@ict.ac.cn)
//
// Revision History:
// 14/06/2016	v0.0.1	Add cycle counte support
// 24/01/2018	v0.0.2	ARMv8 support to avoid unalignment fault
//==========================================================
#include <elf.h>
#include <fcntl.h>
#include <memory.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <errno.h>
#include <signal.h>
#include <time.h>

#include <inttypes.h>

#include <assert.h>
#include <sys/time.h>
#include <sys/wait.h>

#include <pthread.h>
#include <termios.h>

#define MIPS_CPU_MEM_TOTAL_SIZE (1UL << 30)
#define MIPS_CPU_MEM_SHOW_SIZE (1 << 14)
#define MIPS_CPU_MEM_BASE_ADDR 0x4800000000UL
#define MIPS_CPU_FINISH_DW_OFFSET 0x00010000

#define MIPS_CPU_REG_TOTAL_SIZE 0x1000
#define MIPS_CPU_REG_BASE_ADDR 0x80000000

void *mem_map_base;
volatile uint32_t *mem_map_base_mmio;
volatile uint64_t *mem_map_base_mem;

void *reg_map_base;
volatile uint32_t *reset_base;

int fd;

#define mips_addr(p) (map_base + (uintptr_t)(p))

#define ALIGN_MASK_8_BYTES 0x07
#define ALIGN_MASK_4_BYTES 0x03

int set_interface_attribs(int fd, int speed, int parity, int should_block);

void loader(char *file) {
  FILE *fp = fopen(file, "rb");
  assert(fp);

  Elf64_Ehdr *elf;
  Elf64_Phdr *ph = NULL;

  int i;
  uint8_t buf[4096];
  uint8_t buf_temp[16];

  // the program header should be located within the first
  // 4096 byte of the ELF file
  fread(buf, 4096, 1, fp);
  elf = (void *)buf;

  // TODO: fix the magic number with the correct one
  const uint32_t elf_magic = 0x464c457f; // 0xBadC0de;
  uint32_t *p_magic = (uint32_t *)buf;
  // check the magic number
  assert(*p_magic == elf_magic);

  // our MIPS CPU can only reset with PC = 0
  assert(elf->e_entry == 0x80000000);

  for (i = 0, ph = (void *)buf + elf->e_phoff; i < elf->e_phnum; i++) {
    // scan the program header table, load each segment into memory
    if (ph[i].p_type == PT_LOAD) {
      uint64_t va = ph[i].p_vaddr - 0x80000000;

      if (va >= MIPS_CPU_MEM_TOTAL_SIZE) {
        // printf("out of ideal memory range, continue..\n");
        continue;
      }

      uint64_t size = 0;

      // TODO: read the content of the segment from the ELF file
      // to the memory region [VirtAddr, VirtAddr + FileSiz)

      // align va to 64-bit boundary
      if (va & ALIGN_MASK_8_BYTES) {
        assert((va & ALIGN_MASK_4_BYTES) == 0);
        assert(ph[i].p_filesz >= 4);

        memset(buf_temp, 0, 16);
        fseek(fp, ph[i].p_offset, SEEK_SET);
        fread(buf_temp, 4, 1, fp); // read out unaligned size to temporal buffer

        *(mem_map_base_mmio + (va >> 2)) = *(uint32_t *)buf_temp;

        va += 4;
        size += 4;
      }

      // aligned copy
      while ((size + 8) <= ph[i].p_filesz) {
        memset(buf_temp, 0, 16);
        fseek(fp, ph[i].p_offset + size, SEEK_SET);
        fread(buf_temp, 8, 1, fp); // read out unaligned size to temporal buffer

        *(mem_map_base_mem + (va >> 3)) = *(uint64_t *)buf_temp;

        va += 8;
        size += 8;
      }

      // check if remaining a 32-bit word
      if (size != ph[i].p_filesz) {
        uint64_t lastsz = ph[i].p_filesz - size;

        assert((va & ALIGN_MASK_4_BYTES) == 0);
        assert(lastsz == 4);

        memset(buf_temp, 0, 16);
        fseek(fp, ph[i].p_offset + size, SEEK_SET);
        fread(buf_temp, 4, 1, fp);

        *(mem_map_base_mmio + (va >> 2)) = *(uint32_t *)buf_temp;
        va += 4;
      }

      // fseek(fp, ph[i].p_offset, SEEK_SET);
      // fread(mips_addr(va), ph[i].p_filesz, 1, fp);

      // TODO: zero the memory region
      // [VirtAddr + FileSiz, VirtAddr + MemSiz)
      // printf("va: %08x mips_addr: %08x\n", init_va, mips_addr(init_va +
      // ph[i].p_filesz)); printf("memsz: %lld, filesz %lld\n", ph[i].p_memsz,
      // ph[i].p_filesz);
      uint64_t rest = ph[i].p_memsz - ph[i].p_filesz;
      uint64_t zero_sz = 0;
      if (zero_sz < rest && (va & ALIGN_MASK_8_BYTES)) {
        *(mem_map_base_mmio + (va >> 2)) = 0;
        va += 4;
        zero_sz += 4;
      }
      while ((zero_sz + 8) <= rest) {
        *(mem_map_base_mem + (va >> 3)) = 0;
        va += 8;
        zero_sz += 8;
      }
      if (zero_sz < rest) {
        if ((zero_sz + 4) != rest)
          exit(-1);
        *(mem_map_base_mmio + (va >> 2)) = 0;
      }
    }
  }

  fclose(fp);
}

int set_interface_attribs(int fd, int speed, int parity, int should_block) {
  struct termios tty;
  memset(&tty, 0, sizeof tty);
  if (tcgetattr(fd, &tty) != 0) {
    perror("tcgetattr");
    return -1;
  }

  cfsetospeed(&tty, speed);
  cfsetispeed(&tty, speed);

  tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8; // 8-bit chars
  // disable IGNBRK for mismatched speed tests; otherwise receive break
  // as \000 chars
  tty.c_iflag &= ~IGNBRK; // disable break processing
  tty.c_lflag = 0;        // no signaling chars, no echo,
  // no canonical processing
  tty.c_oflag = 0;     // no remapping, no delays
  tty.c_cc[VMIN] = 0;  // read doesn't block
  tty.c_cc[VTIME] = 5; // 0.5 seconds read timeout

  tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl

  tty.c_cflag |= (CLOCAL | CREAD); // ignore modem controls,
  // enable reading
  tty.c_cflag &= ~(PARENB | PARODD); // shut off parity
  tty.c_cflag |= parity;
  tty.c_cflag &= ~CSTOPB;
  tty.c_cflag &= ~CRTSCTS;

  tty.c_cc[VMIN] = 0;
  tty.c_cc[VTIME] = 5; // 0.5 seconds read timeout

  if (tcsetattr(fd, TCSANOW, &tty) != 0) {
    perror("tcsetattr");
    return -1;
  }
  return 0;
}

int should_exit;

void *read_uart(void *dev) {
  int timeout = 1200;
  time_t prev = time(NULL);
  char line_buffer[64];
  int buffer_pos = 0;
  int reach_end = 0;
  int uart_fd = open((char *)dev, O_RDWR | O_NOCTTY | O_SYNC | O_NONBLOCK);
  if (uart_fd < 0) {
    fprintf(stderr, "opening %s: %s\n", dev, strerror(errno));
    exit(1);
  }
  // set speed to 115,200 bps, 8n1 (no parity)
  set_interface_attribs(uart_fd, B115200, 0, 0);

  while (time(NULL) - prev <= timeout && (reach_end == 0 || should_exit == 0)) {
    char ch;
    int n = read(uart_fd, &ch, sizeof(ch));
    if (n > 0) {
      if (ch == '\n') {
        line_buffer[buffer_pos++] = '\0';
        if (strncmp(line_buffer, "Exit with code = ", 17) == 0) {
          reach_end = 1;
        }
        printf("%s\n", line_buffer);
        buffer_pos = 0;
      } else if (ch == '\r') {
        // skip
      } else {
        line_buffer[buffer_pos++] = ch;
      }
    }
  }

  if (time(NULL) - prev > timeout) {
    printf("\nUART read timeout, output maybe incomplete.\n");
  }

  close(uart_fd);

  return NULL;
}

void init_map() {
  int i;

  fd = open("/dev/mem", O_RDWR | O_SYNC);
  if (fd == -1) {
    perror("init_map open failed:");
    exit(1);
  }

  // physical mapping to virtual memory
  mem_map_base = mmap(NULL, MIPS_CPU_MEM_TOTAL_SIZE, PROT_READ | PROT_WRITE,
                      MAP_SHARED, fd, MIPS_CPU_MEM_BASE_ADDR);

  if (mem_map_base == NULL) {
    perror("init_map mmap failed:");
    close(fd);
    exit(1);
  }

  mem_map_base_mmio = (uint32_t *)mem_map_base;
  mem_map_base_mem = (uint64_t *)mem_map_base;

  // physical mapping to virtual memory
  reg_map_base = mmap(NULL, MIPS_CPU_REG_TOTAL_SIZE, PROT_READ | PROT_WRITE,
                      MAP_SHARED, fd, MIPS_CPU_REG_BASE_ADDR);

  if (reg_map_base == NULL) {
    perror("init_map reg mmap failed:");
    close(fd);
    exit(1);
  }

  reset_base = (uint32_t *)reg_map_base;

  // clear 16KB memory region
  for (i = 0; i < MIPS_CPU_MEM_SHOW_SIZE / sizeof(int); i++)
    mem_map_base_mmio[i] = 0;
}

void reset(int val) {
  // Need to fetch result before the next reset.
  //*(map_base_mmio + MIPS_CPU_FINISH_DW_OFFSET) = 0xFFFFFFFF;
  *(reset_base) = val;
}

void finish_map() {
  mem_map_base_mmio = NULL;
  mem_map_base_mem = NULL;
  munmap(mem_map_base, MIPS_CPU_MEM_TOTAL_SIZE);
  mem_map_base = NULL;

  reset_base = NULL;
  munmap(reg_map_base, MIPS_CPU_REG_TOTAL_SIZE);
  reg_map_base = NULL;

  close(fd);
}

void show_help(char *cmd) {
  fprintf(
      stderr,
      "Usage:\n"
      "    %s <elf file>    Load ELF file to memory and start CPU execution\n"
      "    %s               Reset CPU\n",
      cmd, cmd);
}

int main(int argc, char *argv[]) {
  int result = -1;
  pthread_t thread;
  // set stdout with the property of no buffer
  setvbuf(stdout, NULL, _IONBF, 0);

  if (argc > 2) {
    show_help(argv[0]);
    exit(-1);
  }

  /* mapping the MIPS memory space into the address space of this program */
  init_map();

  /* resetting CPU */
  reset(1);

  if (argc == 2) {
    int timeout = 1200;
    time_t prev = time(NULL);

    /* loading binary executable file to MIPS memory space */
    loader(argv[1]);

    should_exit = 0;

    pthread_create(&thread, NULL, read_uart, "/dev/ttyPS1");

    sleep(1);

    /* releasing CPU reset */
    reset(0);

    while (time(NULL) - prev <= timeout && *(uint32_t *)((char *)reset_base + 0x8) == -1)
      ;

    should_exit = 1;

    result = *(uint32_t *)((char *)reset_base + 0x8);

    pthread_join(thread, NULL);
  }

  finish_map();

  return result;
}
