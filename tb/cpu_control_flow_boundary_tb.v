`timescale 1ns/1ps

module cpu_control_flow_boundary_tb;

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

        // 00: JMP FF
        uut.instruction_memory.memory[8'h00] = 16'hB0FF;

        // 01: NOP
        uut.instruction_memory.memory[8'h01] = 16'h0000;

        // 02: NOP
        uut.instruction_memory.memory[8'h02] = 16'h0000;

        // 03: NOP
        uut.instruction_memory.memory[8'h03] = 16'h0000;

        // 04: NOP
        uut.instruction_memory.memory[8'h04] = 16'h0000;

        // 05: NOP
        uut.instruction_memory.memory[8'h05] = 16'h0000;

        // 06: NOP
        uut.instruction_memory.memory[8'h06] = 16'h0000;

        // 07: NOP
        uut.instruction_memory.memory[8'h07] = 16'h0000;

        // ------------------------------------------------------------
        // FF: LOADI R0,77
        // ------------------------------------------------------------

        uut.instruction_memory.memory[8'hFF] = 16'h804D;

        // ------------------------------------------------------------
        // After reaching FF:
        //
        // FF executes LOADI R0,77
        // Then PC wraps to 00
        // 00 executes JMP FF again
        //
        // This proves the extreme addresses are reachable.
        // ------------------------------------------------------------


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
        // JMP 0xFF
        // ============================================================

        cycle;

        check(
            uut.pc_value == 8'hFF,
            "JMP 0xFF loads PC with 0xFF"
        );


        // ============================================================
        // Execute instruction at 0xFF
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd77,
            "Instruction at 0xFF executes correctly"
        );

        check(
            uut.pc_value == 8'h00,
            "PC wraps from 0xFF to 0x00"
        );


        // ============================================================
        // JMP 0xFF AGAIN
        // ============================================================

        cycle;

        check(
            uut.pc_value == 8'hFF,
            "JMP from 0x00 back to 0xFF works"
        );


        // ============================================================
        // Now create Z = 1
        //
        // We'll replace address 0x00 with:
        // LOADI R1,0
        // SUB R1,R1
        // BZ FF
        // ============================================================

        uut.instruction_memory.memory[8'h00] = 16'h8400; // LOADI R1,0
        uut.instruction_memory.memory[8'h01] = 16'h2100; // SUB R1,R0
        uut.instruction_memory.memory[8'h02] = 16'hC0FF; // BZ FF

        // Jump to 00 first
        uut.instruction_memory.memory[8'h03] = 16'hB000;

        // Manually load PC to 00 through JMP at current FF
        uut.instruction_memory.memory[8'hFF] = 16'hB000;


        // Execute JMP 00 from FF
        cycle;

        check(
            uut.pc_value == 8'h00,
            "JMP 0x00 loads PC with 0x00"
        );


        // ============================================================
        // LOADI R1,0
        // ============================================================

        cycle;

        check(
            uut.registers.registers[1] == 8'd0,
            "LOADI R1,0 executes"
        );


        // ============================================================
        // SUB R1,R0
        //
        // R0 = 77, so this would NOT produce zero.
        //
        // Instead set R0 = 0 first through LOADI.
        // ============================================================

        uut.instruction_memory.memory[8'h01] = 16'h8000; // LOADI R0,0
        uut.instruction_memory.memory[8'h02] = 16'h2100; // SUB R0,R1
        uut.instruction_memory.memory[8'h03] = 16'hC0FF; // BZ FF

        cycle;

        check(
            uut.registers.registers[0] == 8'd0,
            "LOADI R0,0 executes"
        );


        // ============================================================
        // SUB R0,R1 → 0
        // ============================================================

        cycle;

        check(
            uut.registers.registers[0] == 8'd0 &&
            uut.zero_flag == 1'b1,
            "SUB produces zero and sets Zero flag"
        );


        // ============================================================
        // BZ 0xFF
        // ============================================================

        cycle;

        check(
            uut.pc_value == 8'hFF,
            "BZ 0xFF loads PC with 0xFF"
        );


        // ============================================================
        // SUMMARY
        // ============================================================

        $display("");
        $display("========================================");
        $display("     CONTROL FLOW EDGE TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL CONTROL FLOW EDGE TESTS PASSED!");
        else
            $display("CONTROL FLOW EDGE TESTS FAILED!");

        $display("========================================");

        $finish;

    end

endmodule