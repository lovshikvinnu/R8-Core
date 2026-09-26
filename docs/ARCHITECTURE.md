# Architecture Specification

This document describes the CPU **as implemented in the RTL** (`rtl/*.v`), which is the source of truth. The instruction set is specified in [`ISA.md`](ISA.md) (v1.0, locked).

| Status | Scope |
| :--- | :--- |
| **Implemented and verified in simulation** | Everything in sections 1–6 |
| **Synthesized** (Vivado 2025.1, no timing constraints) | `cpu_fpga_top` on `xczu7ev-ffvc1156-2-e`; see section 7 |
| **Not yet done (future FPGA work)** | Constraints, board I/O, clocking/reset conditioning, implementation, timing, bitstream, hardware test; see section 8 |

---

## 1. Overview

| Parameter | Value |
| :--- | :--- |
| Organization | Single-cycle, Harvard (separate instruction and data memories) |
| Data path | 8 bits |
| Instruction | 16 bits, fixed length |
| Registers | 4 × 8-bit (`R0`–`R3`), 2 read ports, 1 write port |
| PC | 8 bits |
| Program memory | 256 × 16, combinational read |
| Data memory | 256 × 8, synchronous write, combinational read |
| Flags | `Z`, `C` (registered) |
| Clock / reset | One clock (`clk`), synchronous active-high `reset` |
| Timing model | Every instruction completes in one clock cycle |

**Execution model.** In each cycle the PC addresses program memory. The instruction is decoded combinationally, the register file and ALU compute combinationally, and on the next rising edge of `clk` all state is updated together: PC, the destination register, the flags and data memory. Nothing is pipelined, and there are no multi-cycle instructions.

```text
                           +--------------------------------------------+
                           |        load_value = instruction[7:0]        |
                           v                                             |
+-------+  pc_value  +------------------+ instruction +---------+ address |
|  pc   |----------->|  program_memory  |------------>| decoder |---------+----------------+
+-------+            +------------------+   [15:0]    +---------+                          |
  ^  ^ enable/load                                     | opcode  | ra, rb   | immediate    |
  |  |                                                 v         v          |              |
  |  |         zero_flag   +--------------+   +---------------+             |              |
  |  +---------------------| control_unit |   | register_file |             |              |
  |                  +---->+--------------+   +---------------+             |              |
  |                  |       | reg_write, alu_op, |A           |B           |              |
  |                  |       | mem_read/write     v            v            |              |
  |           +-------+      |                 +------------------+         |              |
  |           | flags |<-----+--- Z, C --------|       alu        |         |              |
  |           +-------+  update_zero/carry     +------------------+         |              |
  |                      (decoded in cpu.v)          | result               |              |
  |                                                  v                      v              v
  |                                          +--------------------------------+   +-------------+
  |                    writeback_data  <-----|  write-back mux (in cpu.v)     |<--| data_memory |
  |                    -> register_file      |  ALU | imm[7:0] | mem data     |   +-------------+
  |                                          +--------------------------------+   write_data = Ra
  +-- (PC update each clock)
```

---

## 2. Module Summary

| Module | File | Type | Function |
| :--- | :--- | :--- | :--- |
| `cpu` | `rtl/cpu.v` | Structural + combinational | Top-level datapath: flag-update decode, write-back mux, debug outputs |
| `pc` | `rtl/pc.v` | Sequential | Program counter with reset, load and increment |
| `program_memory` | `rtl/program_memory.v` | Combinational ROM | 256 × 16 instruction store, optional `INIT_FILE` |
| `decoder` | `rtl/decoder.v` | Combinational | Bit-field extraction |
| `control_unit` | `rtl/control_unit.v` | Combinational | Opcode (+ `zero_flag` for BZ) → control signals |
| `register_file` | `rtl/register_file.v` | Sequential write, combinational read | 4 × 8-bit registers |
| `alu` | `rtl/alu.v` | Combinational | 8 operations, zero and carry outputs |
| `flags` | `rtl/flags.v` | Sequential | Z / C flag register with independent update enables |
| `data_memory` | `rtl/data_memory.v` | Sequential write, combinational read | 256 × 8 data store |
| `cpu_fpga_top` | `rtl/cpu_fpga_top.v` | Structural | Synthesis/FPGA entry point; selects `program.mem` |

---

