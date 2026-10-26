# IAC Lab 2 – Signal Generation and Capture (notes)

## Big picture
Every task is the same idea: a **counter generates addresses**, and those addresses point into a **memory**. Whatever is stored in the memory comes out over time.

| Task | Memory | What's stored | Result |
|---|---|---|---|
| 1 | ROM, 256 × 8 | one cycle of a sine/cosine | sinewave generator |
| 2 | dual-port ROM | same table, read at two addresses | two waves, phase-shifted |
| 3 | dual-port RAM, 512 × 8 | live mic samples | audio delay line |

Every design = **declare the ports → instantiate the parts → wire them together.**

---

## Task 1 – Sinewave generator

### The sine table (`sinegen.py` → `sinerom.mem`)
```python
v = int(math.cos(2*3.1416*i/256)*127+127)
```
- `i/256` → how far through the table (0 → 1)
- `2π × …` → angle for one full cycle
- `cos(…)` → −1 … +1
- `×127 + 127` → shift to 0 … 254, because the ROM stores **unsigned** 8-bit values (no negatives) → wave centred on 127
- Actually a **cosine** (starts at the top, `FE`), but on screen it looks the same as a sine
- Written as 2-digit hex, 16 per line — layout is just for humans; `$readmemh` ignores spaces/newlines and fills `rom_array[0..255]` in order

### ROM (`rom.sv`)
```systemverilog
module rom #(
    parameter ADDRESS_WIDTH = 8,
              DATA_WIDTH    = 8
)(
    input  logic                     clk,
    input  logic [ADDRESS_WIDTH-1:0] addr,
    output logic [DATA_WIDTH-1:0]    dout
);

logic [DATA_WIDTH-1:0] rom_array [2**ADDRESS_WIDTH-1:0];

initial begin
    $display("Loading rom.");
    $readmemh("sinerom.mem", rom_array);
end

always_ff @(posedge clk)
    dout <= rom_array[addr];

endmodule
```
- `rom_array [2**ADDRESS_WIDTH-1:0]` = 256 slots, each 8 bits
- `$readmemh` loads the hex file at the start of simulation
- Synchronous read: `dout` appears one clock after `addr`

### Counter with step size (`counter.sv`)
```systemverilog
always_ff @(posedge clk)
    if (rst)     count <= {WIDTH{1'b0}};
    else if (en) count <= count + incr;
```
- New input `incr` = step size (Lab 1 only ever added 1)

### Top level (`sinegen.sv`)
- Inputs `clk, rst, en, incr`; output `dout`
- One internal wire `address`: counter's `count` → ROM's `addr`

### Why `incr` changes the frequency
- `incr = 1` → visits all 256 samples → 1 wave per 256 clocks
- `incr = 2` → skips every other sample → 2× frequency
- **f_out = incr × f_clk / 256**
- This is **Direct Digital Synthesis (DDS)** — how real digital signal generators work
- Challenge: `top->incr = vbdValue();` → the knob sets the frequency (starts at 0 = flat line until you turn it)

### Testbench additions
- 1,000,000 cycles, so press **q** to quit:
```cpp
if ((Verilated::gotFinish()) || (vbdGetkey()=='q')) exit(0);
```
- `vbdGetkey()` is non-blocking — returns immediately if no key pressed

---

## Task 2 – Sine & cosine (dual-port ROM)

- **One** `rom_array`, **two** read ports (`addr1/dout1`, `addr2/dout2`) — no need for two copies of the table
- Two statements in one `always_ff` need `begin … end`:
```systemverilog
always_ff @(posedge clk) begin
    dout1 <= rom_array[addr1];
    dout2 <= rom_array[addr2];
end
```
- In `sinegen.sv`: `addr1 = address`, `addr2 = address + offset`; new input `offset`
- Testbench: `incr` fixed at 1, `offset = vbdValue()`, `vbdPlot` called twice

### Why offset 64 = sine & cosine
- 256 entries = 360°, so 1 entry ≈ 1.4°
- 90° = a quarter of the table = 256 ÷ 4 = **64**
- 128 = 180° → mirror images
- The knob counts **table entries, not degrees** (knob at 90 ≈ 127°)
- 90°-apart pairs = **quadrature signals**, used in communications

