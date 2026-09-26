module pc (
    input  wire       clk,
    input  wire       reset,
    input  wire       enable,
    input  wire       load,
    input  wire [7:0] load_value,
    output reg  [7:0] pc
);

    always @(posedge clk) begin

        if (reset) begin
            pc <= 8'b0;
        end

        else if (load) begin
            pc <= load_value;
        end

        else if (enable) begin
            pc <= pc + 8'd1;
        end

    end

endmodule