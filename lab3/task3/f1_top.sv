module  f1_top (
    input   logic       clk,
    input   logic       rst,
    input logic [15:0] N,
    output  logic [7:0] data_out
);

logic tick;

clktick myClock(
    .clk(clk),
    .rst(rst),
    .en(1'b1),
    .N (N),
    .tick(tick)
);

f1_fsm myFSM (
    .clk(clk),
    .rst(rst),
    .en(tick),
    .data_out(data_out)
);

endmodule
