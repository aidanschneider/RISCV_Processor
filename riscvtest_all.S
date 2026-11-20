    .option norvc
    .option norelax
    .section .text
    .globl _start
    .type _start, @function
_start:
    # x0 must remain hardwired to zero, even when an instruction names it as rd.
    addi x1, x0, 0
    addi x0, x1, 7
    bne  x0, x1, fail

    # R-type arithmetic and logical operations.
    addi x1, x0, 10
    addi x2, x0, 3

    add   x3, x1, x2          # 13
    addi  x4, x0, 13
    bne   x3, x4, fail

    sub   x3, x1, x2          # 7
    addi  x4, x0, 7
    bne   x3, x4, fail

    sll   x3, x2, x2          # 3 << 3 = 24
    addi  x4, x0, 24
    bne   x3, x4, fail

    slt   x3, x2, x1          # 3 < 10 (signed) = 1
    addi  x4, x0, 1
    bne   x3, x4, fail

    sltu  x3, x2, x1          # 3 < 10 (unsigned) = 1
    bne   x3, x4, fail

    xor   x3, x1, x2          # 10 ^ 3 = 9
    addi  x4, x0, 9
    bne   x3, x4, fail

    srl   x3, x1, x2          # 10 >> 3 = 1 (logical)
    addi  x4, x0, 1
    bne   x3, x4, fail

    or    x3, x1, x2          # 10 | 3 = 11
    addi  x4, x0, 11
    bne   x3, x4, fail

    and   x3, x1, x2          # 10 & 3 = 2
    addi  x4, x0, 2
    bne   x3, x4, fail

    addi  x1, x0, -16
    addi  x2, x0, 2
    sra   x3, x1, x2          # -16 arithmetic-shift-right 2 = -4
    addi  x4, x0, -4
    bne   x3, x4, fail

    # Distinguish signed SLT from unsigned SLTU using the same operands.
    addi  x1, x0, -1
    addi  x2, x0, 1
    slt   x3, x1, x2          # signed: -1 < 1 = 1
    addi  x4, x0, 1
    bne   x3, x4, fail
    sltu  x3, x1, x2         # unsigned: 0xffffffff < 1 = 0
    bne   x3, x0, fail
    sltu  x3, x2, x1         # unsigned: 1 < 0xffffffff = 1
    bne   x3, x4, fail

    # I-type ALU operations and sign-extended immediates.
    addi  x3, x0, -2048
    addi  x4, x0, -2048
    bne   x3, x4, fail

    addi  x1, x0, -1
    slti  x3, x1, 0           # -1 < 0 (signed) = 1
    addi  x4, x0, 1
    bne   x3, x4, fail

    sltiu x3, x0, -1          # 0 < 0xffffffff (unsigned) = 1
    bne   x3, x4, fail

    xori  x3, x1, 0x055       # 0xffffffff ^ 0x55 = 0xffffffaa
    addi  x4, x0, -86
    bne   x3, x4, fail

    ori   x3, x0, 0x155       # 0x155
    addi  x4, x0, 0x155
    bne   x3, x4, fail

    andi  x3, x1, 0x7ff       # 0x7ff
    addi  x4, x0, 2047
    bne   x3, x4, fail

    addi  x1, x0, 1
    slli  x3, x1, 31         # 0x80000000
    blt   x3, x0, slli_ok
    jal   x0, fail
slli_ok:

    addi  x1, x0, -1
    srli  x3, x1, 31         # 1 (zero-fill)
    addi  x4, x0, 1
    bne   x3, x4, fail

    addi  x1, x0, -16
    srai  x3, x1, 2          # -4 (sign-fill)
    addi  x4, x0, -4
    bne   x3, x4, fail

    # LUI: build the expected constant independently, then compare.
    addi  x1, x0, 0x123
    slli  x1, x1, 20
    addi  x2, x0, 0x45
    slli  x2, x2, 12
    add   x3, x1, x2         # 0x12345000
    lui   x4, 0x12345
    bne   x3, x4, fail

    # AUIPC: the two instructions are 4 bytes apart.
auipc_test:
    auipc x5, 1              # PC + 0x1000
    auipc x6, 0              # next PC = PC + 4
    addi  x6, x6, 2047
    addi  x6, x6, 2045       # net +4092, so x6 == x5
    bne   x5, x6, fail

    # All six conditional branches: exercise taken and not-taken cases.
    addi  x1, x0, -1
    addi  x2, x0, 1

    beq   x1, x2, fail       # not taken
    beq   x1, x1, beq_ok     # taken
    jal   x0, fail
