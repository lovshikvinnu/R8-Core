`timescale 1ns/1ps

module cpu_inc_dec_boundary_tb;

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

        // Test 1:
        // R0 = 255
        // INC R0
        // Expected: R0 = 0, Z=1, C=1

        uut.instruction_memory.memory[8'h00] = 16'h80FF; // LOADI R0,255
        uut.instruction_memory.memory[8'h01] = 16'h6000; // INC R0

        // Test 2:
        // R0 = 0
        // DEC R0
        // Expected: R0 = 255, Z=0, C=0

        uut.instruction_memory.memory[8'h02] = 16'h8000; // LOADI R0,0
        uut.instruction_memory.memory[8'h03] = 16'h7000; // DEC R0

        // Test 3:
        // R0 = 1
        // DEC R0
        // Expected: R0 = 0, Z=1, C=1

        uut.instruction_memory.memory[8'h04] = 16'h8001; // LOADI R0,1
        uut.instruction_memory.memory[8'h05] = 16'h7000; // DEC R0

        // Test 4:
        // R0 = 255
        // INC R0
        // Expected: R0 = 0, Z=1, C=1

        uut.instruction_memory.memory[8'h06] = 16'h80FF; // LOADI R0,255
        uut.instruction_memory.memory[8'h07] = 16'h6000; // INC R0

        // HALT
        uut.instruction_memory.memory[8'h08] = 16'hD000;

        // ============================================================
        // RESET
        // ============================================================

        cycle;

        check(
            uut.pc_value == 8'd0,
            "Reset: PC = 0"
        );

        check(
            uut.registers.registers[0] == 8'd0,
            "Reset: R0 = 0"
        );

        reset = 1'b0;

        // ============================================================
        // TEST 1: INC 255
        // ============================================================

        cycle; // LOADI R0,255
        cycle; // INC

        check(
            uut.registers.registers[0] == 8'd0,
            "INC 255 wraps to 0"
        );

        check(
            uut.zero_flag == 1'b1,
            "INC 255 sets Zero flag"
        );

        check(
            uut.carry_flag == 1'b1,
            "INC 255 sets Carry flag"
        );

        // ============================================================
        // TEST 2: DEC 0
        // ============================================================

        cycle; // LOADI R0,0
        cycle; // DEC

        check(
            uut.registers.registers[0] == 8'hFF,
            "DEC 0 wraps to 255"
        );

        check(
            uut.zero_flag == 1'b0,
            "DEC 0 clears Zero flag"
        );

        check(
            uut.carry_flag == 1'b0,
            "DEC 0 indicates borrow"
        );

        // ============================================================
        // TEST 3: DEC 1
        // ============================================================

        cycle; // LOADI R0,1
        cycle; // DEC

        check(
            uut.registers.registers[0] == 8'd0,
            "DEC 1 produces 0"
        );

        check(
            uut.zero_flag == 1'b1,
            "DEC 1 sets Zero flag"
        );

        check(
            uut.carry_flag == 1'b1,
            "DEC 1 indicates no borrow"
        );

        // ============================================================
        // TEST 4: INC 255 AGAIN
        // ============================================================

        cycle; // LOADI R0,255
        cycle; // INC

        check(
            uut.registers.registers[0] == 8'd0,
            "Second INC 255 wraps to 0"
        );

        check(
            uut.zero_flag == 1'b1,
            "Second INC 255 sets Zero flag"
        );

        check(
            uut.carry_flag == 1'b1,
            "Second INC 255 sets Carry flag"
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
        $display("       INC / DEC EDGE TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL INC/DEC EDGE TESTS PASSED!");
        else
            $display("INC/DEC EDGE TESTS FAILED!");

        $display("========================================");

        $finish;

    end

endmodule