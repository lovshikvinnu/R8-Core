# Verification Report

## 1. Summary

| Item | Result |
| :--- | :--- |
| Testbenches | 18, all self-checking (PASS/FAIL per check, summary counts) |
| Full regression | **278 / 278 checks passed, 0 failed**, identical in **Icarus Verilog** and **Vivado XSim** |
| Strict compile | `xvlog` **without `--relax`** over all 10 RTL files and 18 testbenches: **0 errors, 0 warnings** |
| Vivado project simulation (`sim_1`) | Project-generated flow: `cpu_control_flow_boundary_tb` 10/10. `cpu_memory_tb`, `cpu_branching_tb` and `cpu_loop_tb` compiled and elaborated from the project file set: 20/20, 19/19, 29/29 |
| Synthesis | Completed, 0 errors, 0 critical warnings (section 6) |
| FPGA hardware | **Not tested**: no implementation or bitstream yet |

All results in this report are from simulation or synthesis. None come from FPGA hardware.

---

## 2. Methodology

- **Unit level:** each RTL module is tested in isolation with directed, self-checking stimulus.
- **CPU level:** complete programs run on `cpu`. Program memory is preloaded by hierarchical assignment to `uut.instruction_memory.memory[...]` at time 0, with `PROGRAM_INIT_FILE` left at its empty default. Checks use the `dbg_*` ports and read-only hierarchical views of registers and data memory. No DUT state is forced.
- **Wrapper level:** `cpu_fpga_top` loads `mem/program.mem` through `$readmemh` with **no** hierarchical preload, and is checked **only through its ports**.
- **Two simulators:** every testbench runs in both Icarus Verilog and Vivado XSim.
- **Encodings:** CPU-level programs added in the later verification stages were encoded from the [`ISA.md`](ISA.md) field definitions with a small field-packing script, rather than typed as hex by hand.

---

## 3. Results by Testbench

### 3.1 Module-level (unit) tests

| Module | Testbench | Checks | Result |
| :--- | :--- | :---: | :---: |
| ALU | `tb/alu_tb.v` | 17 | 17 / 17 |
| Register file | `tb/register_file_tb.v` | 8 | 8 / 8 |
| Program counter | `tb/pc_tb.v` | 7 | 7 / 7 |
| Decoder | `tb/decoder_tb.v` | 17 | 17 / 17 |
| Control unit | `tb/control_unit_tb.v` | 17 | 17 / 17 |
| Program memory | `tb/program_memory_tb.v` | 8 | 8 / 8 |
| Data memory | `tb/data_memory_tb.v` | 10 | 10 / 10 |
| Flags | `tb/flags_tb.v` | 6 | 6 / 6 |
| **Subtotal** | | **90** | **90 / 90** |

### 3.2 CPU-level program tests

| Suite | Testbench | Checks | Result | Origin |
| :--- | :--- | :---: | :---: | :--- |
| Basic execution | `tb/cpu_basic_tb.v` | 10 | 10 / 10 | Recovered from editor history |
| Memory (LOAD/STORE) | `tb/cpu_memory_tb.v` | 20 | 20 / 20 | **Reconstructed** (section 4) |
| Branching (BZ) | `tb/cpu_branching_tb.v` | 19 | 19 / 19 | **Reconstructed** (section 4) |
| Loop | `tb/cpu_loop_tb.v` | 29 | 29 / 29 | **Reconstructed** (section 4) |
| ISA v1.0 regression | `tb/cpu_isa_regression_tb.v` | 20 | 20 / 20 | Recovered from editor history |
| **Subtotal** | | **98** | **98 / 98** | |

### 3.3 CPU-level boundary tests

| Suite | Testbench | Checks | Result | Covers |
| :--- | :--- | :---: | :---: | :--- |
| Arithmetic | `tb/cpu_arithmetic_boundary_tb.v` | 14 | 14 / 14 | `255+1` (Z=1, C=1), `0-1` (C=0), `255+0`, `0-0` (Z=1, C=1) |
| INC/DEC | `tb/cpu_inc_dec_boundary_tb.v` | 15 | 15 / 15 | `INC 255 → 0`, `DEC 0 → 255`, `DEC 1 → 0` with flags |
| Data memory | `tb/cpu_memory_boundary_tb.v` | 10 | 10 / 10 | STORE/LOAD at `0x00` and `0xFF`, no aliasing |
| Control flow | `tb/cpu_control_flow_boundary_tb.v` | 10 | 10 / 10 | `JMP 0x00/0xFF`, execution at `0xFF`, PC wrap `0xFF → 0x00`, `BZ 0xFF` |
| **Subtotal** | | **49** | **49 / 49** | |

The two "recovered" program suites (3.2), all four boundary suites and the PC unit test (`pc_tb.v`) were restored byte-for-byte from local editor history. Only the `module` names of the CPU suites were changed to match their file names. All were re-verified against the current RTL.

