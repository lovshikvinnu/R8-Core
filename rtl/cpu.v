module cpu #(
    parameter PROGRAM_INIT_FILE = ""
) (
    input wire clk,
    input wire reset,

    // Debug outputs (pure copies of internal signals)
    output wire [7:0] dbg_pc,
    output wire       dbg_halt,
    output wire       dbg_zero_flag,
    output wire       dbg_carry_flag,
    output wire [7:0] dbg_wb_data,
    output wire [1:0] dbg_wb_addr
);

    // ==================================================
    // CONTROL SIGNALS
    // ==================================================

    wire       reg_write;
    wire       alu_enable;
    wire [2:0] alu_op;

    wire       mem_read;
    wire       mem_write;

    wire       pc_enable;
    wire       pc_jump;
    wire       branch_enable;

    wire       halt;


    // ==================================================
    // PROGRAM COUNTER
    // ==================================================

    wire [7:0] pc_value;
    wire [7:0] address;

    /*
     * NOTE:
     * The PC increments when pc_enable is set, and loads
     * instruction[7:0] when pc_jump is set (JMP, taken BZ).
     */

    pc program_counter (
        .clk(clk),
        .reset(reset),
        .enable(pc_enable),
        .load(pc_jump),
        .load_value(address),
        .pc(pc_value)
    );


    // ==================================================
    // PROGRAM MEMORY
    // ==================================================

    wire [15:0] instruction;

    program_memory #(
        .INIT_FILE(PROGRAM_INIT_FILE)
    ) instruction_memory (
        .address(pc_value),
        .instruction(instruction)
    );


    // ==================================================
    // INSTRUCTION DECODER
    // ==================================================

    wire [3:0] opcode;
    wire [1:0] ra;
    wire [1:0] rb;
    wire [9:0] immediate;

    decoder instruction_decoder (
        .instruction(instruction),

        .opcode(opcode),
        .ra(ra),
        .rb(rb),
        .immediate(immediate),
        .address(address)
    );


    // ==================================================
    // FLAGS
    // ==================================================

    wire zero_flag;
    wire carry_flag;

    wire update_zero;
    wire update_carry;

    assign update_zero =
           (opcode == 4'b0001) ||   // ADD
           (opcode == 4'b0010) ||   // SUB
           (opcode == 4'b0011) ||   // AND
           (opcode == 4'b0100) ||   // OR
           (opcode == 4'b0101) ||   // XOR
           (opcode == 4'b0110) ||   // INC
           (opcode == 4'b0111);      // DEC

    assign update_carry =
           (opcode == 4'b0001) ||   // ADD
           (opcode == 4'b0010) ||   // SUB
           (opcode == 4'b0110) ||   // INC
           (opcode == 4'b0111);      // DEC


    // ==================================================
    // CONTROL UNIT
    // ==================================================

    control_unit controller (
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


    // ==================================================
    // REGISTER FILE
    // ==================================================

    wire [7:0] reg_data_a;
    wire [7:0] reg_data_b;

    wire [7:0] writeback_data;
    wire [1:0] writeback_addr;

    assign writeback_addr = ra;

    register_file registers (
        .clk(clk),
        .reset(reset),

        .write_enable(reg_write),
        .write_addr(writeback_addr),
        .write_data(writeback_data),

        .read_addr_a(ra),
        .read_addr_b(rb),

        .read_data_a(reg_data_a),
        .read_data_b(reg_data_b)
    );


    // ==================================================
    // ALU
    // ==================================================

    wire [7:0] alu_result;
    wire       alu_zero;
    wire       alu_carry;

    alu arithmetic_logic_unit (
        .A(reg_data_a),
        .B(reg_data_b),
        .OP(alu_op),

        .RESULT(alu_result),
        .ZERO(alu_zero),
        .CARRY(alu_carry)
    );


    // ==================================================
    // FLAG REGISTER
    // ==================================================

    /*
     * The ALU calculates the current flags.
     *
     * They are stored in the flags register on the clock
     * edge when update_zero / update_carry is set. BZ uses
     * the stored zero_flag, not the ALU's zero output.
     */

    flags cpu_flags (
        .clk(clk),
        .reset(reset),

        .update_zero(update_zero),
        .update_carry(update_carry),

        .zero_in(alu_zero),
        .carry_in(alu_carry),

        .zero_flag(zero_flag),
        .carry_flag(carry_flag)
    );


    // ==================================================
    // DATA MEMORY
    // ==================================================

    wire [7:0] data_memory_read;

    data_memory data_mem (
        .clk(clk),
        .reset(reset),

        .mem_read(mem_read),
        .mem_write(mem_write),

        .address(address),
        .write_data(reg_data_a),

        .read_data(data_memory_read)
    );


    // ==================================================
    // WRITE-BACK MUX
    // ==================================================

    /*
     * Possible register write-back sources:
     *
     * Arithmetic/logical instruction -> ALU result
     * LOADI                         -> immediate
     * LOAD                          -> data memory
     */

    reg [1:0] writeback_select;

    always @(*) begin

        case (opcode)

            // LOADI
            4'b1000: begin
                writeback_select = 2'b01;
            end

            // LOAD
            4'b1001: begin
                writeback_select = 2'b10;
            end

            // ALU operations
            4'b0001,
            4'b0010,
            4'b0011,
            4'b0100,
            4'b0101,
            4'b0110,
            4'b0111: begin
                writeback_select = 2'b00;
            end

            // Default
            default: begin
                writeback_select = 2'b00;
            end

        endcase

    end


    // ==================================================
    // WRITE-BACK DATA
    // ==================================================

    reg [7:0] writeback_data_reg;

    always @(*) begin

        case (writeback_select)

            // ALU result
            2'b00: begin
                writeback_data_reg = alu_result;
            end

            // Immediate
            2'b01: begin
                writeback_data_reg = immediate[7:0];
            end

            // Data memory
            2'b10: begin
                writeback_data_reg = data_memory_read;
            end

            // Default
            default: begin
                writeback_data_reg = 8'b0;
            end

        endcase

    end

    assign writeback_data = writeback_data_reg;


    // ==================================================
    // DEBUG OUTPUTS
    // ==================================================

    assign dbg_pc         = pc_value;
    assign dbg_halt       = halt;
    assign dbg_zero_flag  = zero_flag;
    assign dbg_carry_flag = carry_flag;
    assign dbg_wb_data    = writeback_data;
    assign dbg_wb_addr    = writeback_addr;


endmodule