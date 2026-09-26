`timescale 1ns / 1ps

module cpu_fpga_top_tb;

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
    integer k;

    // --------------------------------------------------
    // DUT
    //
    // Program memory is NOT preloaded by this testbench.
    // The wrapper loads program.mem through PROGRAM_INIT_FILE.
    //
    // program.mem (ISA v1.0 coverage program):
    //
    //   00: 0000  NOP
    //   01: 8005  LOADI R0,0x05
    //   02: 8403  LOADI R1,0x03
    //   03: 88FF  LOADI R2,0xFF
    //   04: 8C01  LOADI R3,0x01
    //   05: 1100  ADD   R0,R1      R0 = 08
    //   06: 2100  SUB   R0,R1      R0 = 05, C = 1 (no borrow)
    //   07: 3100  AND   R0,R1      R0 = 01
    //   08: 4200  OR    R0,R2      R0 = FF
    //   09: 5100  XOR   R0,R1      R0 = FC
    //   0A: 1B00  ADD   R2,R3      R2 = 00, Z = 1, C = 1
    //   0B: 6400  INC   R1         R1 = 04
    //   0C: 7C00  DEC   R3         R3 = 00, Z = 1, C = 1
    //   0D: 2D00  SUB   R3,R1      R3 = FC, C = 0 (borrow)
    //   0E: A010  STORE R0,0x10    mem[10] = FC
    //   0F: A4FF  STORE R1,0xFF    mem[FF] = 04
    //   10: 9810  LOAD  R2,0x10    R2 = FC
    //   11: 9CFF  LOAD  R3,0xFF    R3 = 04
    //   12: 7C00  DEC   R3         LOOP
    //   13: C016  BZ    0x16       not taken 3x, taken 1x
    //   14: 6000  INC   R0
    //   15: B012  JMP   0x12
    //   16: A020  STORE R0,0x20    mem[20] = FF
    //   17: 9420  LOAD  R1,0x20    R1 = FF
    //   18: 5400  XOR   R1,R0      R1 = 00, Z = 1
    //   19: C01B  BZ    0x1B       taken
    //   1A: 84EE  LOADI R1,0xEE    skipped
    //   1B: D000  HALT
    // --------------------------------------------------

    cpu_fpga_top uut (
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

    // --------------------------------------------------
    // EXPECTED TRACE (one entry per executed instruction)
    //
    // exp_pc   : PC of the instruction
    // exp_wr   : 1 if the instruction writes a register
    // exp_addr : destination register (checked when exp_wr = 1)
    // exp_data : write-back value      (checked when exp_wr = 1)
    // exp_z/c  : stored flags while the instruction executes
    // --------------------------------------------------

    localparam STEPS = 36;

    reg [7:0] exp_pc   [0:STEPS-1];
    reg       exp_wr   [0:STEPS-1];
    reg [1:0] exp_addr [0:STEPS-1];
    reg [7:0] exp_data [0:STEPS-1];
    reg       exp_z    [0:STEPS-1];
    reg       exp_c    [0:STEPS-1];

    task step;
        input integer   n;
        input [7:0]     pc;
        input           wr;
        input [1:0]     addr;
        input [7:0]     data;
        input           z;
        input           c;
        begin
            exp_pc[n]   = pc;
            exp_wr[n]   = wr;
            exp_addr[n] = addr;
            exp_data[n] = data;
            exp_z[n]    = z;
            exp_c[n]    = c;
        end
    endtask

    task check;
        input condition;
        input [383:0] message;

        begin
            if (condition) begin
                $display("[PASS] %0s", message);
                passed = passed + 1;
            end
            else begin
                $display("[FAIL] %0s", message);
                $display("       pc=%h halt=%b z=%b c=%b wb_data=%h wb_addr=%h",
                         dbg_pc, dbg_halt, dbg_zero_flag, dbg_carry_flag,
                         dbg_wb_data, dbg_wb_addr);
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

        //     n   pc     wr  addr  data   z  c
        step( 0, 8'h00, 0, 2'd0, 8'h00, 0, 0);   // NOP
        step( 1, 8'h01, 1, 2'd0, 8'h05, 0, 0);   // LOADI R0,05
        step( 2, 8'h02, 1, 2'd1, 8'h03, 0, 0);   // LOADI R1,03
        step( 3, 8'h03, 1, 2'd2, 8'hFF, 0, 0);   // LOADI R2,FF
        step( 4, 8'h04, 1, 2'd3, 8'h01, 0, 0);   // LOADI R3,01
        step( 5, 8'h05, 1, 2'd0, 8'h08, 0, 0);   // ADD R0,R1
        step( 6, 8'h06, 1, 2'd0, 8'h05, 0, 0);   // SUB R0,R1
        step( 7, 8'h07, 1, 2'd0, 8'h01, 0, 1);   // AND R0,R1
        step( 8, 8'h08, 1, 2'd0, 8'hFF, 0, 1);   // OR  R0,R2
        step( 9, 8'h09, 1, 2'd0, 8'hFC, 0, 1);   // XOR R0,R1
        step(10, 8'h0A, 1, 2'd2, 8'h00, 0, 1);   // ADD R2,R3
        step(11, 8'h0B, 1, 2'd1, 8'h04, 1, 1);   // INC R1
        step(12, 8'h0C, 1, 2'd3, 8'h00, 0, 0);   // DEC R3
        step(13, 8'h0D, 1, 2'd3, 8'hFC, 1, 1);   // SUB R3,R1
        step(14, 8'h0E, 0, 2'd0, 8'h00, 0, 0);   // STORE R0,10
        step(15, 8'h0F, 0, 2'd0, 8'h00, 0, 0);   // STORE R1,FF
        step(16, 8'h10, 1, 2'd2, 8'hFC, 0, 0);   // LOAD R2,10
        step(17, 8'h11, 1, 2'd3, 8'h04, 0, 0);   // LOAD R3,FF
        step(18, 8'h12, 1, 2'd3, 8'h03, 0, 0);   // DEC R3
        step(19, 8'h13, 0, 2'd0, 8'h00, 0, 1);   // BZ 16 (not taken)
        step(20, 8'h14, 1, 2'd0, 8'hFD, 0, 1);   // INC R0
        step(21, 8'h15, 0, 2'd0, 8'h00, 0, 0);   // JMP 12
        step(22, 8'h12, 1, 2'd3, 8'h02, 0, 0);   // DEC R3
        step(23, 8'h13, 0, 2'd0, 8'h00, 0, 1);   // BZ 16 (not taken)
        step(24, 8'h14, 1, 2'd0, 8'hFE, 0, 1);   // INC R0
        step(25, 8'h15, 0, 2'd0, 8'h00, 0, 0);   // JMP 12
        step(26, 8'h12, 1, 2'd3, 8'h01, 0, 0);   // DEC R3
        step(27, 8'h13, 0, 2'd0, 8'h00, 0, 1);   // BZ 16 (not taken)
        step(28, 8'h14, 1, 2'd0, 8'hFF, 0, 1);   // INC R0
        step(29, 8'h15, 0, 2'd0, 8'h00, 0, 0);   // JMP 12
        step(30, 8'h12, 1, 2'd3, 8'h00, 0, 0);   // DEC R3
        step(31, 8'h13, 0, 2'd0, 8'h00, 1, 1);   // BZ 16 (taken)
        step(32, 8'h16, 0, 2'd0, 8'h00, 1, 1);   // STORE R0,20
        step(33, 8'h17, 1, 2'd1, 8'hFF, 1, 1);   // LOAD R1,20
        step(34, 8'h18, 1, 2'd1, 8'h00, 1, 1);   // XOR R1,R0
        step(35, 8'h19, 0, 2'd0, 8'h00, 1, 1);   // BZ 1B (taken)

        // ------------------------------------------------
        // RESET
        // ------------------------------------------------

        cycle;
        cycle;
        reset = 1'b0;

        check(dbg_pc === 8'h00, "Reset: PC = 0");

        // ------------------------------------------------
        // EXECUTION TRACE
        // ------------------------------------------------

        for (k = 0; k < STEPS; k = k + 1) begin
            check(dbg_halt === 1'b0 &&
                  dbg_pc === exp_pc[k] &&
                  dbg_zero_flag === exp_z[k] &&
                  dbg_carry_flag === exp_c[k] &&
                  (!exp_wr[k] || (dbg_wb_addr === exp_addr[k] &&
                                  dbg_wb_data === exp_data[k])),
                  "Trace step matches expected PC / write-back / flags");
            cycle;
        end

        // ------------------------------------------------
        // HALT
        // ------------------------------------------------

        check(dbg_pc === 8'h1B, "PC reaches 0x1B (HALT), 0x1A skipped");
        check(dbg_halt === 1'b1, "HALT asserted");
        check(dbg_zero_flag === 1'b1 && dbg_carry_flag === 1'b1,
              "Final flags: Z = 1, C = 1");

        cycle;
        cycle;
        cycle;

        check(dbg_pc === 8'h1B && dbg_halt === 1'b1,
              "PC stays at 0x1B while halted");

        // ------------------------------------------------
        // SUMMARY
        // ------------------------------------------------

        $display("");
        $display("========================================");
        $display("     FPGA TOP (program.mem) TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL FPGA TOP TESTS PASSED!");
        else
            $display("FPGA TOP TESTS FAILED!");

        $display("========================================");

        $finish;

    end

endmodule
