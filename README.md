# Custom 8-Bit CPU in Verilog

A custom 8-bit, single-cycle, Harvard-architecture CPU designed from scratch in Verilog HDL, with a locked 16-bit instruction set (ISA v1.0), self-checking module- and system-level verification, and a first real Vivado synthesis run.

The project is complete through **RTL, verification and synthesis**. FPGA implementation, timing analysis and hardware validation have **not** been done yet (see [Project Status](#project-status)).

---

## Project Status

| Area | Status | Evidence |
| :--- | :--- | :--- |
| ISA v1.0 | **Locked** | [`docs/ISA.md`](docs/ISA.md) |
| RTL (9 CPU modules + FPGA wrapper) | **Complete** | [`rtl/`](rtl/) |
| Simulation verification | **278 / 278 checks pass, 0 failures**, in both Icarus Verilog and Vivado XSim (18 testbenches) | [`docs/VERIFICATION.md`](docs/VERIFICATION.md) |
| Strict compile (`xvlog`, no `--relax`) | **0 errors, 0 warnings** over all RTL and testbenches | [`docs/VERIFICATION.md`](docs/VERIFICATION.md) |
| Vivado synthesis (`cpu_fpga_top`, `xczu7ev-ffvc1156-2-e`) | **Completed**: 0 errors, 0 critical warnings, 1 warning | [Synthesis](#synthesis-result) |

**Completed:** RTL, ISA, simulation, verification and synthesis.

**Not yet completed:**
- FPGA board-specific constraints (XDC: clock, pins, I/O standards)
- Implementation (place and route)
- Timing analysis. No clock constraint exists yet, so **no maximum frequency is claimed**.
- Bitstream generation
- Physical FPGA validation

The laboratory FPGA board has not been identified yet. The `xczu7ev` (ZCU104) part was used **for synthesis only**. No pin assignments have been made.

---

## Architecture at a Glance

| Parameter | Value |
| :--- | :--- |
| Architecture | Single-cycle, Harvard (separate program and data memories) |
| Data width | 8 bits |
| Instruction width | 16 bits, fixed length, 3 formats (R, I, J) |
| Registers | 4 × 8-bit general purpose (`R0`–`R3`) |
| Program counter | 8 bits (256 instruction addresses) |
| Program memory | 256 × 16-bit ROM, combinational read, optional `$readmemh` initialization |
| Data memory | 256 × 8-bit, synchronous write, combinational read |
| Flags | `Z` (zero), `C` (carry / no-borrow, ARM-style) |
| Clock / reset | Single clock, synchronous active-high reset |
| Execution | One instruction per clock cycle |

```text
            +------+   pc    +----------------+  instr  +---------+
   +------->|  PC  |-------->| Program Memory |-------->| Decoder |
   |        +------+         +----------------+         +---------+
   |          ^  load/enable                   opcode |  ra, rb | imm, addr
   |          |                                       v         |
   |          |         zero_flag           +--------------+    |
   |          +-----------------------------| Control Unit |    |
   |                                        +--------------+    |
   |                                  reg_write, alu_op, mem_*  |
   |   +---------------+   Ra, Rb    +-----+                    |
   |   | Register File |------------>| ALU |--> Z, C --> [Flags]|
   |   +---------------+             +-----+                    |
   |           ^ write-back                | result              |
   |           |      +---------------+    |                     |
   |           +------| Write-back MUX|<---+---- imm[7:0] <------+
   |                  +---------------+<-------- Data Memory <---+ addr[7:0]
   +------------- JMP / BZ target = instruction[7:0]
```

Full description: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

---

## ISA v1.0 Summary

| Opcode | Mnemonic | Format | Semantics | Z | C |
| :---: | :--- | :---: | :--- | :---: | :---: |
| `0000` | NOP | – | No operation | – | – |
| `0001` | ADD Ra, Rb | R | `Ra = Ra + Rb` | ✓ | ✓ |
| `0010` | SUB Ra, Rb | R | `Ra = Ra - Rb` | ✓ | ✓ |
| `0011` | AND Ra, Rb | R | `Ra = Ra & Rb` | ✓ | – |
| `0100` | OR Ra, Rb | R | `Ra = Ra \| Rb` | ✓ | – |
| `0101` | XOR Ra, Rb | R | `Ra = Ra ^ Rb` | ✓ | – |
| `0110` | INC Ra | R | `Ra = Ra + 1` | ✓ | ✓ |
| `0111` | DEC Ra | R | `Ra = Ra - 1` | ✓ | ✓ |
| `1000` | LOADI Ra, imm | I | `Ra = imm[7:0]` | – | – |
| `1001` | LOAD Ra, addr | I | `Ra = DataMemory[addr]` | – | – |
| `1010` | STORE Ra, addr | I | `DataMemory[addr] = Ra` | – | – |
| `1011` | JMP addr | J | `PC = addr` | – | – |
| `1100` | BZ addr | J | `if (Z) PC = addr` | – | – |
| `1101` | HALT | – | Hold PC (stop) | – | – |
| `1110`, `1111` | RESERVED | – | Executed as NOP | – | – |

For SUB/DEC, `C = 1` means **no borrow**. Encoding details: [`docs/ISA.md`](docs/ISA.md).

---

## Verification Summary

| Level | Testbenches | Checks |
| :--- | :--- | :---: |
| Module (unit) | ALU, Register File, PC, Decoder, Control Unit, Program Memory, Data Memory, Flags | 90 |
| CPU programs | Basic, Memory\*, Branching\*, Loop\*, ISA regression | 98 |
| CPU boundary | Arithmetic, INC/DEC, Data-memory, Control-flow | 49 |
| FPGA wrapper | `cpu_fpga_top` running `mem/program.mem` (ports only) | 41 |
| **Total** | **18 testbenches** | **278 / 278** |

\* The Memory, Branching and Loop suites were **reconstructed** from the current RTL because their original passing source files were unavailable. They are not the historical files. See [`docs/VERIFICATION.md`](docs/VERIFICATION.md).

---

## Synthesis Result

Vivado 2025.1, run `synth_1`, top `cpu_fpga_top`, part `xczu7ev-ffvc1156-2-e`, default synthesis strategy, **no timing constraints**.

| Resource | Used | Available | Util. |
| :--- | ---: | ---: | ---: |
| CLB LUTs | 519 | 230,400 | 0.23% |
| CLB registers (FF) | 1,066 | 460,800 | 0.23% |
| LUTRAM | 0 | 101,760 | 0.00% |
| Block RAM / URAM | 0 / 0 | 312 / 96 | 0.00% |
| DSP | 0 | 1,728 | 0.00% |
| CARRY8 / F7 / F8 muxes | 1 / 129 / 57 | – | – |
| Bonded IOB | 23 | 360 | 6.39% |
| BUFGCE | 1 | 208 | 0.48% |

Messages: 0 errors, 0 critical warnings, 1 warning (`Synth 8-7080 Parallel synthesis criteria is not met`, a synthesis-flow message, not a functional issue).

> **Important caveat:** these numbers describe **this design with this program image**, not a generic CPU area figure. `mem/program.mem` is loaded into the ROM at synthesis time, so Vivado specializes the hardware to that program:
> - The program memory became a **32 × 15 LUT ROM**.
> - The data memory became **flip-flop storage with multiplexers** (no LUTRAM or block RAM).
> - Only **128 of 256** data-memory bytes were kept (`0x00–0x3F`, `0xC0–0xFF`). The fixed program can never produce the other addresses.

**Timing is currently unconstrained** because no XDC clock constraint has been added. No frequency, setup/hold or timing-closure result is claimed.

---

## Repository Structure

```text
8-bit CPU/
├── rtl/                          CPU RTL (Verilog-2001)
│   ├── cpu.v                     Top-level CPU datapath + debug outputs
│   ├── cpu_fpga_top.v            Synthesis/FPGA wrapper (selects program.mem)
│   ├── pc.v                      8-bit program counter
│   ├── program_memory.v          256 × 16 ROM, optional INIT_FILE
│   ├── decoder.v                 Instruction field extraction
│   ├── control_unit.v            Opcode → control signals
│   ├── register_file.v           4 × 8-bit registers
│   ├── alu.v                     8-bit ALU
│   ├── flags.v                   Z / C flag register
│   └── data_memory.v             256 × 8 data memory
├── tb/                           Self-checking testbenches (see VERIFICATION.md)
│   ├── *_tb.v                    8 unit + 9 CPU-level + 1 wrapper testbench
│   └── cpu_tb.v                  Empty legacy placeholder (unused)
├── mem/
│   └── program.mem               28-word ISA coverage program (loaded by cpu_fpga_top)
├── custom_8bit_cpu/              Vivado 2025.1 project (custom_8bit_cpu.xpr)
├── sim/                          Icarus Verilog build outputs (generated, may be stale)
├── docs/
│   ├── ISA.md                    ISA v1.0 specification (locked)
│   ├── ARCHITECTURE.md           Datapath and module descriptions
│   ├── VERIFICATION.md           Test plan, results and evidence
│   ├── DEVELOPMENT_LOG.md        Milestone history
│   └── verification/             Waveform/console screenshots of unit tests
└── README.md
```

---

## Running the Simulations

### Icarus Verilog

Unit test (example):

```bash
iverilog -g2012 -o sim/alu_tb.vvp rtl/alu.v tb/alu_tb.v
vvp sim/alu_tb.vvp
```

CPU-level test (example). `-s` selects the testbench as the only top, because `rtl/*.v` also contains `cpu_fpga_top`:

```bash
iverilog -g2012 -s cpu_isa_regression_tb -o sim/cpu_isa_regression_tb.vvp rtl/*.v tb/cpu_isa_regression_tb.v
vvp sim/cpu_isa_regression_tb.vvp
```

FPGA wrapper test. `program.mem` is opened relative to the working directory, so run `vvp` from `mem/`:

```bash
iverilog -g2012 -s cpu_fpga_top_tb -o sim/cpu_fpga_top_tb.vvp rtl/*.v tb/cpu_fpga_top_tb.v
cd mem && vvp ../sim/cpu_fpga_top_tb.vvp
```

### Vivado 2025.1

Open `custom_8bit_cpu/custom_8bit_cpu.xpr`.

| Fileset | Top | Contents |
| :--- | :--- | :--- |
| Design sources (`sources_1`) | `cpu_fpga_top` | 10 RTL files + `mem/program.mem` |
| Simulation sources (`sim_1`) | `cpu_control_flow_boundary_tb` | 15 testbenches; change the simulation top to run another suite |

`alu_tb`, `register_file_tb` and `cpu_fpga_top_tb` are not in `sim_1`. Run them standalone, or add them to the project.

---

## Tools

| Tool | Version | Use |
| :--- | :--- | :--- |
| AMD Vivado | 2025.1 | XSim simulation, `xvlog` strict compile, synthesis |
| Icarus Verilog | 12.0 (devel) | Second simulator for all testbenches |

---

## Limitations and Caveats

- **No FPGA implementation yet.** No constraints, place and route, timing, bitstream or hardware test exist.
- **Synthesis area is program-specific.** See the caveat under [Synthesis Result](#synthesis-result).
- **Data memory is register-based.** Reset clears `memory[0:7]`, and a RAM with a content reset cannot be mapped to LUTRAM or block RAM. When a program uses the whole address space, the full memory needs up to 2,048 FFs. This is intentional, documented behavior; it was not optimized.
- **The wrapper is minimal.** `cpu_fpga_top` passes `clk` and `reset` straight to the CPU. It has no clock buffer or PLL, no reset synchronizer or debouncer, and no board I/O mapping yet.
- **Simulation-only X values.** Unwritten ROM and data-memory locations are `X` in simulation and `0` in hardware.
- **Timescale warnings.** RTL files have no `` `timescale ``, so XSim prints 18 `XSIM 43-4099` warnings per elaboration. They're cosmetic.
