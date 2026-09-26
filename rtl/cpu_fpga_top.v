module cpu_fpga_top (
    input  wire       clk,
    input  wire       reset,

    output wire [7:0] dbg_pc,
    output wire       dbg_halt,
    output wire       dbg_zero_flag,
    output wire       dbg_carry_flag,
    output wire [7:0] dbg_wb_data,
    output wire [1:0] dbg_wb_addr
);

    // ==================================================
    // FPGA / SYNTHESIS ENTRY POINT
    // ==================================================

    /*
     * Contains no CPU logic. It selects the program memory
     * image and exposes the CPU debug outputs.
     */

    cpu #(
        .PROGRAM_INIT_FILE("program.mem")
    ) cpu_core (
        .clk(clk),
        .reset(reset),

        .dbg_pc(dbg_pc),
        .dbg_halt(dbg_halt),
        .dbg_zero_flag(dbg_zero_flag),
        .dbg_carry_flag(dbg_carry_flag),
        .dbg_wb_data(dbg_wb_data),
        .dbg_wb_addr(dbg_wb_addr)
    );

endmodule
