`timescale 1ns / 1ps

module flags_tb;

    integer passed;
    integer failed;

    reg clk;
    reg reset;

    reg update_zero;
    reg update_carry;

    reg zero_in;
    reg carry_in;

    wire zero_flag;
    wire carry_flag;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    flags uut (
        .clk(clk),
        .reset(reset),

        .update_zero(update_zero),
        .update_carry(update_carry),

        .zero_in(zero_in),
        .carry_in(carry_in),

        .zero_flag(zero_flag),
        .carry_flag(carry_flag)
    );

    // 10 ns clock
    always #5 clk = ~clk;


    // --------------------------------------------------
    // TESTS
    // --------------------------------------------------

    initial begin

        passed = 0;
        failed = 0;

        clk          = 0;
        reset        = 0;
        update_zero  = 0;
        update_carry = 0;
        zero_in      = 0;
        carry_in     = 0;


        // --------------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------------

        reset = 1;

        #10;

        reset = 0;

        if ((zero_flag == 1'b0) &&
            (carry_flag == 1'b0)) begin

            $display("PASS: Flags reset to Z=0 C=0");
            passed = passed + 1;

        end
        else begin

            $display("FAIL: Flags reset incorrectly");
            $display("      Z=%b C=%b",
                     zero_flag,
                     carry_flag);

            failed = failed + 1;

        end


        // --------------------------------------------------
        // TEST 2: UPDATE BOTH FLAGS
        // --------------------------------------------------

        zero_in      = 1;
        carry_in     = 1;
        update_zero  = 1;
        update_carry = 1;

        #10;

        if ((zero_flag == 1'b1) &&
            (carry_flag == 1'b1)) begin

            $display("PASS: Both flags updated to Z=1 C=1");
            passed = passed + 1;

        end
        else begin

            $display("FAIL: Both flags update failed");
            $display("      Z=%b C=%b",
                     zero_flag,
                     carry_flag);

            failed = failed + 1;

        end


        // --------------------------------------------------
        // TEST 3: UPDATE ZERO ONLY
        // CARRY MUST BE PRESERVED
        // --------------------------------------------------

        zero_in      = 0;
        carry_in     = 0;

        update_zero  = 1;
        update_carry = 0;

        #10;

        if ((zero_flag == 1'b0) &&
            (carry_flag == 1'b1)) begin

            $display("PASS: Zero updated, carry preserved");
            passed = passed + 1;

        end
        else begin

            $display("FAIL: Zero-only update incorrect");
            $display("      Z=%b C=%b",
                     zero_flag,
                     carry_flag);

            failed = failed + 1;

        end


        // --------------------------------------------------
        // TEST 4: UPDATE CARRY ONLY
        // ZERO MUST BE PRESERVED
        // --------------------------------------------------

        zero_in      = 1;
        carry_in     = 0;

        update_zero  = 0;
        update_carry = 1;

        #10;

        if ((zero_flag == 1'b0) &&
            (carry_flag == 1'b0)) begin

            $display("PASS: Carry updated, zero preserved");
            passed = passed + 1;

        end
        else begin

            $display("FAIL: Carry-only update incorrect");
            $display("      Z=%b C=%b",
                     zero_flag,
                     carry_flag);

            failed = failed + 1;

        end


        // --------------------------------------------------
        // TEST 5: NO UPDATE
        // BOTH FLAGS MUST BE PRESERVED
        // --------------------------------------------------

        zero_in      = 1;
        carry_in     = 1;

        update_zero  = 0;
        update_carry = 0;

        #10;

        if ((zero_flag == 1'b0) &&
            (carry_flag == 1'b0)) begin

            $display("PASS: Flags preserved when updates disabled");
            passed = passed + 1;

        end
        else begin

            $display("FAIL: Flags changed when updates disabled");
            $display("      Z=%b C=%b",
                     zero_flag,
                     carry_flag);

            failed = failed + 1;

        end


        // --------------------------------------------------
        // TEST 6: BOTH FLAGS TO ZERO
        // --------------------------------------------------

        zero_in      = 0;
        carry_in     = 0;

        update_zero  = 1;
        update_carry = 1;

        #10;

        if ((zero_flag == 1'b0) &&
            (carry_flag == 1'b0)) begin

            $display("PASS: Both flags updated to Z=0 C=0");
            passed = passed + 1;

        end
        else begin

            $display("FAIL: Both flags zero update failed");
            $display("      Z=%b C=%b",
                     zero_flag,
                     carry_flag);

            failed = failed + 1;

        end


        // --------------------------------------------------
        // SUMMARY
        // --------------------------------------------------

        $display("");
        $display("========================================");
        $display("        FLAGS TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL FLAGS TESTS PASSED!");
        else
            $display("FLAGS TESTS FAILED!");

        $finish;

    end

endmodule
