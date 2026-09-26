`timescale 1ns/1ps

module cpu_arithmetic_boundary_tb;

    reg clk;
    reg reset;

    integer passed;
    integer failed;

    cpu uut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

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

    task cycle;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    initial begin

        clk    = 1'b0;
        reset  = 1'b1;
        passed = 0;
        failed = 0;

        // ============================================================
        // PROGRAM
        // ============================================================

        // ------------------------------------------------------------
        // Test 1:
        // R0 = 255
        // R1 = 1
        // ADD
        // Expected: R0 = 0, C = 1, Z = 1
        // ------------------------------------------------------------

        uut.instruction_memory.memory[8'h00] = 16'h80FF; // LOADI R0,255
        uut.instruction_memory.memory[8'h01] = 16'h8401; // LOADI R1,1
        uut.instruction_memory.memory[8'h02] = 16'h1100; // ADD R0,R1

        // ------------------------------------------------------------
        // Test 2:
        // R0 = 0
        // R1 = 1
        // SUB
        // Expected: R0 = 255, C = 0, Z = 0
        // ------------------------------------------------------------

        uut.instruction_memory.memory[8'h03] = 16'h8000; // LOADI R0,0
        uut.instruction_memory.memory[8'h04] = 16'h8401; // LOADI R1,1
        uut.instruction_memory.memory[8'h05] = 16'h2100; // SUB R0,R1

        // ------------------------------------------------------------
        // Test 3:
        // R0 = 255
        // R1 = 0
        // ADD
        // Expected: R0 = 255, C = 0, Z = 0
        // ------------------------------------------------------------

        uut.instruction_memory.memory[8'h06] = 16'h80FF; // LOADI R0,255
        uut.instruction_memory.memory[8'h07] = 16'h8400; // LOADI R1,0
        uut.instruction_memory.memory[8'h08] = 16'h1100; // ADD R0,R1

        // ------------------------------------------------------------
        // Test 4:
        // R0 = 0
        // R1 = 0
        // SUB
        // Expected: R0 = 0, C = 1, Z = 1
        // ------------------------------------------------------------

        uut.instruction_memory.memory[8'h09] = 16'h8000; // LOADI R0,0
        uut.instruction_memory.memory[8'h0A] = 16'h8400; // LOADI R1,0
        uut.instruction_memory.memory[8'h0B] = 16'h2100; // SUB R0,R1

        // ------------------------------------------------------------
        // HALT
        // ------------------------------------------------------------

        uut.instruction_memory.memory[8'h0C] = 16'hD000;


        // ============================================================
        // RESET
        // ============================================================

        cycle;

        check(
            uut.pc_value == 8'd0,
            "Reset: PC = 0"
        );

        reset = 1'b0;


        // ============================================================
        // TEST 1: 255 + 1
        // ============================================================

        cycle; // LOADI R0,255
        cycle; // LOADI R1,1
        cycle; // ADD

        check(
            uut.registers.registers[0] == 8'd0,
            "255 + 1 wraps to 0"
        );

        check(
            uut.zero_flag == 1'b1,
            "255 + 1 sets Zero flag"
        );

        check(
            uut.carry_flag == 1'b1,
            "255 + 1 sets Carry flag"
        );


        // ============================================================
        // TEST 2: 0 - 1
        // ============================================================

        cycle; // LOADI R0,0
        cycle; // LOADI R1,1
        cycle; // SUB

        check(
            uut.registers.registers[0] == 8'hFF,
            "0 - 1 wraps to 255"
        );

        check(
            uut.zero_flag == 1'b0,
            "0 - 1 clears Zero flag"
        );

        check(
            uut.carry_flag == 1'b0,
            "0 - 1 indicates borrow"
        );


        // ============================================================
        // TEST 3: 255 + 0
        // ============================================================

        cycle; // LOADI R0,255
        cycle; // LOADI R1,0
        cycle; // ADD

        check(
            uut.registers.registers[0] == 8'hFF,
            "255 + 0 remains 255"
        );

        check(
            uut.zero_flag == 1'b0,
            "255 + 0 keeps Zero flag clear"
        );

        check(
            uut.carry_flag == 1'b0,
            "255 + 0 produces no Carry"
        );


        // ============================================================
        // TEST 4: 0 - 0
        // ============================================================

        cycle; // LOADI R0,0
        cycle; // LOADI R1,0
        cycle; // SUB

        check(
            uut.registers.registers[0] == 8'd0,
            "0 - 0 produces 0"
        );

        check(
            uut.zero_flag == 1'b1,
            "0 - 0 sets Zero flag"
        );

        check(
            uut.carry_flag == 1'b1,
            "0 - 0 indicates no borrow"
        );


        // ============================================================
        // HALT
        // ============================================================

        cycle;

        check(
            uut.halt == 1'b1,
            "HALT asserted"
        );


        // ============================================================
        // SUMMARY
        // ============================================================

        $display("");
        $display("========================================");
        $display("       ARITHMETIC EDGE TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL ARITHMETIC EDGE TESTS PASSED!");
        else
            $display("ARITHMETIC EDGE TESTS FAILED!");

        $display("========================================");

        $finish;

    end

endmodule