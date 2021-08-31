set bd_design system_top

open_bd_design [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/${bd_design}/${bd_design}.bd]

set_property synth_checkpoint_mode None [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/${bd_design}/${bd_design}.bd]
generate_target all [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/${bd_design}/${bd_design}.bd]

validate_bd_design
save_bd_design
close_bd_design ${bd_design}

set report_dir ${script_dir}/build/report
file mkdir ${report_dir}

# setting Synthesis options
set_property strategy {Vivado Synthesis defaults} [get_runs synth_1]
# keep module port names in the netlist
set_property STEPS.SYNTH_DESIGN.ARGS.FLATTEN_HIERARCHY {none} [get_runs synth_1]

# synthesizing user design
synth_design -top ${topmodule} -part ${device}

# report potential combinatinal loops
check_timing -verbose

# Design optimization
opt_design

# Output systhesis utilization and timing reports
report_utilization -hierarchical -file ${report_dir}/synth_util.rpt
report_timing_summary -delay_type max -max_paths 10 -file ${report_dir}/synth_timing.rpt
report_clock_utilization -file ${report_dir}/synth_clock_util.rpt

write_debug_probes -force ${script_dir}/build/debug_nets.ltx

# Placement
place_design

# Physical design optimization
phys_opt_design


# Output utilization and timing reports.
report_utilization -hierarchical -file ${report_dir}/post_place_util.rpt
report_timing_summary -delay_type max -max_paths 10 -file ${report_dir}/post_place_timing.rpt
report_clock_utilization -file ${report_dir}/post_place_clock_util.rpt

# routing
route_design

# Output utilization and timing reports.
report_utilization -hierarchical -file ${report_dir}/post_route_util.rpt
report_timing_summary -delay_type max -max_paths 10 -file ${report_dir}/post_route_timing.rpt
report_clock_utilization -file ${report_dir}/post_route_clock_util.rpt

write_bitstream -cell [get_cells mpsoc_i/role_cell/inst] -force ${script_dir}/build/role.bit
write_cfgmem -format BIN -interface SMAPx32 -disablebitswap -loadbit "up 0x0 ${script_dir}/build/role.bit" -force ${script_dir}/build/role.bit.bin
