`timescale 1ns/1ps

module cpu_isa_regression_tb;

    reg clk;
    reg reset;

    integer passed;
    integer failed;

    cpu uut (
        .clk(clk),
        .reset(reset)
    );

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
    // Run one clock cycle
    // ------------------------------------------------

    task cycle;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // ------------------------------------------------
    // TEST
    // ------------------------------------------------

    initial begin

        clk    = 1'b0;
        reset  = 1'b1;
        passed = 0;
        failed = 0;

        // ============================================================
        // PROGRAM
        // ============================================================

        // 00: NOP
        uut.instruction_memory.memory[8'h00] = 16'h0000;

        // 01: LOADI R0,10
        uut.instruction_memory.memory[8'h01] = 16'h800A;

        // 02: LOADI R1,3
        uut.instruction_memory.memory[8'h02] = 16'h8403;

        // 03: ADD R0,R1
        uut.instruction_memory.memory[8'h03] = 16'h1100;

        // 04: SUB R0,R1
        uut.instruction_memory.memory[8'h04] = 16'h2100;

        // 05: AND R0,R1
        uut.instruction_memory.memory[8'h05] = 16'h3100;

        // 06: OR R0,R1
        uut.instruction_memory.memory[8'h06] = 16'h4100;

        // 07: XOR R0,R1
        uut.instruction_memory.memory[8'h07] = 16'h5100;

        // 08: INC R0
        uut.instruction_memory.memory[8'h08] = 16'h6000;

        // 09: DEC R0
        uut.instruction_memory.memory[8'h09] = 16'h7000;

        // 0A: STORE R0,0x20
        uut.instruction_memory.memory[8'h0A] = 16'hA020;

        // 0B: LOAD R2,0x20
        uut.instruction_memory.memory[8'h0B] = 16'h9820;

        // 0C: HALT
        uut.instruction_memory.memory[8'h0C] = 16'hD000;


        // ============================================================
        // RESET
        // ============================================================

        cycle;

        check(
            uut.pc_value == 8'd0,
            "Reset: PC = 0"
        );

        check(
            uut.registers.registers[0] == 8'd0 &&
            uut.registers.registers[1] == 8'd0 &&
            uut.registers.registers[2] == 8'd0 &&
            uut.registers.registers[3] == 8'd0,
            "Reset: all registers = 0"
        );


        // Release reset
        reset = 1'b0;


        // ============================================================
        // NOP
        // ============================================================

        cycle;

        check(
            uut.pc_value == 8'd1,
            "NOP: PC advances to 1"
        );


        // ============================================================
        // LOADI
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd10,
            "LOADI: R0 = 10"
        );


        cycle;

        check(
            uut.registers.registers[1] == 8'd3,
            "LOADI: R1 = 3"
        );


        // ============================================================
        // ADD
        // 10 + 3 = 13
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd13,
            "ADD: R0 = 13"
        );

        check(
            uut.zero_flag == 1'b0,
            "ADD: Zero flag = 0"
        );


        // ============================================================
        // SUB
        // 13 - 3 = 10
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd10,
            "SUB: R0 = 10"
        );


        // ============================================================
        // AND
        // 10 & 3 = 2
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd2,
            "AND: R0 = 2"
        );


        // ============================================================
        // OR
        // 2 | 3 = 3
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd3,
            "OR: R0 = 3"
        );


        // ============================================================
        // XOR
        // 3 ^ 3 = 0
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd0,
            "XOR: R0 = 0"
        );

        check(
            uut.zero_flag == 1'b1,
            "XOR: Zero flag = 1"
        );


        // ============================================================
        // INC
        // 0 + 1 = 1
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd1,
            "INC: R0 = 1"
        );


        // ============================================================
        // DEC
        // 1 - 1 = 0
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd0,
            "DEC: R0 = 0"
        );

        check(
            uut.zero_flag == 1'b1,
            "DEC: Zero flag = 1"
        );


        // ============================================================
        // STORE
        // ============================================================

        cycle;

        check(
            uut.data_mem.memory[8'h20] == 8'd0,
            "STORE: Memory[0x20] = 0"
        );


        // ============================================================
        // LOAD
        // ============================================================

        cycle;

        check(
            uut.registers.registers[2] == 8'd0,
            "LOAD: R2 = Memory[0x20]"
        );


        // ============================================================
        // HALT
        // ============================================================

        cycle;

        check(
            uut.halt == 1'b1,
            "HALT: halt signal asserted"
        );

        check(
            uut.pc_value == 8'h0C,
            "HALT: PC = 0x0C"
        );


        // ============================================================
        // HALT HOLD
        // ============================================================

        cycle;

        check(
            uut.pc_value == 8'h0C,
            "HALT: PC remains at 0x0C"
        );


        // ============================================================
        // SUMMARY
        // ============================================================

        $display("");
        $display("========================================");
        $display("       ISA v1.0 CPU TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL ISA v1.0 TESTS PASSED!");
        else
            $display("ISA v1.0 TESTS FAILED!");

        $display("========================================");

        $finish;

    end

endmodule