set search_path {. /eda/tsmc.90g/aci/sc-x/synopsys /eda/synopsys/syn_vF-2011.09-SP2/libraries/syn}

#set LIBRARY_SLOW slow
#set LIBRARY_FAST fast

set symbol_library {}
set target_library {slow.db}

set synthetic_library {dw_foundation.sldb}
  
set link_library {* slow.db fast.db dw_foundation.sldb}

set LIBRARY_SLOW slow
set LIBRARY_FAST fast
   

set verilogout_no_tri true
set verilogout_show_unconnected_pins true
set bus_naming_style {%s[%d]}
define_name_rules myrules \
  -case_insensitive \
  -allowed {A-Za-z0-9_} \
  -first_restricted "0-9_" \
  -last_restricted "_" \
  -equal_ports_nets


set mydesign intra_pred
set acs_hdl_source "../rtl_468/"	
acs_read_hdl -recurse -format verilog -verbose $mydesign -no_elaborate > $mydesign.acs.log
elaborate $mydesign > $mydesign.elab.log
uniquify
current_design $mydesign
set_wire_load_mode top
set_min_library slow.db -min_version fast.db

set  CLK_PERIOD 2.5
set  CLK_NAME   clk   	 		

#create_clock -period $CLK_PERIOD -name clk [get_ports $CLK_NAME]
create_clock -period $CLK_PERIOD -waveform {0 1.25} -name $CLK_NAME

#set clock_ports [get_ports $CLK_NAME]

set_propagated_clock clk
set_dont_touch_network clk

#set_drive 0 [get_ports $CLK_NAME]
#set_drive 0 [$CLK_NAME]

set_input_delay [expr ($CLK_PERIOD * 0)] -clock clk  [all_inputs]
set_output_delay [expr ($CLK_PERIOD * 0)] -clock clk  [all_outputs]
#remove_input_delay $clock_ports
remove_input_delay clk



set_boundary_optimization $mydesign true
set_fix_multiple_port_nets -feedthroughs -all -buffer_constants

link
check_design > check_design.rep

compile_ultra -no_autoungroup


write_file -format verilog -hierarchy -output ./SYN/$mydesign.vnet
write_sdc ./SYN/$mydesign.sdc
report_area > ./REP/$mydesign.area.txt
report_timing > ./REP/$mydesign.timing.txt
report_power > ./REP/$mydesign.power.txt
report_qor > ./REP/$mydesign.qor.txt


