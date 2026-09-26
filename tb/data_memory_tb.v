`timescale 1ns / 1ps

module data_memory_tb;

    integer passed;
    integer failed;

    reg        clk;
    reg        reset;
    reg        mem_read;
    reg        mem_write;

    reg  [7:0] address;
    reg  [7:0] write_data;

    wire [7:0] read_data;

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------

    data_memory uut (
        .clk(clk),
        .reset(reset),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .address(address),
        .write_data(write_data),
        .read_data(read_data)
    );

    // 10 ns clock
    always #5 clk = ~clk;


    // --------------------------------------------------
    // READ CHECK TASK
    // --------------------------------------------------

    task check_read;
        input [7:0] test_address;
        input [7:0] expected_data;

        begin

            address  = test_address;
            mem_read = 1'b1;

            #1;

            if (read_data == expected_data) begin

                $display("PASS: READ address=%h data=%h",
                         test_address,
                         read_data);

                passed = passed + 1;

            end
            else begin

                $display("FAIL: READ address=%h",
                         test_address);

                $display("      Expected=%h",
                         expected_data);

                $display("      Got=%h",
                         read_data);

                failed = failed + 1;

            end

            mem_read = 1'b0;

        end
    endtask


    // --------------------------------------------------
    // WRITE TASK
    // --------------------------------------------------

    task check_write;
        input [7:0] test_address;
        input [7:0] test_data;

        begin

            address   = test_address;
            write_data = test_data;
            mem_write = 1'b1;

            // Wait for rising edge
            #10;

            mem_write = 1'b0;

            // Read back immediately
            mem_read = 1'b1;
            #1;

            if (read_data == test_data) begin

                $display("PASS: WRITE address=%h data=%h",
                         test_address,
                         read_data);

                passed = passed + 1;

            end
            else begin

                $display("FAIL: WRITE address=%h",
                         test_address);

                $display("      Expected=%h",
                         test_data);

                $display("      Got=%h",
                         read_data);

                failed = failed + 1;

            end

            mem_read = 1'b0;

        end
    endtask


    // --------------------------------------------------
    // TESTS
    // --------------------------------------------------

    initial begin

        passed = 0;
        failed = 0;

        clk       = 0;
        reset     = 0;
        mem_read  = 0;
        mem_write = 0;
        address   = 8'h00;
        write_data = 8'h00;


        // --------------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------------

        reset = 1'b1;

        #10;

        reset = 1'b0;

        $display("RESET COMPLETE");


        // --------------------------------------------------
        // TEST 2: WRITE 0x10 TO ADDRESS 0x00
        // --------------------------------------------------

        check_write(
            8'h00,
            8'h10
        );


        // --------------------------------------------------
        // TEST 3: WRITE 0x25 TO ADDRESS 0x01
        // --------------------------------------------------

        check_write(
            8'h01,
            8'h25
        );


        // --------------------------------------------------
        // TEST 4: WRITE 0xAA TO ADDRESS 0x55
        // --------------------------------------------------

        check_write(
            8'h55,
            8'hAA
        );


        // --------------------------------------------------
        // TEST 5: WRITE 0xFF TO LAST ADDRESS
        // --------------------------------------------------

        check_write(
            8'hFF,
            8'hFF
        );


        // --------------------------------------------------
        // TEST 6: READ ADDRESS 0x00
        // --------------------------------------------------

        check_read(
            8'h00,
            8'h10
        );


        // --------------------------------------------------
        // TEST 7: READ ADDRESS 0x01
        // --------------------------------------------------

        check_read(
            8'h01,
            8'h25
        );


        // --------------------------------------------------
        // TEST 8: READ ADDRESS 0x55
        // --------------------------------------------------

        check_read(
            8'h55,
            8'hAA
        );


        // --------------------------------------------------
        // TEST 9: READ ADDRESS 0xFF
        // --------------------------------------------------

        check_read(
            8'hFF,
            8'hFF
        );


        // --------------------------------------------------
        // TEST 10: WRITE DISABLED
        // Existing value must remain unchanged
        // --------------------------------------------------

        address    = 8'h55;
        write_data = 8'h00;
        mem_write  = 1'b0;

        #10;

        mem_read = 1'b1;
        #1;

        if (read_data == 8'hAA) begin

            $display("PASS: WRITE disabled, memory retained AA");

            passed = passed + 1;

        end
        else begin

            $display("FAIL: WRITE disabled, memory changed");

            $display("      Expected=AA");
            $display("      Got=%h", read_data);

            failed = failed + 1;

        end

        mem_read = 1'b0;


        // --------------------------------------------------
        // TEST 11: READ DISABLED
        // --------------------------------------------------

        address   = 8'h55;
        mem_read  = 1'b0;

        #1;

        if (read_data == 8'h00) begin

            $display("PASS: READ disabled, output is 00");

            passed = passed + 1;

        end
        else begin

            $display("FAIL: READ disabled");

            $display("      Expected=00");
            $display("      Got=%h", read_data);

            failed = failed + 1;

        end


        // --------------------------------------------------
        // SUMMARY
        // --------------------------------------------------

        $display("");
        $display("========================================");
        $display("        DATA MEMORY TEST SUMMARY");
        $display("========================================");
        $display("PASSED = %0d", passed);
        $display("FAILED = %0d", failed);
        $display("========================================");

        if (failed == 0)
            $display("ALL DATA MEMORY TESTS PASSED!");
        else
            $display("DATA MEMORY TESTS FAILED!");

        $finish;

    end

endmodule