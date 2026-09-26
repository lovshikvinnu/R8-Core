# Custom 8-Bit CPU ISA v1.0 Specification

- **Status**: **LOCKED / FROZEN**
- **Architecture**: Custom 8-bit RISC-like Harvard Architecture
- **Instruction Width**: 16-bit Fixed-Length Instruction Words
- **Data Bus Width**: 8-bit
- **Register File**: 4 General-Purpose 8-bit Registers (`R0`, `R1`, `R2`, `R3`)
- **Program Counter**: 8-bit Address Register (Addressing 256 instruction locations)
- **Program Memory**: 256 × 16-bit Memory Space (`0x00` to `0xFF`)
- **Data Memory**: 256 × 8-bit Memory Space (`0x00` to `0xFF`)
- **Hardware Flags**: `Z` (Zero Flag) and `C` (Carry / Active-Low Borrow Flag)

---

## 1. Instruction Formats

ISA v1.0 defines three distinct 16-bit instruction formats:

### 1.1 R-Type (Register Operations)
Used for arithmetic and bitwise logic operations between general-purpose registers.

```text
 15        12 11    10 9      8 7                      0
+------------+--------+--------+------------------------+
|   Opcode   |   Ra   |   Rb   |        Reserved        |
|   (4 bits) | (2 bits| (2 bits|        (8 bits)        |
+------------+--------+--------+------------------------+
```
- **`Opcode [15:12]`**: 4-bit instruction identifier.
- **`Ra [11:10]`**: 2-bit destination/first operand register address (`2'b00` = R0, `2'b01` = R1, `2'b10` = R2, `2'b11` = R3).
- **`Rb [9:8]`**: 2-bit source/second operand register address.
- **`Reserved [7:0]`**: Reserved bits (ignored by execution logic).

### 1.2 I-Type (Immediate & Memory Operations)
Used for loading immediate values, memory transfers, and immediate operations.

```text
 15        12 11    10 9                               0
+------------+--------+---------------------------------+
|   Opcode   |   Ra   |       Immediate / Address       |
|   (4 bits) | (2 bits|            (10 bits)            |
+------------+--------+---------------------------------+
```
- **`Opcode [15:12]`**: 4-bit instruction identifier.
- **`Ra [11:10]`**: 2-bit target register address.
- **`Immediate / Address [9:0]`**: 10-bit immediate value payload or 8-bit data memory address (`address[7:0]`).

### 1.3 J-Type (Jump & Control Flow Operations)
Used for unconditional and conditional control flow branches.

```text
 15        12 11     8 7                               0
+------------+--------+---------------------------------+
|   Opcode   |Reserved|             Address             |
|   (4 bits) |(4 bits)|            (8 bits)             |
+------------+--------+---------------------------------+
```
- **`Opcode [15:12]`**: 4-bit instruction identifier.
- **`Reserved [11:8]`**: Reserved bits (ignored by control logic).
- **`Address [7:0]`**: 8-bit target program memory address (`0x00` to `0xFF`).

---

## 2. Opcode Map & Instruction Semantics

| Opcode (`[15:12]`) | Mnemonic | Format | Assembly Syntax | Execution Semantics | Zero Flag (`Z`) | Carry Flag (`C`) |
| :---: | :--- | :---: | :--- | :--- | :---: | :---: |
| `0000` | **NOP** | - | `NOP` | No Operation | Unchanged | Unchanged |
| `0001` | **ADD** | R-Type | `ADD Ra, Rb` | `Ra = Ra + Rb` | Updated | Updated |
| `0010` | **SUB** | R-Type | `SUB Ra, Rb` | `Ra = Ra - Rb` | Updated | Updated |
| `0011` | **AND** | R-Type | `AND Ra, Rb` | `Ra = Ra & Rb` | Updated | Unchanged |
| `0100` | **OR** | R-Type | `OR Ra, Rb` | `Ra = Ra \| Rb` | Updated | Unchanged |
| `0101` | **XOR** | R-Type | `XOR Ra, Rb` | `Ra = Ra ^ Rb` | Updated | Unchanged |
| `0110` | **INC** | R-Type | `INC Ra` | `Ra = Ra + 1` | Updated | Updated |
| `0111` | **DEC** | R-Type | `DEC Ra` | `Ra = Ra - 1` | Updated | Updated |
| `1000` | **LOADI** | I-Type | `LOADI Ra, imm` | `Ra = immediate[7:0]` | Unchanged | Unchanged |
| `1001` | **LOAD** | I-Type | `LOAD Ra, address` | `Ra = DataMemory[address]` | Unchanged | Unchanged |
| `1010` | **STORE** | I-Type | `STORE Ra, address`| `DataMemory[address] = Ra` | Unchanged | Unchanged |
| `1011` | **JMP** | J-Type | `JMP address` | `PC = address` | Unchanged | Unchanged |
| `1100` | **BZ** | J-Type | `BZ address` | `if (Z == 1) PC = address` | Unchanged | Unchanged |
| `1101` | **HALT** | - | `HALT` | Stop execution (Holds PC) | Unchanged | Unchanged |
| `1110` | **RESERVED** | - | - | Reserved for expansion | Unchanged | Unchanged |
| `1111` | **RESERVED** | - | - | Reserved for expansion | Unchanged | Unchanged |

