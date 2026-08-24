if {$argc < 1} {
    puts "ERROR: No testbench name provided."
    exit 1
}

set testbench [lindex $argv 0]

set project_file "C:/Users/muram/fpga-signal-processing/vivado/fpga_signal_processing/fpga_signal_processing.xpr"

puts "Running $testbench"

open_project $project_file

set_property top $testbench [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sim_1

if {[catch {
    launch_simulation -mode behavioral
} result]} {
    puts "ERROR: Could not launch $testbench"
    puts $result

    catch {close_sim}
    close_project

    exit 2
}

catch {run all}

puts "TEST_COMPLETED: $testbench"

catch {close_sim}
close_project

exit 0
