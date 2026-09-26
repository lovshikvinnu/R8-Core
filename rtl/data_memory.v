module data_memory (
    input  wire       clk,
    input  wire       reset,

    input  wire       mem_read,
    input  wire       mem_write,

    input  wire [7:0] address,
    input  wire [7:0] write_data,

    output wire [7:0] read_data
);

    // 256 locations, each 8 bits wide
    reg [7:0] memory [0:255];

    // --------------------------------------------------
    // WRITE
    // --------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin
            memory[0] <= 8'b0;
            memory[1] <= 8'b0;
            memory[2] <= 8'b0;
            memory[3] <= 8'b0;
            memory[4] <= 8'b0;
            memory[5] <= 8'b0;
            memory[6] <= 8'b0;
            memory[7] <= 8'b0;
        end

        else if (mem_write) begin
            memory[address] <= write_data;
        end

    end

    // --------------------------------------------------
    // READ
    // --------------------------------------------------

    assign read_data = mem_read ? memory[address] : 8'b0;

endmodule