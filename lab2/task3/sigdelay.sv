//top level module
//combines the dual-port RAM with counter

module sigdelay #(
    parameter A_WIDTH = 9, //512 slots
    D_WIDTH = 8 //audio is 0-255
)(
    input logic     clk,
    input logic     rst,
    input logic     wr,
    input logic rd,

    input logic [A_WIDTH-1:0] offset, //difference between read and write value address
    input logic [D_WIDTH-1:0]mic_signal,
    output logic [D_WIDTH-1:0] delayed_signal
) ;

logic [A_WIDTH-1:0] address;

counter addrCounter(
    .clk (clk),
    .rst (rst),
    .en (1'b1), //enable always on
    .incr (9'b1), //step up by 1 each clock cycle 512 values
    .count (address)
);
ramaudio2port audioRam (
    .clk (clk),
    .wr_addr(address),
    .rd_en(rd),
    .wr_en(wr),

    .rd_addr(address - offset),
    .dout(delayed_signal),
    .din(mic_signal)
    
);
endmodule
