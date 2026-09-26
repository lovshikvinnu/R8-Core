`timescale 1ns/1ps

module alu_tb;

    reg [7:0] A;
    reg [7:0] B;
    reg [2:0] OP;

    wire [7:0] RESULT;
    wire ZERO;
    wire CARRY;

    integer passed;
    integer failed;

    alu uut (
        .A(A),
        .B(B),
        .OP(OP),
        .RESULT(RESULT),
        .ZERO(ZERO),
        .CARRY(CARRY)
    );

    // ==========================================
    // TEST TASK
    // ==========================================

    task test_alu;
        input [7:0] test_A;
        input [7:0] test_B;
        input [2:0] test_OP;
        input [7:0] expected_result;
        input expected_zero;
        input expected_carry;

        begin

            A = test_A;
            B = test_B;
            OP = test_OP;

            #10;

            if ((RESULT == expected_result) &&
                (ZERO == expected_zero) &&
                (CARRY == expected_carry)) begin

                $display("[PASS] A=%0d B=%0d OP=%03b -> RESULT=%0d Z=%b C=%b",
                         A, B, OP, RESULT, ZERO, CARRY);

                passed = passed + 1;

            end
            else begin

                $display("[FAIL] A=%0d B=%0d OP=%03b",
                         A, B, OP);

                $display("       Expected: RESULT=%0d Z=%b C=%b",
                         expected_result, expected_zero, expected_carry);

                $display("       Actual:   RESULT=%0d Z=%b C=%b",
                         RESULT, ZERO, CARRY);

                failed = failed + 1;

            end

        end

    endtask


    // ==========================================
    // TESTS
    // ==========================================

    initial begin

        passed = 0;
        failed = 0;

        $display("");
        $display("========================================");
        $display("       8-BIT ALU VERIFICATION");
        $display("========================================");
        $display("");


        // ADD
        test_alu(8'd5, 8'd3, 3'b000,
                 8'd8, 1'b0, 1'b0);

        // ADD overflow
        test_alu(8'd255, 8'd1, 3'b000,
                 8'd0, 1'b1, 1'b1);

        // ADD maximum values
        test_alu(8'd255, 8'd255, 3'b000,
                 8'd254, 1'b0, 1'b1);

        // ADD zero
        test_alu(8'd0, 8'd0, 3'b000,
                 8'd0, 1'b1, 1'b0);


        // SUB
        test_alu(8'd10, 8'd4, 3'b001,
                 8'd6, 1'b0, 1'b1);

        // SUB equal
        test_alu(8'd10, 8'd10, 3'b001,
                 8'd0, 1'b1, 1'b1);

        // SUB borrow
        test_alu(8'd0, 8'd1, 3'b001,
                 8'd255, 1'b0, 1'b0);

        // SUB maximum
        test_alu(8'd255, 8'd1, 3'b001,
                 8'd254, 1'b0, 1'b1);


        // AND
        test_alu(8'hAA, 8'h55, 3'b010,
                 8'h00, 1'b1, 1'b0);

        // OR
        test_alu(8'hAA, 8'h55, 3'b011,
                 8'hFF, 1'b0, 1'b0);

        // XOR
        test_alu(8'hAA, 8'h55, 3'b100,
                 8'hFF, 1'b0, 1'b0);


        // INC
        test_alu(8'd7, 8'd0, 3'b101,
                 8'd8, 1'b0, 1'b0);

        // INC overflow
        test_alu(8'd255, 8'd0, 3'b101,
                 8'd0, 1'b1, 1'b1);


        // DEC
        test_alu(8'd7, 8'd0, 3'b110,
                 8'd6, 1'b0, 1'b1);

        // DEC underflow
        test_alu(8'd0, 8'd0, 3'b110,
                 8'd255, 1'b0, 1'b0);


        // PASS A
        test_alu(8'd42, 8'd0, 3'b111,
                 8'd42, 1'b0, 1'b0);

        // PASS A zero
        test_alu(8'd0, 8'd0, 3'b111,
                 8'd0, 1'b1, 1'b0);


        // ==========================================
        // SUMMARY
        // ==========================================

        $display("");
        $display("========================================");
        $display("              TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL ALU TESTS PASSED!");
        else
            $display("ALU VERIFICATION FAILED!");

        $display("");

        $finish;

    end

endmodule