set script_dir  [file dirname [info script]]

set_param board.repoPaths ${script_dir}/boards

set device xczu19eg-ffvc1760-2-e
set board sugon:nf_card:part0:2.0

# Add files for system top
set src_files [list \
  "[file normalize "${script_dir}/rtl"]" \
]

# Add files for constraint
set xdc_files [list \
 "[file normalize "${script_dir}/constr/top.xdc"]" \
]

source ${script_dir}/../common.tcl
