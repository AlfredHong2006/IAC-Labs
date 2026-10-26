#!/bin/sh
rm -rf obj_dir
rm -f sigdelay.vcd
verilator -Wall --cc --trace sigdelay.sv counter.sv ramaudio2port.sv --exe sigdelay_tb.cpp
make -j -C obj_dir/ -f Vsigdelay.mk Vsigdelay
obj_dir/Vsigdelay
