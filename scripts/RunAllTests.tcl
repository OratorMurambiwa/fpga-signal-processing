# Run all FPGA behavioral simulations and print a summary.

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

set log_file [file normalize \
    "C:/Users/muram/fpga-signal-processing/vivado/fpga_signal_processing/fpga_signal_processing.sim/sim_1/behav/xsim/simulate.log"]


puts "Starting FPGA verification test suite"



foreach testbench $testbenches {

    puts "Running $testbench"
  

    # Close the previous simulation.
    catch {close_sim}

    # Give Vivado a moment to release simulator files/processes.
    after 1500


    # Set the next simulation top.
    if {[catch {
        set_property top $testbench [get_filesets sim_1]
        set_property top_lib xil_defaultlib [get_filesets sim_1]
    } top_result]} {

        puts "ERROR: Could not set $testbench as simulation top."
        puts $top_result

        lappend failed_tests $testbench
        continue
    }


    # Update compile order.
    # Retry once if Vivado has a temporary spawn failure.
    set compile_ok 0

    for {set attempt 1} {$attempt <= 2} {incr attempt} {

        if {![catch {
            update_compile_order -fileset sim_1
        } compile_result]} {

            set compile_ok 1
            break
        }

        puts "WARNING: Compile-order attempt $attempt failed."
        puts $compile_result

        after 2000
    }


    if {!$compile_ok} {

        puts ""
        puts "RESULT: $testbench FAILED TO PREPARE"

        lappend failed_tests $testbench
        continue
    }


    # Launch behavioral simulation.
    set launch_ok 0

    for {set attempt 1} {$attempt <= 2} {incr attempt} {

        if {![catch {
            launch_simulation -mode behavioral
        } launch_result]} {

            set launch_ok 1
            break
        }

        puts "WARNING: Simulation launch attempt $attempt failed."
        puts $launch_result

        catch {close_sim}
        after 2000
    }


    if {!$launch_ok} {

        puts ""
        puts "RESULT: $testbench FAILED TO LAUNCH"

        lappend failed_tests $testbench
        continue
    }


    # launch_simulation normally runs 1000 ns automatically.
    # Continue until the testbench reaches $finish.
    catch {run all}


    # Check the simulator log.
    set test_failed 0

    if {[file exists $log_file]} {

        set file_handle [open $log_file r]
        set log_text [read $file_handle]
        close $file_handle


        # Explicit FAIL messages mean the test failed.
        if {[string first "FAIL:" $log_text] >= 0} {
            set test_failed 1
        }


        # Detect major simulator errors.
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

    # Give Windows/Vivado time to release XSim processes.
    after 1500
}


puts "TEST SUMMARY"



foreach testbench $testbenches {

    if {[lsearch -exact $passed_tests $testbench] >= 0} {

        puts [format "%-40s PASS" $testbench]

    } elseif {[lsearch -exact $failed_tests $testbench] >= 0} {

        puts [format "%-40s FAIL" $testbench]

    } else {

        puts [format "%-40s NOT RUN" $testbench]
    }
}



puts "Passed: [llength $passed_tests]"
puts "Failed: [llength $failed_tests]"
puts "Total:  [llength $testbenches]"



if {[llength $failed_tests] == 0} {

    puts ""
    puts "ALL TESTS PASSED"

} else {

    puts ""
    puts "SOME TESTS FAILED"
}
