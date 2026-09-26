`timescale 1ns / 1ps

module program_memory_tb;

    integer passed;
    integer failed;

    reg  [7:0]  address;
    wire [15:0] instruction;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    program_memory uut (
        .address(address),
        .instruction(instruction)
    );

    // --------------------------------------------------
    // TEST TASK
    // --------------------------------------------------

    task check_memory;
        input [7:0]  test_address;
        input [15:0] expected_instruction;

        begin

            address = test_address;
            #1;

            if (instruction == expected_instruction) begin

                $display("PASS: Address=%h Instruction=%h",
                         test_address,
                         instruction);

                passed = passed + 1;

            end
            else begin

                $display("FAIL: Address=%h",
                         test_address);

                $display("      Expected=%h",
                         expected_instruction);

                $display("      Got=%h",
                         instruction);

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

        address = 8'h00;

        // --------------------------------------------------
        // Put known instructions into program memory
        // --------------------------------------------------

        uut.memory[8'h00] = 16'h800A;  // LOADI R0, 10
        uut.memory[8'h01] = 16'h8420;  // LOADI R1, 32
        uut.memory[8'h02] = 16'h0520;  // Example instruction
        uut.memory[8'h05] = 16'hB055;  // JMP 0x55
        uut.memory[8'h10] = 16'hD000;  // HALT
        uut.memory[8'h55] = 16'h0000;  // NOP
        uut.memory[8'hAA] = 16'h1234;
        uut.memory[8'hFF] = 16'hABCD;

        // --------------------------------------------------
        // TEST 1
        // --------------------------------------------------

        check_memory(
            8'h00,
            16'h800A
        );

        // --------------------------------------------------
        // TEST 2
        // --------------------------------------------------

        check_memory(
            8'h01,
            16'h8420
        );

        // --------------------------------------------------
        // TEST 3
        // --------------------------------------------------

        check_memory(
            8'h02,
            16'h0520
        );

        // --------------------------------------------------
        // TEST 4
        // --------------------------------------------------

        check_memory(
            8'h05,
            16'hB055
        );

        // --------------------------------------------------
        // TEST 5
        // --------------------------------------------------

        check_memory(
            8'h10,
            16'hD000
        );

        // --------------------------------------------------
        // TEST 6
        // --------------------------------------------------

        check_memory(
            8'h55,
            16'h0000
        );

        // --------------------------------------------------
        // TEST 7
        // --------------------------------------------------

        check_memory(
            8'hAA,
            16'h1234
        );

        // --------------------------------------------------
        // TEST 8
        // --------------------------------------------------

        check_memory(
            8'hFF,
            16'hABCD
        );

        // --------------------------------------------------
        // SUMMARY
        // --------------------------------------------------

        $display("");
        $display("========================================");
        $display("      PROGRAM MEMORY TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL PROGRAM MEMORY TESTS PASSED!");
        else
            $display("PROGRAM MEMORY TESTS FAILED!");

        $finish;

    end

endmodule