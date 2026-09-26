`timescale 1ns / 1ps

module cpu_memory_tb;

    reg clk;
    reg reset;

    wire [7:0] dbg_pc;
    wire       dbg_halt;
    wire       dbg_zero_flag;
    wire       dbg_carry_flag;
    wire [7:0] dbg_wb_data;
    wire [1:0] dbg_wb_addr;

    integer passed;
    integer failed;
    integer pc_errors;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    cpu uut (
        .clk(clk),
        .reset(reset),

        .dbg_pc(dbg_pc),
        .dbg_halt(dbg_halt),
        .dbg_zero_flag(dbg_zero_flag),
        .dbg_carry_flag(dbg_carry_flag),
        .dbg_wb_data(dbg_wb_data),
        .dbg_wb_addr(dbg_wb_addr)
    );

    always #5 clk = ~clk;

    // Read-only views of architectural state
    wire [7:0] R0 = uut.registers.registers[0];
    wire [7:0] R1 = uut.registers.registers[1];
    wire [7:0] R2 = uut.registers.registers[2];
    wire [7:0] R3 = uut.registers.registers[3];

    wire [7:0] MEM20 = uut.data_mem.memory[8'h20];
    wire [7:0] MEM21 = uut.data_mem.memory[8'h21];

    task check;
        input condition;
        input [8*64-1:0] message;

        begin
            if (condition) begin
                $display("[PASS] %0s", message);
                passed = passed + 1;
            end
            else begin
                $display("[FAIL] %0s", message);
                $display("       pc=%h R0=%h R1=%h R2=%h R3=%h Z=%b C=%b mem[20]=%h mem[21]=%h",
                         dbg_pc, R0, R1, R2, R3, dbg_zero_flag, dbg_carry_flag, MEM20, MEM21);
                failed = failed + 1;
            end
        end
    endtask

    // Execute one instruction, first confirming the PC it executes from
    task exec;
        input [7:0] expected_pc;

        begin
            if (dbg_pc !== expected_pc) begin
                $display("       PC sequence error: expected %h, got %h", expected_pc, dbg_pc);
                pc_errors = pc_errors + 1;
            end
            @(posedge clk);
            #1;
        end
    endtask

    initial begin

        clk       = 1'b0;
        reset     = 1'b1;
        passed    = 0;
        failed    = 0;
        pc_errors = 0;

        // ------------------------------------------------
        // PROGRAM (ISA v1.0 encodings)
        //
        //   00: 2000  SUB   R0,R0      R0 = 0, Z = 1, C = 1
        //   01: 802A  LOADI R0,42
        //   02: A020  STORE R0,0x20    mem[20] = 42
        //   03: 8400  LOADI R1,0
        //   04: 9420  LOAD  R1,0x20    R1 = 42
        //   05: 88A5  LOADI R2,0xA5
        //   06: A821  STORE R2,0x21    mem[21] = A5
        //   07: 8000  LOADI R0,0       overwrite source register
        //   08: 9C21  LOAD  R3,0x21    R3 = A5
        //   09: 9020  LOAD  R0,0x20    R0 = 42 (reloaded)
        //   0A: D000  HALT
        // ------------------------------------------------

        uut.instruction_memory.memory[8'h00] = 16'h2000;
        uut.instruction_memory.memory[8'h01] = 16'h802A;
        uut.instruction_memory.memory[8'h02] = 16'hA020;
        uut.instruction_memory.memory[8'h03] = 16'h8400;
        uut.instruction_memory.memory[8'h04] = 16'h9420;
        uut.instruction_memory.memory[8'h05] = 16'h88A5;
        uut.instruction_memory.memory[8'h06] = 16'hA821;
        uut.instruction_memory.memory[8'h07] = 16'h8000;
        uut.instruction_memory.memory[8'h08] = 16'h9C21;
        uut.instruction_memory.memory[8'h09] = 16'h9020;
        uut.instruction_memory.memory[8'h0A] = 16'hD000;

        // ------------------------------------------------
        // RESET
        // ------------------------------------------------

        @(posedge clk);
        #1;

        check(dbg_pc === 8'h00 && dbg_halt === 1'b0, "Reset: PC = 0, HALT = 0");
        check(R0 === 8'h00 && R1 === 8'h00 && R2 === 8'h00 && R3 === 8'h00,
              "Reset: R0-R3 = 0");

        reset = 1'b0;

        // ------------------------------------------------
        // 00: SUB R0,R0 - flag baseline Z = 1, C = 1
        // ------------------------------------------------

        exec(8'h00);
        check(dbg_zero_flag === 1'b1 && dbg_carry_flag === 1'b1,
              "SUB R0,R0 sets Z = 1, C = 1 (baseline)");

        // ------------------------------------------------
        // 01: LOADI R0,42
        // ------------------------------------------------

        exec(8'h01);
        check(R0 === 8'd42, "LOADI R0,42: R0 = 42");

        // ------------------------------------------------
        // 02: STORE R0,0x20
        // ------------------------------------------------

        exec(8'h02);
        check(MEM20 === 8'd42, "STORE R0,0x20: mem[0x20] = 42");
        check(R0 === 8'd42 && R1 === 8'h00 && R2 === 8'h00 && R3 === 8'h00,
              "STORE does not modify registers");

        // ------------------------------------------------
        // 03: LOADI R1,0
        // ------------------------------------------------

        exec(8'h03);
        check(R1 === 8'h00, "LOADI R1,0: R1 cleared before LOAD");

        // ------------------------------------------------
        // 04: LOAD R1,0x20
        // ------------------------------------------------

        check(dbg_wb_addr === 2'd1 && dbg_wb_data === 8'd42,
              "LOAD R1,0x20: write-back selects memory data (42 -> R1)");
        exec(8'h04);
        check(R1 === 8'd42, "LOAD R1,0x20: R1 = 42");

        // ------------------------------------------------
        // 05: LOADI R2,0xA5
        // 06: STORE R2,0x21
        // ------------------------------------------------

        exec(8'h05);
        exec(8'h06);
        check(MEM21 === 8'hA5, "STORE R2,0x21: mem[0x21] = A5");
        check(MEM20 === 8'd42, "mem[0x20] unaffected by write to 0x21");

        // ------------------------------------------------
        // 07: LOADI R0,0
        // ------------------------------------------------

        exec(8'h07);
        check(R0 === 8'h00 && MEM20 === 8'd42,
              "Memory persists after source register overwritten");

        // ------------------------------------------------
        // 08: LOAD R3,0x21
        // ------------------------------------------------

        exec(8'h08);
        check(R3 === 8'hA5, "LOAD R3,0x21: R3 = A5");

        // ------------------------------------------------
        // 09: LOAD R0,0x20
        // ------------------------------------------------

        exec(8'h09);
        check(R0 === 8'd42, "LOAD R0,0x20: R0 reloaded = 42");
        check(dbg_zero_flag === 1'b1 && dbg_carry_flag === 1'b1,
              "LOADI/LOAD/STORE left flags unchanged (Z = 1, C = 1)");

        // ------------------------------------------------
        // 0A: HALT
        // ------------------------------------------------

        check(dbg_pc === 8'h0A && dbg_halt === 1'b1, "PC = 0x0A, HALT asserted");

        exec(8'h0A);
        exec(8'h0A);

        check(dbg_pc === 8'h0A && dbg_halt === 1'b1, "PC remains at 0x0A while halted");
        check(R0 === 8'd42 && R1 === 8'd42 && R2 === 8'hA5 && R3 === 8'hA5,
              "Final registers: R0 = 42, R1 = 42, R2 = A5, R3 = A5");
        check(MEM20 === 8'd42 && MEM21 === 8'hA5,
              "Final memory: mem[0x20] = 42, mem[0x21] = A5");

        check(pc_errors == 0, "PC followed the expected sequence 00-0A");

        // ------------------------------------------------
        // SUMMARY
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("       CPU MEMORY TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL CPU MEMORY TESTS PASSED!");
        else
            $display("CPU MEMORY TESTS FAILED!");

        $display("========================================");

        $finish;

    end

endmodule
