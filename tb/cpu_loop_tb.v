`timescale 1ns / 1ps

module cpu_loop_tb;

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
    integer n;
    integer body_count;
    integer instr_count;

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

    // Count executed instructions and loop-body entries (ports only)
    always @(posedge clk) begin
        if (!reset && !dbg_halt) begin
            instr_count <= instr_count + 1;
            if (dbg_pc == 8'h02)
                body_count <= body_count + 1;
        end
    end

    // Read-only views of architectural state
    wire [7:0] R0 = uut.registers.registers[0];
    wire [7:0] R1 = uut.registers.registers[1];

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
                $display("       pc=%h R0=%h R1=%h Z=%b C=%b",
                         dbg_pc, R0, R1, dbg_zero_flag, dbg_carry_flag);
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

        clk         = 1'b0;
        reset       = 1'b1;
        passed      = 0;
        failed      = 0;
        pc_errors   = 0;
        body_count  = 0;
        instr_count = 0;

        // ------------------------------------------------
        // PROGRAM (ISA v1.0 encodings)
        //
        //   00: 8005  LOADI R0,5       loop counter
        //   01: 8400  LOADI R1,0       iteration counter
        //   02: 6400  INC   R1         LOOP (body)
        //   03: 7000  DEC   R0         (DEC R0 = 7000, not 6000 = INC R0)
        //   04: C006  BZ    0x06       exit when R0 == 0
        //   05: B002  JMP   0x02
        //   06: D000  HALT
        // ------------------------------------------------

        uut.instruction_memory.memory[8'h00] = 16'h8005;
        uut.instruction_memory.memory[8'h01] = 16'h8400;
        uut.instruction_memory.memory[8'h02] = 16'h6400;
        uut.instruction_memory.memory[8'h03] = 16'h7000;
        uut.instruction_memory.memory[8'h04] = 16'hC006;
        uut.instruction_memory.memory[8'h05] = 16'hB002;
        uut.instruction_memory.memory[8'h06] = 16'hD000;

        // ------------------------------------------------
        // RESET
        // ------------------------------------------------

        @(posedge clk);
        #1;

        check(dbg_pc === 8'h00 && dbg_halt === 1'b0, "Reset: PC = 0, HALT = 0");
        check(R0 === 8'h00 && R1 === 8'h00, "Reset: R0 = 0, R1 = 0");

        reset = 1'b0;

        exec(8'h00);
        exec(8'h01);
        check(R0 === 8'd5 && R1 === 8'd0, "Before loop: R0 = 5, R1 = 0");

        // ------------------------------------------------
        // LOOP: iterations 1..5
        // ------------------------------------------------

        for (n = 1; n <= 5; n = n + 1) begin

            exec(8'h02);   // INC R1
            exec(8'h03);   // DEC R0

            check(R1 === n[7:0] && R0 === (8'd5 - n[7:0]),
                  "Iteration: INC R1 / DEC R0 values");
            check(dbg_zero_flag === (n == 5) && dbg_carry_flag === 1'b1,
                  "Iteration: DEC sets Z only at 0, C = 1 (no borrow)");

            exec(8'h04);   // BZ 0x06

            if (n < 5) begin
                check(dbg_pc === 8'h05, "BZ not taken while R0 != 0");
                exec(8'h05);   // JMP 0x02
                check(dbg_pc === 8'h02, "JMP returns to loop start 0x02");
            end
            else begin
                check(dbg_pc === 8'h06, "BZ taken when R0 = 0: exits to 0x06");
            end

        end

        // ------------------------------------------------
        // HALT
        // ------------------------------------------------

        check(dbg_halt === 1'b1, "HALT asserted at 0x06");

        exec(8'h06);
        exec(8'h06);

        check(dbg_pc === 8'h06 && dbg_halt === 1'b1, "PC remains at 0x06 while halted");
        check(R0 === 8'h00 && R1 === 8'd5, "Final state: R0 = 0, R1 = 5");
        check(dbg_zero_flag === 1'b1 && dbg_carry_flag === 1'b1, "Final flags: Z = 1, C = 1");
        check(body_count == 5, "Loop body executed exactly 5 times");
        check(instr_count == 21, "21 instructions executed before HALT");
        check(pc_errors == 0, "PC followed the expected loop sequence");

        // ------------------------------------------------
        // SUMMARY
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("          CPU LOOP TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL CPU LOOP TESTS PASSED!");
        else
            $display("CPU LOOP TESTS FAILED!");

        $display("========================================");

        $finish;

    end

endmodule