beq_ok:
    bne   x1, x1, fail       # not taken
    bne   x1, x2, bne_ok     # taken
    jal   x0, fail
bne_ok:
    blt   x1, x2, blt_ok     # signed: -1 < 1, taken
    jal   x0, fail
blt_ok:
    blt   x2, x1, fail       # signed: 1 < -1, not taken
    bge   x1, x2, fail       # signed: -1 >= 1, not taken
    bge   x2, x1, bge_ok     # signed: 1 >= -1, taken
    jal   x0, fail
bge_ok:
    bltu  x1, x2, fail      # unsigned: 0xffffffff < 1, not taken
    bltu  x2, x1, bltu_ok   # unsigned: 1 < 0xffffffff, taken
    jal   x0, fail
bltu_ok:
    bgeu  x1, x2, bgeu_ok   # unsigned: 0xffffffff >= 1, taken
    jal   x0, fail
bgeu_ok:
    bgeu  x2, x1, fail      # unsigned: 1 >= 0xffffffff, not taken

    # Exercise a backward B-type offset (negative branch displacement).
    addi  x3, x0, 2
branch_back:
    addi  x3, x3, -1
    bne   x3, x0, branch_back

    # JAL: target is 8 bytes ahead; link must be PC+4.
jal_test:
    jal   x5, jal_target
    jal   x0, fail           # must be skipped
jal_target:
    auipc x6, 0              # target PC
    addi  x6, x6, -4         # address of instruction after JAL
    bne   x5, x6, fail

    # JALR: odd target address must have bit 0 cleared.
jalr_test:
    auipc x10, 0             # address S
    addi  x10, x10, 17       # intended target S+16, with bit 0 set
    jalr  x5, 0(x10)         # link is S+12
    jal   x0, fail           # skipped; at S+12
jalr_target:
    auipc x6, 0              # target is S+16
    addi  x6, x6, -4         # link address S+12
    bne   x5, x6, fail

    # Memory instructions. Data region starts at byte address 128.
    addi  x20, x0, 128
    addi  x1, x0, -1
    sw    x1, 0(x20)
    fence rw, rw

    lb    x2, 0(x20)         # -1, sign-extended
    bne   x2, x1, fail
    lbu   x2, 0(x20)         # 255, zero-extended
    addi  x3, x0, 255
    bne   x2, x3, fail
    lh    x2, 0(x20)         # -1, sign-extended
    bne   x2, x1, fail
    lhu   x2, 0(x20)         # 65535, zero-extended
    lui   x3, 0x10
    addi  x3, x3, -1
    bne   x2, x3, fail
    lw    x2, 0(x20)
    bne   x2, x1, fail

    # SW followed by SB: preserve the other three bytes.
    lui   x1, 0x11223
    addi  x1, x1, 0x344      # 0x11223344
    sw    x1, 4(x20)
    addi  x2, x0, 0x0aa
    sb    x2, 5(x20)         # word at 4 becomes 0x1122aa44
    lw    x3, 4(x20)
    lui   x4, 0x1122b
    addi  x4, x4, -1468      # 0x1122aa44
    bne   x3, x4, fail

    lb    x3, 5(x20)         # 0xffffffaa = -86
    addi  x4, x0, -86
    bne   x3, x4, fail
    lbu   x3, 5(x20)         # 170
    addi  x4, x0, 170
    bne   x3, x4, fail

    # SH at byte offset 6: word at 4 becomes 0x5566aa44.
    lui   x5, 0x5
    addi  x5, x5, 0x566      # 0x00005566
    sh    x5, 6(x20)
    lw    x3, 4(x20)
    lui   x4, 0x5566b
    addi  x4, x4, -1468      # 0x5566aa44
    bne   x3, x4, fail
    lh    x3, 6(x20)
    bne   x3, x5, fail
    lhu   x3, 6(x20)
    bne   x3, x5, fail

    # FENCE is intentionally just exercised; a single-hart test cannot
    # meaningfully demonstrate cross-hart/device ordering.
    fence iorw, iorw

    # PASS signature: the testbench watches for a word write of 25 to 100.
    addi  x11, x0, 25
    sw    x11, 100(x0)
pass_loop:
    jal   x0, pass_loop

fail:
    addi  x11, x0, 1
    sw    x11, 104(x0)      # testbench treats this as failure
fail_loop:
    jal   x0, fail_loop