### 3.4 FPGA wrapper test

| Testbench | Checks | Result | Description |
| :--- | :---: | :---: | :--- |
| `tb/cpu_fpga_top_tb.v` | 41 | 41 / 41 | Runs the 28-word coverage program from `mem/program.mem`. It checks reset, a 36-step trace of PC, write-back register/data, Z and C, then HALT at `0x1B` and that the halt persists. Ports only |

When the wrapper flow was introduced (with an earlier 4-instruction `program.mem`), a negative control was run: with `program.mem` removed from the working directory, both simulators reported the file could not be opened and the test failed (7 pass, 6 fail). This negative control has not been repeated with the current 28-word image. The current test does depend on the file's contents: against the earlier image's testbench, the new image failed 6 of 13 checks.

### 3.5 Full regression

| Group | Checks | Icarus | XSim |
| :--- | :---: | :---: | :---: |
| Unit | 90 | 90 / 90 | 90 / 90 |
| CPU programs | 98 | 98 / 98 | 98 / 98 |
| CPU boundary | 49 | 49 / 49 | 49 / 49 |
| Wrapper | 41 | 41 / 41 | 41 / 41 |
| **Total** | **278** | **278 / 278** | **278 / 278** |

Tool messages during the regression:
- **XSim:** 18 × `XSIM 43-4099` per elaboration ("module doesn't have a timescale"). They're cosmetic: the RTL files have no `` `timescale ``.
- **Icarus:** `$readmemh(program.mem): Not enough words in the file for the requested range [0:255]` in `cpu_fpga_top_tb`. Expected: the file has 28 words, and the remaining ROM entries are `X` in simulation.
- No other warnings or errors.

---

## 4. Reconstructed Memory, Branching and Loop Suites

### 4.1 Why they were reconstructed

The original passing source files for the CPU Memory (documented 9/9), Branching (11/11) and Loop (18/18) tests **were not available**. They had been overwritten during development, and the saved editor history held no passing version. The three current testbenches were therefore **written fresh against the current RTL and ISA v1.0**.

**They are not the historical testbenches, and their check counts differ from the historical results.**

The historical evidence that did exist was used only to guide the design:

| Suite | Historical evidence | How it was used |
| :--- | :--- | :--- |
| Memory | Program in the earlier version of this document (`802A A020 8400 9420 D000`); 9 check names from a *failing* (7/9) Vivado run log | That program's STORE/LOAD behavior is included; the new test extends it |
| Branching | Earlier documented program (`8005 2000 C005 8463 B006 842A D000`, taken BZ only); 11 check names from a *failing* (6/11) run log | Taken-branch/skip behavior is included; a not-taken case was added |
| Loop | Earlier documented program (`8005 7000 C005 B001 0000 D000`); an editor-history snapshot with 18 checks that encoded DEC as `6000` (actually INC R0) and failed 8/18 | The new test uses `7000` for DEC. With only `6000 → 7000` changed, the snapshot passed 18/18 on the current RTL (outside the repository). This suggests, but doesn't prove, that the documented 18/18 came from that test with the encoding fixed |

### 4.2 What the reconstructed suites check

| Testbench | Program (hex) | Checks |
| :--- | :--- | :--- |
| `cpu_memory_tb` (20) | `2000 802A A020 8400 9420 88A5 A821 8000 9C21 9020 D000` | Reset; Z = C = 1 baseline; STORE to `0x20` and `0x21`; STORE leaves registers unchanged; LOAD write-back data seen on `dbg_wb_*`; no aliasing between adjacent addresses; memory persists after the source register is overwritten; LOAD into R1, R3 and R0; LOAD/STORE/LOADI leave flags unchanged; HALT; PC held; final registers and memory; PC sequence |
| `cpu_branching_tb` (19) | `8005 8401 2F00 2100 C008 8811 2000 C00B 8C63 B00D 8C77 842A C00E 88EE D000` | Z set by a zero result and cleared by a non-zero result; **BZ not taken** with fall-through executing; **BZ taken** redirecting PC; Z kept through LOADI; second taken BZ; skipped instructions leave no effect and addresses `0x08`, `0x09`, `0x0A`, `0x0D` are never executed (PC monitor); HALT; PC path |
| `cpu_loop_tb` (29) | `8005 8400 6400 7000 C006 B002 D000` | For each of 5 iterations: INC/DEC values, Z only at 0, C = 1, BZ not taken, JMP back. Then BZ exit, final R0 = 0 / R1 = 5 / Z = C = 1, body executed exactly 5 times, exactly 21 instructions before HALT, PC held, PC sequence |

### 4.3 Mutation evidence

To confirm that the new checks detect real errors, each testbench was copied (outside the repository) with **one** program word deliberately corrupted, then run in Icarus:

