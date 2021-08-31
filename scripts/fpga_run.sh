#!/bin/bash

BIT_FILE_BIN=role.bit.bin
BIT_FILE=fpga/board/nf_card/build/$BIT_FILE_BIN
BIT_TARGET_LOC=/lib/firmware

FPGA_CFG_LOC=/sys/class/fpga_manager/fpga0/firmware
FPGA_BR_LOC=/sys/class/fpga_bridge/br0/set
FPGA_FLAG_LOC=/sys/class/fpga_manager/fpga0/flags

SW_LOC=build
RISCV_ELF_LOADER_BIN=riscv_elf_loader
RISCV_ELF_LOADER=$SW_LOC/$RISCV_ELF_LOADER_BIN

ELF_FILE=build/$1-riscv64-nutshell_nf.elf
ELF_FILE_RT=ready-to-run/rtthread.elf

# check if .bit.bin file is ready in this repository
if [ ! -e $BIT_FILE ]
then
	echo "Error: No binary bitstream file is ready"
	exit -1
fi

#=======================
# Step 1: FPGA configuration
#=======================
# Step 1.1: Copy .bit.bin file to target board
cp $BIT_FILE $BIT_TARGET_LOC

# Step 1.2 configuration of FPGA logic
echo 0 > $FPGA_FLAG_LOC
echo $BIT_FILE_BIN > $FPGA_CFG_LOC

#=======================
# Step 2: Launch evaluations of different benchmark suites
#=======================
gcc scripts/riscv_elf_loader.c -lpthread -o ${RISCV_ELF_LOADER}
if [ "$1" == "rtthread" ];
then
$RISCV_ELF_LOADER $ELF_FILE_RT
else
$RISCV_ELF_LOADER $ELF_FILE
fi

RESULT=$?
  
if [ $RESULT -eq 0 ]; then
  echo "Hit good trap"
else
  echo "Hit bad trap"
fi

#=======================
# Step 3: Check if all benchmarks passed
#=======================

if [ $RESULT -ne 0 ]
then
	exit -1
fi