## 3. Module Details

### 3.1 Program Counter (`pc.v`)

| Port | Dir | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk`, `reset` | in | 1 | Clock, synchronous active-high reset |
| `enable` | in | 1 | Increment enable (`pc_enable`) |
| `load` | in | 1 | Load enable (`pc_jump`) |
| `load_value` | in | 8 | Jump target, `instruction[7:0]` |
| `pc` | out | 8 | Current PC (`pc_value` in `cpu.v`) |

Priority on each rising edge: `reset` sets `pc` to `0`; otherwise `load` sets `pc` to `load_value`; otherwise `enable` sets `pc` to `pc + 1` (wrapping from `0xFF` to `0x00`); otherwise `pc` holds.

### 3.2 Program Memory (`program_memory.v`)

- `reg [15:0] memory [0:255]`, read combinationally: `instruction = memory[address]`.
- Parameter `INIT_FILE` (default `""`):
  - **Empty (default):** there's no initialization. Testbenches preload `memory` hierarchically, which is how all CPU-level unit tests work.
  - **Non-empty:** `$readmemh(INIT_FILE, memory)` runs in an `initial` block. `cpu_fpga_top` uses this with `program.mem`.
- The CPU has no path to write it: it's a ROM from the CPU's point of view.

### 3.3 Decoder (`decoder.v`)

Pure bit slicing, no logic:

| Output | Bits | Used for |
| :--- | :---: | :--- |
| `opcode` | `[15:12]` | Control unit, flag-update decode, write-back select |
| `ra` | `[11:10]` | Register read port A and **write address** |
| `rb` | `[9:8]` | Register read port B |
| `immediate` | `[9:0]` | LOADI uses `immediate[7:0]`; bits `[9:8]` are ignored |
| `address` | `[7:0]` | Data-memory address (LOAD/STORE) and PC jump target (JMP/BZ) |

The fields overlap by design. For example, the `rb` bits are part of `immediate`. Each instruction uses only the fields its format defines.

### 3.4 Control Unit (`control_unit.v`)

Combinational. Defaults are `pc_enable = 1` and all other outputs `0`.

| Opcode | Instr. | `reg_write` | `alu_op` | `mem_read` | `mem_write` | `pc_enable` | `pc_jump` | `halt` |
| :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| `0000` | NOP | 0 | 000 | 0 | 0 | 1 | 0 | 0 |
| `0001` | ADD | 1 | 000 | 0 | 0 | 1 | 0 | 0 |
| `0010` | SUB | 1 | 001 | 0 | 0 | 1 | 0 | 0 |
| `0011` | AND | 1 | 010 | 0 | 0 | 1 | 0 | 0 |
| `0100` | OR | 1 | 011 | 0 | 0 | 1 | 0 | 0 |
| `0101` | XOR | 1 | 100 | 0 | 0 | 1 | 0 | 0 |
| `0110` | INC | 1 | 101 | 0 | 0 | 1 | 0 | 0 |
| `0111` | DEC | 1 | 110 | 0 | 0 | 1 | 0 | 0 |
| `1000` | LOADI | 1 | 000 | 0 | 0 | 1 | 0 | 0 |
| `1001` | LOAD | 1 | 000 | 1 | 0 | 1 | 0 | 0 |
| `1010` | STORE | 0 | 000 | 0 | 1 | 1 | 0 | 0 |
| `1011` | JMP | 0 | 000 | 0 | 0 | 0 | 1 | 0 |
| `1100` | BZ, Z = 1 | 0 | 000 | 0 | 0 | 0 | 1 | 0 |
| `1100` | BZ, Z = 0 | 0 | 000 | 0 | 0 | 1 | 0 | 0 |
| `1101` | HALT | 0 | 000 | 0 | 0 | 0 | 0 | 1 |
| `1110`, `1111` | RESERVED | 0 | 000 | 0 | 0 | 1 | 0 | 0 |

The control unit also produces `alu_enable` and `branch_enable` (the latter is 1 only for a taken BZ). **Neither signal is used by `cpu.v`**: the ALU computes every cycle, and write-back is controlled by `reg_write`. They're kept for observability in the control-unit unit test.

### 3.5 Register File (`register_file.v`)

- Four 8-bit registers.
- Synchronous write: when `write_enable` is high, `registers[write_addr] <= write_data`.
- Synchronous reset clears all four registers to `0`.
- Two combinational read ports: A from `ra`, B from `rb`.
- In `cpu.v` the write address is always `ra`, and `write_enable = reg_write`.

### 3.6 ALU (`alu.v`)

Combinational. `A` = register `Ra`, `B` = register `Rb`.

| `alu_op` | Operation | `RESULT` | `CARRY` |
| :---: | :--- | :--- | :--- |
| `000` | ADD | `A + B` | carry out of bit 7 |
| `001` | SUB | `A - B` | `1` if `A >= B` (no borrow) |
| `010` | AND | `A & B` | 0 |
| `011` | OR | `A \| B` | 0 |
| `100` | XOR | `A ^ B` | 0 |
| `101` | INC | `A + 1` | carry out of bit 7 |
| `110` | DEC | `A - 1` | `1` if `A >= 1` (no borrow) |
| `111` | PASS | `A` | 0 (not used by any ISA v1.0 instruction) |

`ZERO = (RESULT == 0)`. The ALU drives `CARRY = 0` for logic operations, but those instructions don't update `C` (section 3.7), so the stored carry flag keeps its value.

### 3.7 Flags (`flags.v`) and flag-update decode (`cpu.v`)

- Two flip-flops, `zero_flag` and `carry_flag`, both cleared by synchronous reset.
- On each rising edge, `zero_flag <= alu_zero` if `update_zero`, and `carry_flag <= alu_carry` if `update_carry`. Otherwise each flag holds.
- `update_zero` and `update_carry` are decoded from the opcode **in `cpu.v`**, not in `control_unit.v`:

| Instructions | `update_zero` | `update_carry` |
| :--- | :---: | :---: |
| ADD, SUB, INC, DEC | 1 | 1 |
| AND, OR, XOR | 1 | 0 |
| All others | 0 | 0 |

**Flag timing:** flags are registered. A BZ sees the Z value written by the **most recent earlier** flag-updating instruction; non-flag instructions in between (LOADI, LOAD, STORE, JMP, NOP) don't change it.

### 3.8 Data Memory (`data_memory.v`)

- `reg [7:0] memory [0:255]`.
- **Write:** synchronous. When `mem_write` is high, `memory[address] <= write_data`, where `write_data` is register `Ra`.
- **Read:** combinational and gated: `read_data = mem_read ? memory[address] : 8'h00`.
- **Reset:** synchronous. It clears **only `memory[0]`–`memory[7]`**; the other 248 bytes keep their contents. They start as `X` in simulation and `0` after FPGA configuration.
- `address` is `instruction[7:0]`.