| Mutation | Result |
| :--- | :--- |
| Loop: DEC R0 `7000` → `6000` (the historical INC-for-DEC mistake) | 11 pass, **18 fail** |
| Branching: `SUB R0,R1` (`2100`) → `SUB R0,R0` (`2000`), so the not-taken BZ is wrongly taken | 9 pass, **10 fail** |
| Memory: second STORE `A821` → `A820`, aliasing onto `0x20` | 13 pass, **7 fail** |

The repository testbenches themselves are unmodified; all three pass as listed in section 3.2.

---

## 5. Coverage Program (`mem/program.mem`)

A 28-word program used both for synthesis (section 6) and by `cpu_fpga_top_tb`.
- It uses **all 14 defined opcodes**.
- It uses each of R0–R3 as both Ra and Rb.
- BZ is taken twice and not taken three times, and JMP is taken three times.
- It STOREs to and LOADs from `0x10`, `0x20` and `0xFF`.
- It reaches HALT at `0x1B` after 36 instructions.

Before being installed, it was checked against an **independent ISA v1.0 reference model** written from `ISA.md`, running in lockstep with the DUT. The model compares PC, R0–R3, Z, C and the used memory bytes every cycle: 16/16 checks passed and there were 0 mismatches, in both simulators. That model testbench was a temporary verification aid and is not in the repository.

Final state: R0 = `FF`, R1 = `00`, R2 = `FC`, R3 = `00`, Z = 1, C = 1; data memory `[0x10] = FC`, `[0x20] = FF`, `[0xFF] = 04`.

---

## 6. Synthesis Evidence

Vivado 2025.1, run `synth_1`, `synth_design -top cpu_fpga_top -part xczu7ev-ffvc1156-2-e`, default strategy, standard (non-incremental) flow.

| Item | Result |
| :--- | :--- |
| Status | `synth_design completed successfully` |
| Messages | 0 errors, 0 critical warnings, **1 warning**, 36 infos |
| Warning | `[Synth 8-7080] Parallel synthesis criteria is not met`, a flow message, not a functional issue |
| Program image | `[Synth 8-3876] $readmem data file 'program.mem' is read successfully` |

| Resource | Used | Available |
| :--- | ---: | ---: |
| CLB LUTs | 519 | 230,400 |
| FF | 1,066 | 460,800 |
| LUTRAM | 0 | 101,760 |
| BRAM / URAM | 0 / 0 | 312 / 96 |
| DSP | 0 | 1,728 |
| CARRY8 / F7 / F8 | 1 / 129 / 57 | – |
| Bonded IOB | 23 | 360 |
| BUFGCE | 1 | 208 |

**Program-specific result.** The ROM is initialized at synthesis time, so Vivado optimizes the hardware for this program:
- Program memory became a 32 × 15 LUT ROM.
- Data memory became FF storage with multiplexers.
- Only the 128 data addresses the program can generate were kept.

These figures are the resource usage of the current design and program image, **not a generic-CPU area number**. An earlier synthesis with a 4-instruction demo program kept only 30 LUTs and 24 FFs, which shows how strongly the result depends on the program. Details: [`ARCHITECTURE.md`](ARCHITECTURE.md) §7.

**Timing is currently unconstrained** because no XDC clock constraint has been added. No timing, frequency or timing-closure result exists.

---

## 7. Documentation Discrepancies (Historical)

Earlier versions of this document contained errors. They are recorded here, not silently rewritten:

| Earlier statement | Issue | Correct / current |
| :--- | :--- | :--- |
| Basic execution program listed `ADD R0, R1 ; 16'h1000` | By ISA v1.0 (`0001 Ra Rb 00000000`), `16'h1000` encodes **ADD R0, R0** | `ADD R0, R1` = **`16'h1100`**, which is what the verified `cpu_basic_tb` uses |
| "SYNTHESIS VERIFIED: 0 errors, 26 warnings, 24 infos" | That figure came from Vivado **RTL elaboration** (Open Elaborated Design), not from a synthesis run. The only synthesis run at that time had used a testbench (`alu_tb`) as its top | Real synthesis results are in section 6 |
| All CPU suites listed as `tb/pc_tb.v` (`cpu_tb`) | That single file was overwritten repeatedly with successive CPU tests | Each suite now has its own file (section 3) |
| Memory 9/9, Branching 11/11, Loop 18/18 | Source files unavailable; not reproducible | Reconstructed suites: 20/20, 19/19, 29/29 (section 4) |

Testbench encoding mistakes found earlier in development (`1000` vs `2000` for SUB, `A420` vs `9420` for LOAD, `6000` vs `7000` for DEC) were testbench errors, not RTL defects.

---

## 8. Not Yet Verified

- Post-synthesis or post-implementation (gate-level) simulation
- Timing (no constraints yet)
- Operation on FPGA hardware
