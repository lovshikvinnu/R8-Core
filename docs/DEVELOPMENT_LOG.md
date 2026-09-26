# Development Log

Entries are newest first. Stages 1–8 (below) cover the project-hygiene, synthesis and re-verification work that followed Session 12. Their dates come from tool log and file timestamps. Sessions 1–12 are kept as originally written; where later evidence superseded a claim, a **Correction note** has been added rather than editing the original text.

---

## [2026-09-27] - Stage 8: Documentation Update

- Rewrote `README.md`, `docs/ARCHITECTURE.md` and `docs/VERIFICATION.md` from the current RTL and tool evidence; added clarifications to `docs/ISA.md` (opcode map and semantics unchanged).
- Recorded historical documentation discrepancies instead of silently changing them (see `VERIFICATION.md` §7).

## [2026-09-27] - Stage 7: Reconstructed CPU Memory / Branching / Loop Suites, 278/278 Regression

- The original passing sources of the Memory (9/9), Branching (11/11) and Loop (18/18) suites were unavailable, so three new testbenches were **written from scratch** against the current RTL:
  - `tb/cpu_memory_tb.v`: 20/20
  - `tb/cpu_branching_tb.v`: 19/19
  - `tb/cpu_loop_tb.v`: 29/29, with DEC encoded correctly as `7000`
- Mutation runs (one corrupted program word per test) produced 7, 10 and 18 failures respectively, confirming that the checks detect errors.
- Evidence note: the recovered historical loop snapshot, with only its DEC encoding changed from `6000` to `7000`, passed 18/18 (outside the repository).
- Added the three testbenches to the Vivado `sim_1` fileset; they compile and elaborate from the project file set.
- **Full regression: 278/278 checks passed in both Icarus Verilog and Vivado XSim** (18 testbenches). Strict `xvlog` (no `--relax`): 0 errors, 0 warnings.

## [2026-09-27] - Stage 6: Full-ISA Synthesis Coverage Program

- Replaced the 4-instruction demo image with a 28-word program in `mem/program.mem` that uses all 14 defined opcodes, all four registers, taken and not-taken BZ, JMP, and STORE/LOAD at three addresses.
- Encoded it from the ISA field definitions and verified it before installing: an independent ISA reference model ran in lockstep, with 0 mismatches over 36 instructions in both simulators.
- Updated `tb/cpu_fpga_top_tb.v` (ports only) to the new program: 41/41.
- Synthesis: **519 CLB LUTs, 1,066 FFs, 0 BRAM, 0 DSP**; 0 errors, 0 critical warnings, 1 warning (`Synth 8-7080`).
  - Program ROM became a 32 × 15 LUT ROM.
  - Data memory became FF storage, and only the 128 addresses reachable by the program were kept.
  - These results are specific to this program image.

## [2026-09-26] - Stage 5: First Real Synthesis

- Ran `synth_1` with top `cpu_fpga_top` on `xczu7ev-ffvc1156-2-e`. Vivado confirmed the program image was read (`Synth 8-3876`).
- With the 4-instruction demo program, the result was only **30 LUTs and 24 FFs**: Vivado removed data memory, R2/R3 and all logic the program couldn't reach. This showed that the synthesis result depends heavily on the ROM contents.
- No clock constraint was applied, so no timing result exists.

## [2026-09-26] - Stage 4: Synthesis-Ready Architecture (program-memory initialization and FPGA wrapper)

- `rtl/program_memory.v`: added parameter `INIT_FILE` (default `""`) with a conditional `$readmemh`, so testbench preloading is unchanged by default.
- `rtl/cpu.v`: added parameter `PROGRAM_INIT_FILE` and six debug outputs (`dbg_pc`, `dbg_halt`, `dbg_zero_flag`, `dbg_carry_flag`, `dbg_wb_data`, `dbg_wb_addr`). These are pure signal copies; CPU behavior is unchanged.
- Added `rtl/cpu_fpga_top.v` (synthesis/FPGA entry point), `mem/program.mem` and `tb/cpu_fpga_top_tb.v`.
- All existing suites still passed in both simulators. A negative control, with `program.mem` removed, confirmed that the file was actually loaded.

## [2026-09-26] - Stage 3: Vivado Project Hygiene

- The simulation fileset's top pointed to a module that no longer existed, and `alu.v`/`register_file.v` were listed a second time in `sim_1` although already inherited from `sources_1`.
- Fixed via the Vivado Tcl API: set the simulation top to `cpu_control_flow_boundary_tb`, added the recovered CPU testbenches, and removed the duplicate RTL entries from `sim_1`.
- Reset the stale `synth_1` run, whose last execution had used `alu_tb` as the top, and removed its stale incremental checkpoint.

## [2026-09-26] - Stage 2: Testbench Recovery

