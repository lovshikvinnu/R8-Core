module decoder (
    input  wire [15:0] instruction,

    output wire [3:0]  opcode,
    output wire [1:0]  ra,
    output wire [1:0]  rb,
    output wire [9:0]  immediate,
    output wire [7:0]  address
);

    assign opcode    = instruction[15:12];
    assign ra        = instruction[11:10];
    assign rb        = instruction[9:8];
    assign immediate = instruction[9:0];
    assign address   = instruction[7:0];

endmodule