---

## 3. Flag Rules & Conventions

1. **Flag Register Update Controls**:
   - `ADD`, `SUB`, `INC`, `DEC` assert both `update_zero` and `update_carry`.
   - `AND`, `OR`, `XOR` assert `update_zero` only (`update_carry = 0`).
   - `LOADI`, `LOAD`, `STORE`, `JMP`, `BZ`, `NOP`, `HALT`, and `RESERVED` do **not** update any flags (`update_zero = 0`, `update_carry = 0`).

2. **Carry / Borrow Flag Convention (ARM-Style)**:
   - For `ADD` & `INC`: `C = 1` indicates an 8-bit unsigned arithmetic overflow/carry-out.
   - For `SUB` & `DEC`: `C = 1` indicates **no borrow** (`A >= B`), while `C = 0` indicates a **borrow** (`A < B`).

3. **Unused Fields Handling**:
   - `INC` and `DEC` ignore the `Rb` field (`instruction[9:8]`).
   - `NOP` and `HALT` ignore all operand fields.
   - `BZ` evaluates the stored `zero_flag` output from the dedicated `flags.v` module.

---

## 4. Clarifications (no change to ISA v1.0)

This section adds detail that the specification above doesn't state explicitly. Every item matches the implemented RTL (`rtl/*.v`) and the verified testbenches. **The opcode map, instruction formats and semantics above are unchanged.**

1. **Execution timing:** every instruction completes in one clock cycle. PC, register, flag and data-memory updates take effect on the same rising clock edge.
2. **Field usage by instruction:**
   - `LOADI` writes `instruction[7:0]` into `Ra`. Bits `[9:8]` of the 10-bit immediate field are ignored.
   - `LOAD` and `STORE` use `instruction[7:0]` as the data-memory address. Bits `[9:8]` are ignored.
   - `STORE` writes the value of register `Ra`.
   - `JMP` and `BZ` use `instruction[7:0]` as an absolute target address. Bits `[11:8]` are ignored.
3. **RESERVED opcodes (`1110`, `1111`)** execute as NOP: the PC increments, and no register, flag or memory changes.
4. **HALT:** the PC holds, so the HALT instruction is fetched again every cycle and execution stays stopped until reset. No register, flag or memory changes while halted.
5. **BZ flag source:** `Z` is the stored flag written by the most recent flag-updating instruction (ADD, SUB, AND, OR, XOR, INC, DEC). Intervening LOADI, LOAD, STORE, JMP or NOP instructions don't change it.
6. **Reset state** (synchronous, active-high):
   - `PC = 0x00`
   - `R0`–`R3 = 0`
   - `Z = 0`, `C = 0`
   - data memory `0x00`–`0x07` cleared to 0; other data-memory locations aren't affected by reset
7. **PC wrap:** sequential execution from `0xFF` continues at `0x00`.

### 4.1 Encoding examples (verified in simulation)

| Instruction | Fields | Hex |
| :--- | :--- | :---: |
| `ADD R0, R1` | `0001 00 01 00000000` | `1100` |
| `SUB R0, R0` | `0010 00 00 00000000` | `2000` |
| `INC R0` | `0110 00 00 00000000` | `6000` |
| `DEC R0` | `0111 00 00 00000000` | `7000` |
| `LOADI R1, 20` | `1000 01 0000010100` | `8414` |
| `LOAD R1, 0x20` | `1001 01 00 00100000` | `9420` |
| `STORE R0, 0x20` | `1010 00 00 00100000` | `A020` |
| `JMP 0x12` | `1011 0000 00010010` | `B012` |
| `BZ 0x16` | `1100 0000 00010110` | `C016` |
| `HALT` | `1101 0000 00000000` | `D000` |

`1000` is **ADD R0, R0**, not ADD R0, R1. `6000` is **INC R0**, not DEC R0. Both were encoding mistakes in earlier test material (see [`VERIFICATION.md`](VERIFICATION.md) §7).
