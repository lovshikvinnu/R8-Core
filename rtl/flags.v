module flags (
    input  wire       clk,
    input  wire       reset,

    input  wire       update_zero,
    input  wire       update_carry,

    input  wire       zero_in,
    input  wire       carry_in,

    output reg        zero_flag,
    output reg        carry_flag
);

    always @(posedge clk) begin

        if (reset) begin
            zero_flag  <= 1'b0;
            carry_flag <= 1'b0;
        end
        else begin

            if (update_zero)
                zero_flag <= zero_in;

            if (update_carry)
                carry_flag <= carry_in;

        end

    end

endmodule
