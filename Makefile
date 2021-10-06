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

.PHONY: verilog emu clean
