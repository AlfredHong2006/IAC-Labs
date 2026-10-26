module counter #(
    parameter WIDTH = 9
)(
    input logic clk,
    input logic rst,
    input logic en,
    output logic [WIDTH-1:0] count,
    input logic [WIDTH -1:0] incr
);

always_ff @ (posedge clk)
    if (rst) count <= {WIDTH{1'b0}};
    // else count <= count + {{WIDTH-1{1'b0}}, en};

    else if (en) count <= count + incr;
endmodule

