SCALA_FILE = $(shell find ./src/main/scala -name '*.scala' 2>/dev/null)
VERILOG_FILE = $(shell find ./vsrc -name '*.v')
SYSTEMVERILOG_FILE = $(shell find ./vsrc -name '*.sv')

USE_READY_TO_RUN_NEMU = true

.DEFAULT_GOAL = verilog

include Makefile.include

ifeq ($(wildcard src/*), )
	SCALA_CODE = "false"
else
	SCALA_CODE = "true"
endif

build/SimTop.v: $(SCALA_FILE)
	mkdir -p build
ifeq ($(SCALA_CODE), "true")
	mill chiselModule.runMain $(SCALA_OPTS)
endif
	cp -r vsrc/* build

verilog: build/SimTop.v

sim-verilog: verilog

emu: verilog
	$(MAKE) -C ./difftest emu $(DIFFTEST_OPTS)

clean:
	rm -rf build out

NOOP_HOME = $(abspath .)
test:
	export NOOP_HOME=$(NOOP_HOME)
	rm -rf build
	mkdir -p build
	ln -s -r vsrc/* build
	make emu -j12 NOOP_HOME=$(NOOP_HOME) NEMU_HOME=.
	./build/emu -b 0 -e 0 --dump-wave -i  ./ready-to-run/coremark-riscv64-nutshell.bin --diff ./riscv64-nemu-interpreter-so || true
	#./build/emu -b 0 -e 0 -i ./ready-to-run/dhrystone-riscv64-nutshell.bin --diff ./riscv64-nemu-interpreter-so || true
	#./build/emu -b 0 -e 0 -i ./ready-to-run/microbench-riscv64-nutshell.bin --diff ./riscv64-nemu-interpreter-so || true
	#./build/emu -b 0 -e 0 -i ./ready-to-run/rtthread.bin --no-diff || true

bit:
	rm -rf build
	mkdir -p build
	cp -r vsrc/* build
	export NOOP_HOME=$(pwd)
	export PATH=${PATH}:~/Xilinx/Vivado/2019.2/bin/
	rm -rf fpga/board/nf_card/build/
	make -C fpga PRJ=project BOARD=nf_card DUT_FREQ=100 GEN_BITSTREAM=true
	
.PHONY: verilog emu clean
