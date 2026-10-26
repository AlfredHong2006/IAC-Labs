module ramaudio2port #(
    parameter   ADDRESS_WIDTH = 9,
                DATA_WIDTH = 8

)(
    input logic     clk,
    input logic wr_en,
    input logic rd_en,
    input logic [ADDRESS_WIDTH-1:0] wr_addr,
    input logic [ADDRESS_WIDTH-1:0] rd_addr,

    output logic [DATA_WIDTH-1:0] dout,
    input logic [DATA_WIDTH-1:0] din
);

logic [DATA_WIDTH-1:0] ram_array [2**ADDRESS_WIDTH-1:0];

always_ff @(posedge clk) begin
    if (wr_en)
        ram_array[wr_addr] <=din;
    
    if (rd_en)
        dout <= ram_array[rd_addr];
    

end
endmodule