- The CPU-level tests had all been developed in a single file (`tb/pc_tb.v`, module `cpu_tb`) that was overwritten repeatedly, and `tb/cpu_tb.v` was empty.
- Recovered from local editor history, each into its own correctly named file:
  - PC unit test
  - Basic CPU
  - ISA regression
  - Arithmetic, INC/DEC, Memory and Control-flow boundary suites
- All of them reproduced their documented results.
- The Memory, Branching and passing Loop sources could not be recovered (see Stage 7).

## [2026-09-26] - Stage 1: Diagnosis and Declaration-Order Fix

- Diagnosed a jump in Vivado messages (6 errors, 164 warnings) as mostly session accumulation.
  - The 6 errors were `[Common 17-180] Spawn failed`, a GUI/environment issue, not a design error.
  - The earlier "synthesis" baseline of 24 infos and 26 warnings had come from RTL elaboration only.
- **RTL fix:** in `rtl/cpu.v`, the net `address` was used (PC `load_value` connection) before its declaration. This made it an implicit 1-bit net that was later redeclared as 8 bits (`VRFC 10-2938` / `Synth 8-8895`). Moving `wire [7:0] address;` ahead of its first use removed both warnings. Behavior is unchanged, and the control-flow boundary test still passed 10/10.

---

## [2026-09-26] - Session 12: Functional Verification and Boundary Testing Complete Milestone

> **Correction note (added later):** the Memory (9/9), Branching (11/11) and Loop (18/18) results below can't be reproduced, because their source files were lost. They were replaced by reconstructed suites in Stage 7.

### What was done
- Completed comprehensive simulation-based functional and boundary-condition verification for the custom 8-bit CPU.
- Verified end-to-end integrated CPU programs:
  - Basic CPU execution verified (10/10 PASS).
  - Data memory transfer execution verified (9/9 PASS).
  - Conditional branching (`BZ` / `JMP`) verified (11/11 PASS).
  - Iterative loop execution verified (18/18 PASS).
  - ISA v1.0 CPU regression suite completed (20/20 PASS).
- Executed four dedicated boundary-condition test suites:
  - Arithmetic boundary behavior verified (14/14 PASS: `255 + 1`, `0 - 1`, `255 + 0`, `0 - 0`, zero flag, carry/no-borrow, 8-bit wraparound).
  - INC/DEC wraparound behavior verified (15/15 PASS: `INC 255 -> 0`, `DEC 0 -> 255`, `DEC 1 -> 0`).
  - Data memory address boundaries `0x00` and `0xFF` verified (10/10 PASS: proven spatial independence).
  - Program/control-flow boundaries verified (10/10 PASS: `JMP 0x00`, `JMP 0xFF`, execution at `0xFF`, PC wraparound `0xFF -> 0x00`, `BZ 0xFF`).
- Documented instruction encoding mistakes discovered during earlier CPU test development (`0x1000` vs `0x2000` for `SUB`, `0xA420` vs `0x9420` for `LOAD`, `0x6000` vs `0x7000` for `DEC`) as testbench encoding errors rather than RTL failures.
- **Engineering Lesson**: Instruction encodings should be generated or checked systematically against the ISA specification to reduce testbench mistakes.

### Current Project Phase
- **CURRENT PHASE**: **Functional verification complete.** Directed simulation-based verification completed at module, system, regression, and boundary levels.

### Next Project Phase
- **NEXT PHASE**: RTL quality review, Vivado synthesis warning analysis, resource utilization analysis, timing analysis, and FPGA deployment preparation.

---

## [2026-09-26] - Session 11: Full Top-Level CPU Integration, Sequential Flags & System Verification Milestone

> **Correction note (added later):** the "SYNTHESIS VERIFIED" result below (0 errors, 0 critical warnings) came from Vivado RTL elaboration, not from a synthesis run. The first real synthesis is recorded in Stage 5.

### What was done
- Implemented sequential Flag Register module ([`rtl/flags.v`](../rtl/flags.v)) and verified with self-checking testbench ([`tb/flags_tb.v`](../tb/flags_tb.v), 6/6 PASS).
- Integrated all eight hardware modules (PC, Program Memory, Decoder, Control Unit, Register File, ALU, Flags, Data Memory) into top-level CPU datapath ([`rtl/cpu.v`](../rtl/cpu.v)).
- Upgraded Program Counter (`pc.v`) with jump loading interface (`load`, `load_value`) and wired control logic in `cpu.v`.
- Added flag update decoding logic (`update_zero`, `update_carry`) in `cpu.v` for arithmetic and logic instructions.
- Implemented and verified 5 comprehensive end-to-end CPU execution suites covering basic arithmetic, memory transfers, conditional branching, loop iterations, and full ISA v1.0 regression:
  1. Basic CPU Execution: 10/10 PASS
  2. CPU Memory Execution: 9/9 PASS
  3. Conditional Branch Execution: 11/11 PASS
  4. Loop Execution: 18/18 PASS
  5. ISA v1.0 CPU Regression Test: 20/20 PASS
