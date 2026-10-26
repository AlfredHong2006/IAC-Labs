#include "Vf1_fsm.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "vbuddy.cpp"

int main(int argc, char **argv, char **env){
    int i;
    int clk;

    Verilated::commandArgs(argc, argv);
    Vf1_fsm* top = new Vf1_fsm;
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("f1_fsm.vcd");

    //init Vbuddy
    if (vbdOpen()!=1) return(-1);

    vbdSetMode(1);
    vbdHeader("L3T2: F1 Lights");

    top->clk = 1;
    top->rst=1;
    top->en =0;

    for (i=0;i<30000;i++){
        for (clk = 0; clk<2; clk++){
            tfp->dump (2*i+clk);
            top->clk = !top->clk;
            top->eval ();
        }


    vbdBar(top->data_out & 0xFF);
    vbdCycle(i+1);
    //end of Vbuddy output section
    top->rst = (i<2);
    // top->en = (i>4);
    top->en = vbdFlag();
    if (Verilated::gotFinish()||(vbdGetkey() == 'q')) exit(0);
    }

    vbdClose();
    tfp->close();
    exit(0);
}