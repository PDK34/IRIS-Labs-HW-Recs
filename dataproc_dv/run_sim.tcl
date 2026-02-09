# Vivado simulation script
create_project rvsoc_sim sim_output -part xc7a35tcpg236-1 -force
set_property simulator_language Verilog [current_project]
add_files ../rvsoc.v
add_files ../rvsoc_wrapper.v
add_files ../picorv32.v
add_files ../simpleuart.v
add_files ../spimemio.v
add_files ../spiflash.v
add_files data_proc_wrapper.v
add_files data_proc.v
add_files data_prod.v
add_files -fileset sim_1 dataproc_tb.v
set_property top dataproc_tb [get_filesets sim_1]
# Add hex files using absolute path from script location
set script_dir [file dirname [file normalize [info script]]]
add_files -fileset sim_1 -norecurse $script_dir/firmware.hex
add_files -fileset sim_1 -norecurse $script_dir/image.hex
launch_simulation
run all
close_sim
close_project
exit