- Completed Vivado 2025.1 elaboration and synthesis with **0 Errors** and **0 Critical Warnings** (**SYNTHESIS VERIFIED**).
- Discovered and corrected testbench opcode encoding errors during CPU verification (`0x1000` vs `0x2000` for SUB, `0xA420` vs `0x9420` for LOAD, `0x6000` vs `0x7000` for DEC), confirming RTL adherence to ISA v1.0.

### Simulation Results Summary
```text
========================================
       ISA v1.0 CPU TEST SUMMARY
========================================
PASSED = 20
FAILED = 0
========================================
ALL ISA v1.0 TESTS PASSED!
```

### Module Status
- **Top-Level CPU (`rtl/cpu.v`)**: **IMPLEMENTED + VERIFIED + SYNTHESIS VERIFIED**
- **Sequential Flags (`rtl/flags.v`)**: **IMPLEMENTED + VERIFIED**

### Next Steps
- Edge-case/boundary verification and testbench suite organization.
- Synthesis warning cleanup/review and resource utilization analysis.
- Timing constraint definition and FPGA deployment planning.

---

## [2026-09-26] - Session 10: Data Memory Implementation & Verification

### What was done
- Implemented 256 x 8-bit Data Memory module ([`rtl/data_memory.v`](../rtl/data_memory.v)) supporting synchronous writes on `posedge clk` (`mem_write`) and combinational reads (`mem_read`).
- Implemented synchronous reset logic explicitly clearing the first eight memory locations (`memory[0:7]`).
- Implemented self-checking testbench ([`tb/data_memory_tb.v`](../tb/data_memory_tb.v)) executing 10 scored test cases covering write/read access at addresses `0x00`, `0x01`, `0x55`, `0xFF`, write-protection when `mem_write = 0`, and read-disable output (`8'b0`) when `mem_read = 0`. Reset sequence was exercised in Test 1 prior to scored tests.
- Executed simulation with Icarus Verilog (`iverilog -g2012`) and Vivado 2025.1 behavioral simulator.

### Simulation Results Summary
```text
========================================
        DATA MEMORY TEST SUMMARY
========================================
PASSED = 10
FAILED = 0
========================================
ALL DATA MEMORY TESTS PASSED!
```

### Module Status
- **Data Memory (`rtl/data_memory.v`)**: **IMPLEMENTED + VERIFIED**

### Next Steps
- Integrate PC, Program Memory, Decoder, Control Unit, Register File, Data Memory, and ALU into top-level CPU datapath ([`rtl/cpu.v`](../rtl/cpu.v)).

---

## [2026-09-26] - Session 9: Program Memory Implementation & Verification

### What was done
- Implemented 256 x 16-bit combinational read-only Program Memory module ([`rtl/program_memory.v`](../rtl/program_memory.v)) for ISA v1.0 instructions.
- Implemented self-checking testbench ([`tb/program_memory_tb.v`](../tb/program_memory_tb.v)) executing 8 test cases verifying memory locations across the address space (`0x00` to `0xFF`), including the first address (`0x00`), intermediate locations (`0x01`, `0x02`, `0x05`, `0x10`, `0x55`, `0xAA`), and the final address (`0xFF`).
- Executed simulation with Icarus Verilog (`iverilog -g2012`) and Vivado 2025.1 behavioral simulator.

### Simulation Results Summary
```text
========================================
      PROGRAM MEMORY TEST SUMMARY
========================================
PASSED = 8
FAILED = 0
========================================
ALL PROGRAM MEMORY TESTS PASSED!
```

### Module Status
- **Program Memory (`rtl/program_memory.v`)**: **IMPLEMENTED + VERIFIED**

### Next Steps
- Implement Data Memory module (`rtl/data_memory.v`).
- Integrate Program Memory, Control Unit, Register File, PC, Decoder, and ALU into top-level CPU datapath ([`rtl/cpu.v`](../rtl/cpu.v)).

---

## [2026-09-26] - Session 8: Control Unit Implementation & Verification

