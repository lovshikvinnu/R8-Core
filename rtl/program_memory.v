module program_memory #(
    parameter INIT_FILE = ""
) (
    input  wire [7:0]  address,
    output wire [15:0] instruction
);

    reg [15:0] memory [0:255];

    // Optional initialization. When INIT_FILE is empty (default), the
    // memory is left uninitialized so testbenches can preload it.
    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, memory);
        end
    end

    assign instruction = memory[address];

endmodule