### 3.9 Write-back multiplexer (`cpu.v`)

| Opcode | `writeback_select` | Data written to `Ra` (when `reg_write = 1`) |
| :--- | :---: | :--- |
| LOADI (`1000`) | `01` | `immediate[7:0]` |
| LOAD (`1001`) | `10` | `data_memory` read data |
| ALU ops (`0001`–`0111`) and all others | `00` | `alu_result` |

For instructions with `reg_write = 0` the mux output is still computed, but it isn't written.

---

## 4. Instruction Behavior in the Datapath

| Class | What happens on the clock edge |
| :--- | :--- |
| ALU (`ADD`–`DEC`) | `Ra <= alu_result`; flags update per section 3.7; `PC <= PC + 1` |
| `LOADI` | `Ra <= imm[7:0]`; `PC <= PC + 1` |
| `LOAD` | `Ra <= memory[addr]`, using data read combinationally in the same cycle; `PC <= PC + 1` |
| `STORE` | `memory[addr] <= Ra`; `PC <= PC + 1` |
| `JMP` | `PC <= instruction[7:0]` |
| `BZ` | If `zero_flag = 1`, `PC <= instruction[7:0]`; otherwise `PC <= PC + 1` |
| `NOP`, RESERVED | `PC <= PC + 1` only |
| `HALT` | Nothing changes (`pc_enable = 0`, `pc_jump = 0`) |

**HALT.** `halt` is decoded combinationally from the current instruction; it isn't a latched state bit. Because HALT holds the PC, the same HALT instruction is fetched again every cycle, so `halt` stays asserted and no register, flag or memory changes. Only `reset` leaves the halted state.

