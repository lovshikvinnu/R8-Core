`timescale 1ns / 1ps

module control_unit_tb;

    integer passed;
    integer failed;

    reg  [3:0] opcode;
    reg        zero_flag;

    wire       reg_write;
    wire       alu_enable;
    wire [2:0] alu_op;

    wire       mem_read;
    wire       mem_write;

    wire       pc_enable;
    wire       pc_jump;
    wire       branch_enable;

    wire       halt;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    control_unit uut (
        .opcode(opcode),
        .zero_flag(zero_flag),

        .reg_write(reg_write),
        .alu_enable(alu_enable),
        .alu_op(alu_op),

        .mem_read(mem_read),
        .mem_write(mem_write),

        .pc_enable(pc_enable),
        .pc_jump(pc_jump),
        .branch_enable(branch_enable),

        .halt(halt)
    );

    // --------------------------------------------------
    // TEST TASK
    // --------------------------------------------------

    task check_control;
        input [3:0] expected_opcode;
        input       test_zero_flag;

        input       expected_reg_write;
        input       expected_alu_enable;
        input [2:0] expected_alu_op;

        input       expected_mem_read;
        input       expected_mem_write;

        input       expected_pc_enable;
        input       expected_pc_jump;
        input       expected_branch_enable;

        input       expected_halt;

        begin

            opcode    = expected_opcode;
            zero_flag = test_zero_flag;

            #1;

            if ((reg_write     == expected_reg_write) &&
                (alu_enable    == expected_alu_enable) &&
                (alu_op        == expected_alu_op) &&
                (mem_read      == expected_mem_read) &&
                (mem_write     == expected_mem_write) &&
                (pc_enable     == expected_pc_enable) &&
                (pc_jump       == expected_pc_jump) &&
                (branch_enable == expected_branch_enable) &&
                (halt          == expected_halt)) begin

                $display("PASS: OPCODE=%b ZERO=%b",
                         expected_opcode,
                         test_zero_flag);

                passed = passed + 1;

            end
            else begin

                $display("FAIL: OPCODE=%b ZERO=%b",
                         expected_opcode,
                         test_zero_flag);

                $display("      Expected:");
                $display("      REG_WRITE=%b ALU_ENABLE=%b ALU_OP=%b",
                         expected_reg_write,
                         expected_alu_enable,
                         expected_alu_op);

                $display("      MEM_READ=%b MEM_WRITE=%b",
                         expected_mem_read,
                         expected_mem_write);

                $display("      PC_ENABLE=%b PC_JUMP=%b BRANCH=%b HALT=%b",
                         expected_pc_enable,
                         expected_pc_jump,
                         expected_branch_enable,
                         expected_halt);

                $display("      Got:");
                $display("      REG_WRITE=%b ALU_ENABLE=%b ALU_OP=%b",
                         reg_write,
                         alu_enable,
                         alu_op);

                $display("      MEM_READ=%b MEM_WRITE=%b",
                         mem_read,
                         mem_write);

                $display("      PC_ENABLE=%b PC_JUMP=%b BRANCH=%b HALT=%b",
                         pc_enable,
                         pc_jump,
                         branch_enable,
                         halt);

                failed = failed + 1;

            end
        end
    endtask


    // --------------------------------------------------
    // TESTS
    // --------------------------------------------------

    initial begin

        passed = 0;
        failed = 0;

        opcode    = 4'b0000;
        zero_flag = 1'b0;

        // --------------------------------------------------
        // TEST 1: NOP
        // --------------------------------------------------

        check_control(
            4'b0000, 1'b0,
            1'b0, 1'b0, 3'b000,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 2: ADD
        // --------------------------------------------------

        check_control(
            4'b0001, 1'b0,
            1'b1, 1'b1, 3'b000,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 3: SUB
        // --------------------------------------------------

        check_control(
            4'b0010, 1'b0,
            1'b1, 1'b1, 3'b001,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 4: AND
        // --------------------------------------------------

        check_control(
            4'b0011, 1'b0,
            1'b1, 1'b1, 3'b010,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 5: OR
        // --------------------------------------------------

        check_control(
            4'b0100, 1'b0,
            1'b1, 1'b1, 3'b011,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 6: XOR
        // --------------------------------------------------

        check_control(
            4'b0101, 1'b0,
            1'b1, 1'b1, 3'b100,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 7: INC
        // --------------------------------------------------

        check_control(
            4'b0110, 1'b0,
            1'b1, 1'b1, 3'b101,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 8: DEC
        // --------------------------------------------------

        check_control(
            4'b0111, 1'b0,
            1'b1, 1'b1, 3'b110,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 9: LOADI
        // --------------------------------------------------

        check_control(
            4'b1000, 1'b0,
            1'b1, 1'b0, 3'b000,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 10: LOAD
        // --------------------------------------------------

        check_control(
            4'b1001, 1'b0,
            1'b1, 1'b0, 3'b000,
            1'b1, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 11: STORE
        // --------------------------------------------------

        check_control(
            4'b1010, 1'b0,
            1'b0, 1'b0, 3'b000,
            1'b0, 1'b1,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 12: JMP
        // --------------------------------------------------

        check_control(
            4'b1011, 1'b0,
            1'b0, 1'b0, 3'b000,
            1'b0, 1'b0,
            1'b0, 1'b1, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 13: BZ WITH ZERO = 1
        // Branch should happen
        // --------------------------------------------------

        check_control(
            4'b1100, 1'b1,
            1'b0, 1'b0, 3'b000,
            1'b0, 1'b0,
            1'b0, 1'b1, 1'b1,
            1'b0
        );


        // --------------------------------------------------
        // TEST 14: BZ WITH ZERO = 0
        // Branch should NOT happen
        // --------------------------------------------------

        check_control(
            4'b1100, 1'b0,
            1'b0, 1'b0, 3'b000,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 15: HALT
        // --------------------------------------------------

        check_control(
            4'b1101, 1'b0,
            1'b0, 1'b0, 3'b000,
            1'b0, 1'b0,
            1'b0, 1'b0, 1'b0,
            1'b1
        );


        // --------------------------------------------------
        // TEST 16: RESERVED 1110
        // --------------------------------------------------

        check_control(
            4'b1110, 1'b0,
            1'b0, 1'b0, 3'b000,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // TEST 17: RESERVED 1111
        // --------------------------------------------------

        check_control(
            4'b1111, 1'b0,
            1'b0, 1'b0, 3'b000,
            1'b0, 1'b0,
            1'b1, 1'b0, 1'b0,
            1'b0
        );


        // --------------------------------------------------
        // SUMMARY
        // --------------------------------------------------

        $display("");
        $display("========================================");
        $display("       CONTROL UNIT TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL CONTROL UNIT TESTS PASSED!");
        else
            $display("CONTROL UNIT TESTS FAILED!");

        $finish;

    end

endmodule