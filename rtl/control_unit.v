module control_unit (
    input  wire [3:0] opcode,
    input  wire       zero_flag,

    output reg        reg_write,
    output reg        alu_enable,
    output reg [2:0]  alu_op,

    output reg        mem_read,
    output reg        mem_write,

    output reg        pc_enable,
    output reg        pc_jump,
    output reg        branch_enable,

    output reg        halt
);

    always @(*) begin

        // Default control signals
        reg_write     = 1'b0;
        alu_enable    = 1'b0;
        alu_op        = 3'b000;

        mem_read      = 1'b0;
        mem_write     = 1'b0;

        pc_enable     = 1'b1;
        pc_jump       = 1'b0;
        branch_enable = 1'b0;

        halt          = 1'b0;

        case (opcode)

            // ------------------------------------------
            // 0000 : NOP
            // ------------------------------------------
            4'b0000: begin
                // No operation
            end

            // ------------------------------------------
            // 0001 : ADD
            // ------------------------------------------
            4'b0001: begin
                reg_write  = 1'b1;
                alu_enable = 1'b1;
                alu_op     = 3'b000;
            end

            // ------------------------------------------
            // 0010 : SUB
            // ------------------------------------------
            4'b0010: begin
                reg_write  = 1'b1;
                alu_enable = 1'b1;
                alu_op     = 3'b001;
            end

            // ------------------------------------------
            // 0011 : AND
            // ------------------------------------------
            4'b0011: begin
                reg_write  = 1'b1;
                alu_enable = 1'b1;
                alu_op     = 3'b010;
            end

            // ------------------------------------------
            // 0100 : OR
            // ------------------------------------------
            4'b0100: begin
                reg_write  = 1'b1;
                alu_enable = 1'b1;
                alu_op     = 3'b011;
            end

            // ------------------------------------------
            // 0101 : XOR
            // ------------------------------------------
            4'b0101: begin
                reg_write  = 1'b1;
                alu_enable = 1'b1;
                alu_op     = 3'b100;
            end

            // ------------------------------------------
            // 0110 : INC
            // ------------------------------------------
            4'b0110: begin
                reg_write  = 1'b1;
                alu_enable = 1'b1;
                alu_op     = 3'b101;
            end

            // ------------------------------------------
            // 0111 : DEC
            // ------------------------------------------
            4'b0111: begin
                reg_write  = 1'b1;
                alu_enable = 1'b1;
                alu_op     = 3'b110;
            end

            // ------------------------------------------
            // 1000 : LOADI
            // ------------------------------------------
            4'b1000: begin
                reg_write = 1'b1;
            end

            // ------------------------------------------
            // 1001 : LOAD
            // ------------------------------------------
            4'b1001: begin
                mem_read  = 1'b1;
                reg_write = 1'b1;
            end

            // ------------------------------------------
            // 1010 : STORE
            // ------------------------------------------
            4'b1010: begin
                mem_write = 1'b1;
            end

            // ------------------------------------------
            // 1011 : JMP
            // ------------------------------------------
            4'b1011: begin
                pc_enable = 1'b0;
                pc_jump   = 1'b1;
            end

            // ------------------------------------------
            // 1100 : BZ
            // ------------------------------------------
            4'b1100: begin
                if (zero_flag) begin
                    pc_enable     = 1'b0;
                    pc_jump       = 1'b1;
                    branch_enable = 1'b1;
                end
            end

            // ------------------------------------------
            // 1101 : HALT
            // ------------------------------------------
            4'b1101: begin
                pc_enable = 1'b0;
                halt      = 1'b1;
            end

            // ------------------------------------------
            // 1110 : RESERVED
            // ------------------------------------------
            4'b1110: begin
                // Treat reserved instruction as NOP
            end

            // ------------------------------------------
            // 1111 : RESERVED
            // ------------------------------------------
            4'b1111: begin
                // Treat reserved instruction as NOP
            end

            // ------------------------------------------
            // Safety default
            // ------------------------------------------
            default: begin
                // Keep default control signals
            end

        endcase

    end

endmodule