**Branch and jump targets** are absolute 8-bit addresses from `instruction[7:0]`, so the full 256-word program space is reachable. Sequential execution past `0xFF` wraps to `0x00`.

---

## 5. Clock and Reset

| Property | Implementation |
| :--- | :--- |
| Clock | Single clock `clk`; all state updates on its rising edge |
| Reset | Synchronous, active-high `reset` input |
| Reset state | `PC = 0x00`; `R0`–`R3 = 0`; `Z = C = 0`; `data_memory[0:7] = 0` |
| Not reset | `data_memory[8:255]`; program memory (a ROM) |

After `reset` is released, the instruction at `0x00` executes on the next rising edge.

---

## 6. Debug Outputs and FPGA Wrapper

### 6.1 `cpu` ports

| Port | Dir | Width | Source | Notes |
| :--- | :---: | :---: | :--- | :--- |
| `clk`, `reset` | in | 1 | – | |
| `dbg_pc` | out | 8 | `pc_value` | Current PC |
| `dbg_halt` | out | 1 | `halt` | |
| `dbg_zero_flag` | out | 1 | `zero_flag` | Stored flag |
| `dbg_carry_flag` | out | 1 | `carry_flag` | Stored flag |
| `dbg_wb_data` | out | 8 | `writeback_data` | Meaningful when the instruction writes a register |
| `dbg_wb_addr` | out | 2 | `writeback_addr` (`ra`) | Destination register |

Parameter `PROGRAM_INIT_FILE` (default `""`) is passed to `program_memory.INIT_FILE`. The debug outputs are plain `assign` copies of internal signals: they add no logic or state. They also keep the datapath observable for synthesis, so it isn't optimized away.

### 6.2 `cpu_fpga_top`

- Instantiates `cpu` with `PROGRAM_INIT_FILE("program.mem")`.
- Exposes `clk`, `reset` and the six debug outputs as top-level ports.
- Contains no CPU logic.
- It's the synthesis top (`sources_1`) of the Vivado project.

**Current limitation (future FPGA work):** the wrapper connects `clk` and `reset` directly to the CPU. It has no clock buffering or PLL/MMCM, no reset synchronizer or debouncer, and no mapping of debug signals to board LEDs or headers. These depend on the target board. The laboratory board is the **AUP-ZU3**, which hasn't been used for implementation or hardware testing yet.

---

## 7. Synthesis Mapping (observed, program-specific)

These are the observed results from the Vivado 2025.1 synthesis of `cpu_fpga_top` with the current `mem/program.mem` (the 28-word ISA coverage program). The ROM contents are known at synthesis time, so **Vivado specialized the hardware to this program**. These are not generic properties of the design.

| Structure | Observed implementation |
| :--- | :--- |
| Program memory | LUT ROM, **32 × 15** (Vivado ROM report). The program occupies 32 addresses or fewer; instruction bits 6 and 7 are identical in every word, so only 15 distinct columns are stored |
| Data memory | **1,024 FFs** plus LUT/MUXF7/MUXF8 multiplexing. No LUTRAM, block RAM or URAM. Only the 128 addresses the program can generate were kept (`0x00–0x3F`, `0xC0–0xFF`) |
| Register file | 32 FFs (all 4 registers) |
| PC / flags | 8 FFs / 2 FFs |
| ALU | Merged into surrounding logic (1 `CARRY8`) |
| `decoder`, `control_unit`, `program_memory` | No separate hierarchy after synthesis; the logic was merged into the other modules |

Totals are 519 CLB LUTs, 1,066 FFs, 0 BRAM and 0 DSP; see [`VERIFICATION.md`](VERIFICATION.md) §6. The data memory isn't mapped to RAM primitives because of its combinational read and its partial content reset (`memory[0:7]`). This behavior is intentional and was left unchanged.

---

## 8. Not Yet Implemented (Future FPGA Work)

| Item | Status |
| :--- | :--- |
| Target board | **AUP-ZU3** identified as the laboratory board; not yet used. `xczu7ev` was used for synthesis only |
| XDC constraints (clock period, pins, I/O standards) | Not created |
| Clock/reset conditioning in the wrapper | Not implemented |
| Implementation (place and route) | Not run |
| Static timing analysis / maximum frequency | Not available: no clock constraint yet |
| Bitstream generation | Not done |
| Hardware validation | Not done |
