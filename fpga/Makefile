include Makefile.check
include ../Makefile.include

default: project

STANDALONE ?= false
GEN_BITSTREAM ?= false

# vivado project name
PRJ ?= myproject
PRJ_FULL = $(PRJ)-$(BOARD)
VIVADO_FLAG = -nolog -nojournal -notrace

#--------------------------------------------------------------------
# Project building and implementation
#--------------------------------------------------------------------

PRJ_ROOT = board/$(BOARD)/build/$(PRJ_FULL)
XPR_FILE = $(PRJ_ROOT)/$(PRJ_FULL).xpr
ifeq ($(GEN_BITSTREAM), "true")
	BITSTREAM_DEP=board/$(BOARD)/build/role.bit.bin
else
	BITSTREAM_DEP=""
endif
$(XPR_FILE):
	make -C .. BOARD=$(BOARD)
	vivado $(VIVADO_FLAG) -mode batch -source board/$(BOARD)/mk.tcl -tclargs $(PRJ_FULL) $(STANDALONE) $(GEN_BITSTREAM) $(DUT_FREQ)

project: $(XPR_FILE)

bootgen:
	cd boot && hsi $(VIVADO_FLAG) -source mk.tcl -tclargs $(PRJ_FULL) $(STANDALONE)

vivado: $(XPR_FILE) $(BITSTREAM_DEP)
	vivado $(VIVADO_FLAG) $(XPR_FILE) &

.PHONY: default project vivado bootgen
