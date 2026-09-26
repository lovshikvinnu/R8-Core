`timescale 1ns / 1ps

module register_file_tb;

    integer passed;
    integer failed;
    reg        clk;
    reg        reset;

    reg        write_enable;
    reg  [1:0] write_addr;
    reg  [7:0] write_data;

    reg  [1:0] read_addr_a;
    reg  [1:0] read_addr_b;

    wire [7:0] read_data_a;
    wire [7:0] read_data_b;

    register_file uut (
        .clk(clk),
        .reset(reset),

        .write_enable(write_enable),
        .write_addr(write_addr),
        .write_data(write_data),

        .read_addr_a(read_addr_a),
        .read_addr_b(read_addr_b),

        .read_data_a(read_data_a),
        .read_data_b(read_data_b)
    );

always #5 clk = ~clk;

initial begin
    passed = 0;
    failed = 0;

    clk = 0;
    reset = 0;

    write_enable = 0;
    write_addr = 0;
    write_data = 0;

    read_addr_a = 0;
    read_addr_b = 0;

    // Apply reset
    reset = 1;
    #10;

    reset = 0;
    #5;

    // Check R0 and R1
    read_addr_a = 2'b00;
    read_addr_b = 2'b01;
    #1;

    if (read_data_a == 8'd0 && read_data_b == 8'd0) begin
        $display("PASS: R0 and R1 reset to 0");
        passed = passed + 1;
    end
    else begin
        $display("FAIL: R0 = %d, R1 = %d", read_data_a, read_data_b);
        failed = failed + 1;
    end

    // Check R2 and R3
    read_addr_a = 2'b10;
    read_addr_b = 2'b11;
    #1;

    if (read_data_a == 8'd0 && read_data_b == 8'd0) begin
        $display("PASS: R2 and R3 reset to 0");
        passed = passed + 1;
    end
    else begin
        $display("FAIL: R2 = %d, R3 = %d", read_data_a, read_data_b);
        failed = failed + 1;
    end

    // Write 10 to R0
    write_enable = 1;
    write_addr = 2'b00;
    write_data = 8'd10;

    #10;

    write_enable = 0;

    // Read R0
    read_addr_a = 2'b00;
    #1;

    if (read_data_a == 8'd10) begin
        $display("PASS: R0 = 10");
        passed = passed + 1;
    end
    else begin
        $display("FAIL: R0 = %d, expected 10", read_data_a);
        failed = failed + 1;
    end

    // Write 25 to R1
    write_enable = 1;
    write_addr = 2'b01;
    write_data = 8'd25;

    #10;

    write_enable = 0;

    read_addr_a = 2'b01;
    #1;

    if (read_data_a == 8'd25) begin
        $display("PASS: R1 = 25");
        passed = passed + 1;
    end
    else begin
        $display("FAIL: R1 = %d, expected 25", read_data_a);
        failed = failed + 1;
    end

    // Write 170 to R2
    write_enable = 1;
    write_addr = 2'b10;
    write_data = 8'd170;

    #10;

    write_enable = 0;

    read_addr_a = 2'b10;
    #1;

    if (read_data_a == 8'd170) begin
        $display("PASS: R2 = 170");
        passed = passed + 1;
    end
    else begin
        $display("FAIL: R2 = %d, expected 170", read_data_a);
        failed = failed + 1;
    end

    // Write 255 to R3
    write_enable = 1;
    write_addr = 2'b11;
    write_data = 8'd255;

    #10;

    write_enable = 0;

    read_addr_a = 2'b11;
    #1;

    if (read_data_a == 8'd255) begin
        $display("PASS: R3 = 255");
        passed = passed + 1;
    end
    else begin
        $display("FAIL: R3 = %d, expected 255", read_data_a);
        failed = failed + 1;
    end

    // Test simultaneous dual read
    read_addr_a = 2'b00;
    read_addr_b = 2'b10;
    #1;

    if (read_data_a == 8'd10 && read_data_b == 8'd170) begin
        $display("PASS: Dual read R0 = %d, R2 = %d",
                 read_data_a, read_data_b);
        passed = passed + 1;
    end
    else begin
        $display("FAIL: Dual read R0 = %d, R2 = %d",
                 read_data_a, read_data_b);
        failed = failed + 1;
    end

    // Test write protection
    write_enable = 0;
    write_addr = 2'b00;
    write_data = 8'd99;

    #10;

    read_addr_a = 2'b00;
    #1;

    if (read_data_a == 8'd10) begin
        $display("PASS: Write disabled, R0 remains %d", read_data_a);
        passed = passed + 1;
    end
    else begin
        $display("FAIL: Write disabled, R0 changed to %d",
                 read_data_a);
        failed = failed + 1;
    end

    $display("------------------------------");
    $display("PASSED = %0d", passed);
    $display("FAILED = %0d", failed);
    $display("------------------------------");

    if (failed == 0)
        $display("ALL REGISTER FILE TESTS PASSED!");
    else
        $display("REGISTER FILE VERIFICATION FAILED!");

    $finish;
end

endmodule