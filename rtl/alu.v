module alu (
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [2:0] OP,

    output reg  [7:0] RESULT,
    output reg        ZERO,
    output reg        CARRY
);

always @(*) begin

    // Default values
    RESULT = 8'b00000000;
    CARRY  = 1'b0;

    case (OP)

        3'b000: begin
            {CARRY, RESULT} = A + B;
        end

        3'b001: begin
            RESULT = A - B;

            if (A >= B)
                CARRY = 1'b1;   // No borrow
            else
                CARRY = 1'b0;   // Borrow occurred
        end

        3'b010: begin
            RESULT = A & B;
        end

        3'b011: begin
            RESULT = A | B;
        end

        3'b100: begin
            RESULT = A ^ B;
        end

        3'b101: begin
            {CARRY, RESULT} = A + 8'b00000001;
        end

        3'b110: begin
            RESULT = A - 8'b00000001;

            if (A >= 8'd1)
                CARRY = 1'b1;   // No borrow
            else
                CARRY = 1'b0;   // Borrow occurred
        end

        3'b111: begin
            RESULT = A;
        end

        default: begin
            RESULT = 8'b00000000;
            CARRY  = 1'b0;
        end

    endcase

    // Zero flag
    if (RESULT == 8'b00000000)
        ZERO = 1'b1;
    else
        ZERO = 1'b0;

end

endmodule