### What was done
- Implemented combinational Control Unit module ([`rtl/control_unit.v`](../rtl/control_unit.v)) for ISA v1.0.
- Decodes 4-bit opcodes into control signals for register write (`reg_write`), ALU enable and opcode (`alu_enable`, `alu_op`), memory read/write (`mem_read`, `mem_write`), PC enable/jump (`pc_enable`, `pc_jump`), conditional branch (`branch_enable`), and CPU execution state (`halt`).
- Implemented conditional branch logic for `BZ` (`4'b1100`) using the `zero_flag` input (`zero_flag=1` → branch taken; `zero_flag=0` → normal PC progression).
- Implemented self-checking testbench ([`tb/control_unit_tb.v`](../tb/control_unit_tb.v)) covering 17 test cases for all opcodes, including `BZ` flags evaluation and reserved opcodes.
- Executed simulation with Icarus Verilog (`iverilog -g2012`) and Vivado 2025.1 behavioral simulator.

### Simulation Results Summary
```text
========================================
        CONTROL UNIT TEST SUMMARY
========================================
PASSED = 17
FAILED = 0
========================================
ALL CONTROL UNIT TESTS PASSED!
```

### Module Status
- **Control Unit (`rtl/control_unit.v`)**: **IMPLEMENTED + VERIFIED**

### Next Steps
- Implement Program / Data Memory module (`rtl/memory.v`, planned name; implemented instead as `rtl/program_memory.v` and `rtl/data_memory.v`).
- Integrate Control Unit and all sub-modules into top-level CPU datapath ([`rtl/cpu.v`](../rtl/cpu.v)).

---

## [2026-09-26] - Session 7: Instruction Decoder Implementation & Verification

### What was done
- Implemented combinational Instruction Decoder module ([`rtl/decoder.v`](../rtl/decoder.v)) for ISA v1.0 16-bit words.
- Implemented self-checking testbench ([`tb/decoder_tb.v`](../tb/decoder_tb.v)) covering 17 test cases for all 16 opcodes (NOP, ADD, SUB, AND, OR, XOR, INC, DEC, LOADI, LOAD, STORE, JMP, BZ, HALT, and 2 RESERVED opcodes).
- Executed simulation with Icarus Verilog (`iverilog -g2012`) and Vivado 2025.1 behavioral simulator.

### Simulation Results Summary
```text
========================================
         DECODER TEST SUMMARY
========================================
PASSED = 17
FAILED = 0
========================================
ALL DECODER TESTS PASSED!
```

### Module Status
- **Instruction Decoder (`rtl/decoder.v`)**: **IMPLEMENTED + VERIFIED**

### Next Steps
- Begin implementation of Control Unit FSM ([`rtl/control_unit.v`](../rtl/control_unit.v)).

---

## [2026-09-26] - Session 6: ISA v1.0 Specification Lock & Architecture Definition

### What was done
- Formally locked and documented **ISA v1.0** specification for the custom 8-bit CPU.
- Defined system architecture parameters, 3 instruction formats (R-Type, I-Type, J-Type), and 16-instruction opcode map.

---

## [2026-09-26] - Session 5: Program Counter Full Implementation & Verification

> **Correction note (added later):** the PC was later extended with `load`/`load_value` (Session 11). The current PC unit test, `tb/pc_tb.v` as recovered in Stage 2, has 7 checks and passes 7/7.

### What was done
- Implemented Program Counter module ([`rtl/pc.v`](../rtl/pc.v)) with synchronous reset, enable counting, and 8-bit wraparound.
- Verified testbench ([`tb/pc_tb.v`](../tb/pc_tb.v)) with 5/5 tests passing (`PASSED = 5, FAILED = 0`).

---

## [2026-09-26] - Session 4: Register File Full Implementation & Verification

### What was done
- Completed [`rtl/register_file.v`](../rtl/register_file.v) implementation (4 x 8-bit registers R0–R3, synchronous write/reset, dual asynchronous read ports).
- Verified testbench [`tb/register_file_tb.v`](../tb/register_file_tb.v) with 8/8 tests passing.

---

## [2026-09-26] - Session 3: Register File Write & Reset Logic Implementation

### What was done
- Added synchronous write and reset logic to [`rtl/register_file.v`](../rtl/register_file.v).

---

## [2026-09-26] - Session 2: ALU v1 Edge-Case Verification & ARM-Style Carry Implementation

### Development Sequence
1. **ALU Implementation**: Developed combinational 8-bit ALU (`rtl/alu.v`).
2. **Edge-Case Testing**: Added comprehensive edge cases to `tb/alu_tb.v`.
3. **ARM-Style C Convention Implemented**: Updated `rtl/alu.v` (`CARRY = 1` for no borrow `A >= B`).
4. **17/17 Tests Passed**: Re-simulated with `PASSED = 17, FAILED = 0`.
5. **ALU v1 VERIFIED**: Marked **ALU v1** as **IMPLEMENTED + VERIFIED**.

---

## [2026-09-26] - Session 1: Project Setup & Repository Initialization

### What was done
- Created standard CPU repository layout (`rtl/`, `tb/`, `sim/`, `docs/`, `docs/verification/`).
- Initialized core project documentation.
