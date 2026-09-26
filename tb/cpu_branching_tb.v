`timescale 1ns / 1ps

module cpu_branching_tb;

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
    integer i;

    // PCs sampled at every executed clock edge (ports only)
    reg visited [0:255];

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

    always @(posedge clk) begin
        if (!reset)
            visited[dbg_pc] <= 1'b1;
    end

    // Read-only views of architectural state
    wire [7:0] R0 = uut.registers.registers[0];
    wire [7:0] R1 = uut.registers.registers[1];
    wire [7:0] R2 = uut.registers.registers[2];
    wire [7:0] R3 = uut.registers.registers[3];

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
                $display("       pc=%h R0=%h R1=%h R2=%h R3=%h Z=%b C=%b",
                         dbg_pc, R0, R1, R2, R3, dbg_zero_flag, dbg_carry_flag);
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

        for (i = 0; i < 256; i = i + 1)
            visited[i] = 1'b0;

        // ------------------------------------------------
        // PROGRAM (ISA v1.0 encodings)
        //
        //   00: 8005  LOADI R0,5
        //   01: 8401  LOADI R1,1
        //   02: 2F00  SUB   R3,R3      Z = 1
        //   03: 2100  SUB   R0,R1      R0 = 4, Z = 0 (cleared)
        //   04: C008  BZ    0x08       NOT taken
        //   05: 8811  LOADI R2,0x11    executes (fall-through)
        //   06: 2000  SUB   R0,R0      R0 = 0, Z = 1
        //   07: C00B  BZ    0x0B       taken
        //   08: 8C63  LOADI R3,99      skipped
        //   09: B00D  JMP   0x0D       skipped
        //   0A: 8C77  LOADI R3,0x77    skipped
        //   0B: 842A  LOADI R1,42      branch target
        //   0C: C00E  BZ    0x0E       taken (Z kept through LOADI)
        //   0D: 88EE  LOADI R2,0xEE    skipped
        //   0E: D000  HALT
        // ------------------------------------------------

        uut.instruction_memory.memory[8'h00] = 16'h8005;
        uut.instruction_memory.memory[8'h01] = 16'h8401;
        uut.instruction_memory.memory[8'h02] = 16'h2F00;
        uut.instruction_memory.memory[8'h03] = 16'h2100;
        uut.instruction_memory.memory[8'h04] = 16'hC008;
        uut.instruction_memory.memory[8'h05] = 16'h8811;
        uut.instruction_memory.memory[8'h06] = 16'h2000;
        uut.instruction_memory.memory[8'h07] = 16'hC00B;
        uut.instruction_memory.memory[8'h08] = 16'h8C63;
        uut.instruction_memory.memory[8'h09] = 16'hB00D;
        uut.instruction_memory.memory[8'h0A] = 16'h8C77;
        uut.instruction_memory.memory[8'h0B] = 16'h842A;
        uut.instruction_memory.memory[8'h0C] = 16'hC00E;
        uut.instruction_memory.memory[8'h0D] = 16'h88EE;
        uut.instruction_memory.memory[8'h0E] = 16'hD000;

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
        // 00-02: setup, Z = 1
        // ------------------------------------------------

        exec(8'h00);
        exec(8'h01);
        check(R0 === 8'd5 && R1 === 8'd1, "LOADI: R0 = 5, R1 = 1");

        exec(8'h02);
        check(R3 === 8'h00 && dbg_zero_flag === 1'b1, "SUB R3,R3 = 0 sets Z = 1");

        // ------------------------------------------------
        // 03: SUB R0,R1 (non-zero result)
        // ------------------------------------------------

        exec(8'h03);
        check(R0 === 8'd4 && dbg_zero_flag === 1'b0,
              "SUB R0,R1 = 4 clears Z = 0");

        // ------------------------------------------------
        // 04: BZ 0x08 with Z = 0 -> not taken
        // ------------------------------------------------

        exec(8'h04);
        check(dbg_pc === 8'h05, "BZ not taken (Z = 0): PC = 0x05");

        exec(8'h05);
        check(R2 === 8'h11, "Fall-through instruction executed: R2 = 0x11");

        // ------------------------------------------------
        // 06: SUB R0,R0 -> Z = 1
        // ------------------------------------------------

        exec(8'h06);
        check(R0 === 8'h00 && dbg_zero_flag === 1'b1, "SUB R0,R0 = 0 sets Z = 1");

        // ------------------------------------------------
        // 07: BZ 0x0B with Z = 1 -> taken
        // ------------------------------------------------

        exec(8'h07);
        check(dbg_pc === 8'h0B, "BZ taken (Z = 1): PC redirected to 0x0B");

        exec(8'h0B);
        check(R1 === 8'd42, "Branch target executed: R1 = 42");
        check(dbg_zero_flag === 1'b1, "Z remains 1 after LOADI (no flag update)");

        // ------------------------------------------------
        // 0C: BZ 0x0E with Z = 1 -> taken
        // ------------------------------------------------

        exec(8'h0C);
        check(dbg_pc === 8'h0E, "Second BZ taken: PC redirected to 0x0E");

        // ------------------------------------------------
        // 0E: HALT
        // ------------------------------------------------

        check(dbg_halt === 1'b1, "HALT asserted at 0x0E");

        exec(8'h0E);
        exec(8'h0E);

        check(dbg_pc === 8'h0E && dbg_halt === 1'b1, "PC remains at 0x0E while halted");

        // ------------------------------------------------
        // SKIPPED INSTRUCTIONS
        // ------------------------------------------------

        check(R3 === 8'h00, "Skipped LOADI R3,99 / R3,0x77 not executed (R3 = 0)");
        check(R2 === 8'h11, "Skipped LOADI R2,0xEE not executed (R2 = 0x11)");
        check(!visited[8'h08] && !visited[8'h09] && !visited[8'h0A] && !visited[8'h0D],
              "Addresses 0x08, 0x09, 0x0A, 0x0D never executed");

        check(R0 === 8'h00 && R1 === 8'd42 && dbg_carry_flag === 1'b1,
              "Final state: R0 = 0, R1 = 42, C = 1");
        check(pc_errors == 0, "PC followed the expected branch path");

        // ------------------------------------------------
        // SUMMARY
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("       CPU BRANCHING TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL CPU BRANCHING TESTS PASSED!");
        else
            $display("CPU BRANCHING TESTS FAILED!");

        $display("========================================");

        $finish;

    end

endmodule
