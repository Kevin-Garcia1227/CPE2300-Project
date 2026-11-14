.equ FB,       0x20000000
.equ PRESENT,  0x21001008
.equ WIDTH,  128
.equ HEIGHT, 96

.equ WHITE,      1
.equ BLACK,    0
.equ GREEN,    3

.data
.align 2

# Each rectangle: x, y, width, height, color.
rectangles:
    # Request routes
    .word 25, 19, 77,  1, BLACK
    .word 25, 19,  1, 20, BLACK
    .word 63, 13,  1, 26, BLACK
    .word 101,19,  1, 20, BLACK

    # Server bodies
    .word 14, 48, 23, 32, BLACK
    .word 52, 48, 23, 32, BLACK
    .word 90, 48, 23, 32, BLACK

    # Green stripes
    .word 14, 55, 23, 2, GREEN
    .word 14, 65, 23, 2, GREEN
    .word 52, 55, 23, 2, GREEN
    .word 52, 65, 23, 2, GREEN
    .word 90, 55, 23, 2, GREEN
    .word 90, 65, 23, 2, GREEN


# Three-pixel-wide, five-pixel-high font.
# Glyph indices: S=0, E=1, R=2, V=3, space=4, 1=5, 2=6, 3=7.
font:
    .byte 7, 4, 7, 1, 2       # S
    .byte 7, 4, 6, 4, 7       # E
    .byte 6, 5, 6, 5, 5       # R
    .byte 5, 5, 5, 5, 2       # V
    .byte 0, 0, 0, 0, 0       # space
    .byte 2, 6, 2, 2, 7       # 1
    .byte 6, 1, 2, 4, 7       # 2
    .byte 6, 1, 2, 1, 6       # 3

labels:
    .byte 0, 1, 2, 3, 1, 2, 4, 5   # SERVER 1
    .byte 0, 1, 2, 3, 1, 2, 4, 6   # SERVER 2
    .byte 0, 1, 2, 3, 1, 2, 4, 7   # SERVER 3

.text
.globl main

main:
    # Paint the background.
    li t0, FB
    li t1, WIDTH
    li t2, HEIGHT
    mul t2, t1, t2
    li t3, WHITE

background_loop:
    sb t3, 0(t0)
    addi t0, t0, 1
    addi t2, t2, -1
    bnez t2, background_loop

    # Draw routes, server bodies, and green stripes.
    la s0, rectangles
    li s1, 13

rectangle_loop:
    lw a0, 0(s0)
    lw a1, 4(s0)
    lw a2, 8(s0)
    lw a3, 12(s0)
    lw a4, 16(s0)
    jal ra, draw_rectangle

    addi s0, s0, 20
    addi s1, s1, -1
    bnez s1, rectangle_loop
    
    la s0, labels
    li s1, 3
    li s2, 10
    
label_loop:
    mv a0, s2
    li a1, 90
    mv a2, s0
    jal ra, draw_label

    addi s0, s0, 8
    addi s2, s2, 38
    addi s1, s1, -1
    bnez s1, label_loop

    # Present the completed screen once.
    li t0, PRESENT
    li t1, 1
    sw t1, 0(t0)

    li a7, 10
    ecall

# ------------------------------------------------------------
# draw_rectangle
# a0 = x, a1 = y, a2 = width, a3 = height, a4 = color
# ------------------------------------------------------------
draw_rectangle:
    li t0, WIDTH
    mul t1, a1, t0
    add t1, t1, a0
    li t2, FB
    add t1, t1, t2

    mv t3, a3

rectangle_row:
    mv t4, t1
    mv t5, a2

rectangle_pixel:
    sb a4, 0(t4)
    addi t4, t4, 1
    addi t5, t5, -1
    bnez t5, rectangle_pixel

    addi t1, t1, WIDTH
    addi t3, t3, -1
    bnez t3, rectangle_row
    ret




# ------------------------------------------------------------
# draw_label
# a0 = x, a1 = y, a2 = address of eight glyph indices
# ------------------------------------------------------------
draw_label:
    li a3, 8

label_character:
    lbu t0, 0(a2)
    li t1, 5
    mul t0, t0, t1
    la t1, font
    add t0, t0, t1
    li t1, 0

label_row:
    lbu t2, 0(t0)

    add t3, a1, t1
    li t4, WIDTH
    mul t3, t3, t4
    add t3, t3, a0
    li t4, FB
    add t3, t3, t4

    li t4, 4
    li t5, 3

label_pixel:
    and t6, t2, t4
    beqz t6, label_skip_pixel
    li t6, BLACK
    sb t6, 0(t3)

label_skip_pixel:
    srli t4, t4, 1
    addi t3, t3, 1
    addi t5, t5, -1
    bnez t5, label_pixel

    addi t0, t0, 1
    addi t1, t1, 1
    li t6, 5
    blt t1, t6, label_row

    addi a0, a0, 4
    addi a2, a2, 1
    addi a3, a3, -1
    bnez a3, label_character
    ret