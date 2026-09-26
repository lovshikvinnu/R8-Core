`timescale 1ns / 1ps

module pc_tb;

    integer passed;
    integer failed;

    reg clk;
    reg reset;
    reg enable;
    reg load;

    reg [7:0] load_value;

    wire [7:0] pc;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    pc uut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .load(load),
        .load_value(load_value),
        .pc(pc)
    );

    // 10 ns clock
    always #5 clk = ~clk;


    // --------------------------------------------------
    // TESTS
    // --------------------------------------------------

    initial begin

        passed = 0;
        failed = 0;

        clk        = 0;
        reset      = 0;
        enable     = 0;
        load       = 0;
        load_value = 8'h00;


        // --------------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------------

        reset = 1;
        #10;
        reset = 0;
        #1;

        if (pc == 8'd0) begin
            $display("PASS: PC reset to 0");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: PC = %d, expected 0", pc);
            failed = failed + 1;
        end


        // --------------------------------------------------
        // TEST 2: INCREMENT
        // --------------------------------------------------

        enable = 1;

        #20;

        if (pc == 8'd2) begin
            $display("PASS: PC incremented to 2");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: PC = %d, expected 2", pc);
            failed = failed + 1;
        end


        // --------------------------------------------------
        // TEST 3: HOLD
        // --------------------------------------------------

        enable = 0;

        #30;

        if (pc == 8'd2) begin
            $display("PASS: PC held at 2");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: PC = %d, expected 2", pc);
            failed = failed + 1;
        end


        // --------------------------------------------------
        // TEST 4: LOAD / JUMP
        // --------------------------------------------------

        load_value = 8'h55;
        load       = 1;

        #10;

        load = 0;

        if (pc == 8'h55) begin
            $display("PASS: PC loaded address 0x55");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: PC = %h, expected 55", pc);
            failed = failed + 1;
        end


        // --------------------------------------------------
        // TEST 5: INCREMENT AFTER LOAD
        // --------------------------------------------------

        enable = 1;

        #10;

        if (pc == 8'h56) begin
            $display("PASS: PC incremented from 0x55 to 0x56");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: PC = %h, expected 56", pc);
            failed = failed + 1;
        end


        // --------------------------------------------------
        // TEST 6: LOAD HAS PRIORITY OVER INCREMENT
        // --------------------------------------------------

        load_value = 8'hA0;
        load       = 1;
        enable     = 1;

        #10;

        load   = 0;
        enable = 0;

        if (pc == 8'hA0) begin
            $display("PASS: LOAD has priority over increment");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: PC = %h, expected A0", pc);
            failed = failed + 1;
        end


        // --------------------------------------------------
        // TEST 7: WRAPAROUND
        // --------------------------------------------------

        load_value = 8'hFF;
        load       = 1;

        #10;

        load = 0;

        enable = 1;

        #10;

        if (pc == 8'h00) begin
            $display("PASS: PC wrapped from 0xFF to 0x00");
            passed = passed + 1;
        end
        else begin
            $display("FAIL: PC = %h, expected 00", pc);
            failed = failed + 1;
        end


        // --------------------------------------------------
        // SUMMARY
        // --------------------------------------------------

        $display("");
        $display("========================================");
        $display("          PC TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL PC TESTS PASSED!");
        else
            $display("PC TESTS FAILED!");

        $finish;

    end

endmodule