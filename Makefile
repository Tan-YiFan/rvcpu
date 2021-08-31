SCALA_FILE = $(shell find ./src/main/scala -name '*.scala')
VERILOG_FILE = $(shell find ./vsrc -name '*.v')

USE_READY_TO_RUN_NEMU = true

.DEFAULT_GOAL = verilog

include Makefile.include

build/SimTop.v: $(SCALA_FILE)
	mkdir -p build
	mill chiselModule.runMain $(SCALA_OPTS)

verilog: build/SimTop.v

emu: verilog
	$(MAKE) -C ./difftest $(DIFFTEST_OPTS) emu

clean:
	rm -rf build out

.PHONY: verilog emu clean
