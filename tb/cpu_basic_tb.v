`timescale 1ns/1ps

module cpu_basic_tb;

    reg clk;
    reg reset;

    integer passed;
    integer failed;

    // Instantiate CPU
    cpu uut (
        .clk(clk),
        .reset(reset)
    );

    // 10 ns clock
    always #5 clk = ~clk;

    // ------------------------------------------------
    // Test helper
    // ------------------------------------------------
    task check;
        input condition;
        input [255:0] message;

        begin
            if (condition) begin
                $display("[PASS] %s", message);
                passed = passed + 1;
            end
            else begin
                $display("[FAIL] %s", message);
                failed = failed + 1;
            end
        end
    endtask

    // ------------------------------------------------
    // Test
    // ------------------------------------------------
    initial begin

        clk    = 1'b0;
        reset  = 1'b1;
        passed = 0;
        failed = 0;

        // ------------------------------------------------
        // Program:
        //
        // 0: LOADI R0, 10
        // 1: LOADI R1, 20
        // 2: ADD   R0, R1
        // 3: HALT
        //
        // Expected:
        // R0 = 30
        // R1 = 20
        // PC = 3
        // Z  = 0
        // C  = 0
        // ------------------------------------------------

        uut.instruction_memory.memory[8'h00] = 16'h800A; // LOADI R0,10
        uut.instruction_memory.memory[8'h01] = 16'h8414; // LOADI R1,20
        uut.instruction_memory.memory[8'h02] = 16'h1100; // ADD R0,R1
        uut.instruction_memory.memory[8'h03] = 16'hD000; // HALT

        // ------------------------------------------------
        // Reset CPU
        // ------------------------------------------------

        @(posedge clk);
        #1;

        check(
            uut.pc_value == 8'd0,
            "PC resets to 0"
        );

        check(
            uut.registers.registers[0] == 8'd0 &&
            uut.registers.registers[1] == 8'd0,
            "Registers reset to 0"
        );

        // Release reset
        reset = 1'b0;

        // ------------------------------------------------
        // Execute LOADI R0,10
        // ------------------------------------------------

        @(posedge clk);
        #1;

        // ------------------------------------------------
        // Execute LOADI R1,20
        // ------------------------------------------------

        @(posedge clk);
        #1;

        // ------------------------------------------------
        // Execute ADD R0,R1
        // ------------------------------------------------

        @(posedge clk);
        #1;

        // ------------------------------------------------
        // Execute HALT
        // ------------------------------------------------

        @(posedge clk);
        #1;

        // ------------------------------------------------
        // Check final CPU state
        // ------------------------------------------------

        check(
            uut.registers.registers[0] == 8'd30,
            "R0 = 30 after ADD"
        );

        check(
            uut.registers.registers[1] == 8'd20,
            "R1 = 20 after LOADI"
        );

        check(
            uut.pc_value == 8'd3,
            "PC = 3 after HALT"
        );

        check(
            uut.zero_flag == 1'b0,
            "Zero flag = 0"
        );

        check(
            uut.carry_flag == 1'b0,
            "Carry flag = 0"
        );

        check(
            uut.halt == 1'b1,
            "HALT signal is asserted"
        );

        // ------------------------------------------------
        // Verify CPU stays halted
        // ------------------------------------------------

        @(posedge clk);
        #1;

        check(
            uut.pc_value == 8'd3,
            "PC remains at 3 while halted"
        );

        check(
            uut.registers.registers[0] == 8'd30,
            "R0 remains 30 while halted"
        );

        // ------------------------------------------------
        // Final summary
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("          CPU TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL CPU TESTS PASSED!");
        else
            $display("CPU TESTS FAILED!");

        $display("========================================");

        $finish;
    end

endmodule