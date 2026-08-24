# Run all behavioral simulations and print a summary.

set testbenches {
    FirFilterTestbench
    MagnitudeSquaredTestbench
    PeakDetectorTestbench
    FftCoreTestbench
    FrequencyAnalysisPipelineTestbench
    AxiLiteControlTestbench
    FullPipelineTestbench
}

set passed_tests {}
set failed_tests {}


puts "Starting FPGA verification test suite"


foreach testbench $testbenches {

 
    puts "Running $testbench"


    catch {close_sim}

    set_property top $testbench [get_filesets sim_1]
    set_property top_lib xil_defaultlib [get_filesets sim_1]

    update_compile_order -fileset sim_1

    set launch_failed 0

    if {[catch {launch_simulation -mode behavioral} launch_result]} {

        puts ""
        puts "ERROR: Could not launch $testbench"
        puts $launch_result

        lappend failed_tests $testbench
        set launch_failed 1
    }

    if {$launch_failed} {
        catch {close_sim}
        continue
    }

    set run_failed 0

    if {[catch {run all} run_result]} {

        puts ""
        puts "ERROR: Simulation failed for $testbench"
        puts $run_result

        lappend failed_tests $testbench
        set run_failed 1
    }

    if {$run_failed} {
        catch {close_sim}
        continue
    }

    # Find the XSim log for this run.
    set log_file [file normalize \
        "C:/Users/muram/fpga-signal-processing/vivado/fpga_signal_processing/fpga_signal_processing.sim/sim_1/behav/xsim/simulate.log"]

    set test_failed 0

    if {[file exists $log_file]} {

        set file_handle [open $log_file r]
        set log_text [read $file_handle]
        close $file_handle

        # Any FAIL message marks the test as failed.
        if {[string first "FAIL:" $log_text] >= 0} {
            set test_failed 1
        }

        # A simulation error also marks the test as failed.
        if {[string first "ERROR:" $log_text] >= 0} {
            set test_failed 1
        }

    } else {

        puts "WARNING: Could not find simulation log."
        set test_failed 1
    }

    if {$test_failed} {

        puts ""
        puts "RESULT: $testbench FAILED"

        lappend failed_tests $testbench

    } else {

        puts ""
        puts "RESULT: $testbench PASSED"

        lappend passed_tests $testbench
    }

    catch {close_sim}
}


puts "TEST SUMMARY"


foreach testbench $testbenches {

    if {[lsearch -exact $passed_tests $testbench] >= 0} {

        puts [format "%-40s PASS" $testbench]

    } else {

        puts [format "%-40s FAIL" $testbench]
    }
}


puts "Passed: [llength $passed_tests]"
puts "Failed: [llength $failed_tests]"
puts "Total:  [llength $testbenches]"


if {[llength $failed_tests] == 0} {

    puts "ALL TESTS PASSED"

} else {

    puts "SOME TESTS FAILED"
}
