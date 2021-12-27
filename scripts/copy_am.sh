#!/bin/bash

VERSION=$1

cp ${AM_HOME}/apps/coremark/build/coremark-riscv64-nutshell_nf_$VERSION.elf build/coremark-riscv64-nutshell_nf.elf
cp ${AM_HOME}/apps/dhrystone/build/dhrystone-riscv64-nutshell_nf_$VERSION.elf build/dhrystone-riscv64-nutshell_nf.elf
cp ${AM_HOME}/apps/microbench/build/microbench-riscv64-nutshell_nf_$VERSION.elf build/microbench-riscv64-nutshell_nf.elf