---

## Task 3 – Audio delay (dual-port RAM)

### Dual-port RAM (`ramaudio2port.sv`), 512 × 8
```systemverilog
module ramaudio2port #(
    parameter ADDRESS_WIDTH = 9,
              DATA_WIDTH    = 8
)(
    input  logic                     clk,
    input  logic                     wr_en,
    input  logic                     rd_en,
    input  logic [ADDRESS_WIDTH-1:0] wr_addr,
    input  logic [ADDRESS_WIDTH-1:0] rd_addr,
    input  logic [DATA_WIDTH-1:0]    din,
    output logic [DATA_WIDTH-1:0]    dout
);

logic [DATA_WIDTH-1:0] ram_array [2**ADDRESS_WIDTH-1:0];

always_ff @(posedge clk) begin
    if (wr_en) ram_array[wr_addr] <= din;
    if (rd_en) dout <= ram_array[rd_addr];
end

endmodule
```
- Like the ROM but **no `$readmemh`** (starts empty; the mic fills it) and it has a **write** port
- Address = **9 bits** (512 slots); data = **8 bits** (audio sample 0–255) — don't swap them

### Top level (`sigdelay.sv`)
- Ports must match the **provided** testbench: `clk, rst, wr, rd, offset[8:0], mic_signal[7:0], delayed_signal[7:0]`
- Testbench never sets `en` or `incr` → they're **not** ports; hard-wire them inside:
  `.en(1'b1)`, `.incr(9'd1)`
- Write address = counter; **read address = counter − offset** → reads older audio = delay
- `mic_signal` → RAM `din`; RAM `dout` → `delayed_signal`

### What the testbench does (already provided)
- `vbdInitMicIn(RAM_SZ)` — once, tells Vbuddy to record in 512-sample blocks
- `top->mic_signal = vbdMicValue();` — every cycle, next audio sample
- `top->offset = abs(vbdValue());` — knob = delay size
- Nothing plays out — it only records and plots. Use a tone generator (200–500 Hz) or whistle at the mic.

### Result
- Trace 1 = live mic; trace 2 = same signal delayed by `offset` samples
- This is a **delay line** (circular buffer) — the basis of echo/reverb effects

---

## SystemVerilog syntax I learned

### Instantiating a module with parameters
```systemverilog
counter #(.WIDTH(A_WIDTH)) addrCounter ( .clk(clk), .count(address), ... );
```
| Piece | Meaning |
|---|---|
| `counter` | which module to build |
| `#(.WIDTH(A_WIDTH))` | set its parameter `WIDTH` for this copy (overrides the default) |
| `addrCounter` | name of this copy (my choice) |
| `.count(address)` | **its** port `count` ← **my** wire `address` |

Like C++ `Counter<9> addrCounter(...)` — but it's real hardware.

### Rules that kept breaking my builds
- Indentation **doesn't matter** (not Python)
- Every port in the list has a **comma except the last**
- An error on line N is often caused by a missing `,` or `;` on line **N−1**
- `if (condition)` needs brackets; two+ statements need `begin … end`
- Module name in an instantiation must match the module's file/name exactly (`ramaudio2port`, not `rom`)
- Port names after the dot must match exactly (`wr_addr`, not `wr_address`)
- No `+=` in port connections — just `address - offset`
- Every `.sv` file must **end with a newline** (`-Wall` makes the EOFNEWLINE warning fatal)
- Typos seen: `cik`, `intput`, `postedge`

## Workflow
- `doit.sh` per task: list **all** `.sv` files (top module first) and rename `Vcounter` → `V<top>`
- Each task folder needs `vbuddy.cfg` (`/dev/ttyUSB0`) — the repo doesn't include it
- Navigate with `cd ../task3` (sibling folder), Tab to autocomplete, `pwd` / `ls` to check
- `obj_dir/V… not found` just means the build failed — scroll up for the `%Error`

## To do
- Rebuild `sigdelay.sv` and `ramaudio2port.sv` from a blank file without looking
