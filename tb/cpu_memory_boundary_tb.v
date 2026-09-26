`timescale 1ns/1ps

module cpu_memory_boundary_tb;

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

        // R0 = 42
        uut.instruction_memory.memory[8'h00] = 16'h802A;

        // STORE R0, 0x00
        uut.instruction_memory.memory[8'h01] = 16'hA000;

        // R0 = 99
        uut.instruction_memory.memory[8'h02] = 16'h8063;

        // STORE R0, 0xFF
        uut.instruction_memory.memory[8'h03] = 16'hA0FF;

        // R1 = 0
        uut.instruction_memory.memory[8'h04] = 16'h8400;

        // LOAD R1, 0x00
        uut.instruction_memory.memory[8'h05] = 16'h9400;

        // R2 = 0
        uut.instruction_memory.memory[8'h06] = 16'h8800;

        // LOAD R2, 0xFF
        uut.instruction_memory.memory[8'h07] = 16'h98FF;

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

        reset = 1'b0;


        // ============================================================
        // STORE 42 → 0x00
        // ============================================================

        cycle; // LOADI R0,42
        cycle; // STORE R0,0x00

        check(
            uut.data_mem.memory[8'h00] == 8'd42,
            "STORE: Memory[0x00] = 42"
        );


        // ============================================================
        // STORE 99 → 0xFF
        // ============================================================

        cycle; // LOADI R0,99
        cycle; // STORE R0,0xFF

        check(
            uut.data_mem.memory[8'hFF] == 8'd99,
            "STORE: Memory[0xFF] = 99"
        );


        // ============================================================
        // VERIFY ADDRESSES ARE INDEPENDENT
        // ============================================================

        check(
            uut.data_mem.memory[8'h00] == 8'd42,
            "Memory[0x00] remains 42 after writing 0xFF"
        );

        check(
            uut.data_mem.memory[8'hFF] == 8'd99,
            "Memory[0xFF] remains 99"
        );


        // ============================================================
        // LOAD FROM 0x00
        // ============================================================

        cycle; // LOADI R1,0
        cycle; // LOAD R1,0x00

        check(
            uut.registers.registers[1] == 8'd42,
            "LOAD: R1 receives 42 from Memory[0x00]"
        );


        // ============================================================
        // LOAD FROM 0xFF
        // ============================================================

        cycle; // LOADI R2,0
        cycle; // LOAD R2,0xFF

        check(
            uut.registers.registers[2] == 8'd99,
            "LOAD: R2 receives 99 from Memory[0xFF]"
        );


        // ============================================================
        // FINAL MEMORY INTEGRITY
        // ============================================================

        check(
            uut.data_mem.memory[8'h00] == 8'd42 &&
            uut.data_mem.memory[8'hFF] == 8'd99,
            "Both memory boundary values remain correct"
        );


        // ============================================================
        // HALT
        // ============================================================

        cycle;

        check(
            uut.halt == 1'b1,
            "HALT asserted"
        );

        check(
            uut.pc_value == 8'h08,
            "PC = 0x08 at HALT"
        );


        // ============================================================
        // SUMMARY
        // ============================================================

        $display("");
        $display("========================================");
        $display("       MEMORY BOUNDARY TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL MEMORY BOUNDARY TESTS PASSED!");
        else
            $display("MEMORY BOUNDARY TESTS FAILED!");

        $display("========================================");

        $finish;

    end

endmodule