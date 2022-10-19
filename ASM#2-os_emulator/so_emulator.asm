global          so_emul

%ifndef         CORES
%define         CORES   4
%endif

REGA    equ     0
REGD    equ     1
REGX    equ     2
REGY    equ     3
MEMX    equ     4
MEMY    equ     5
MEMXD   equ     6
MEMYD   equ     7

OPARGS  equ     0x3FFF
ARG1    equ     0x0700
ARG1SH  equ     0x0008
ARG2    equ     0x3800
ARG2SH  equ     0x000B
BRK     equ     0xFFFF

; jmp_op <reg16>, <imm16>, <label>
%macro  jmp_op      3
        cmp     %1, %2
        jb      %3
%endmacro

; call_op_imm <func> <whether we set the argument>
%macro  call_op_imm 1
        call    %1
        jmp     .op_finished
%endmacro

; decode_arg <reg64>, <imm16>, <reg16>, <reg16>, <imm8>
%macro  decode_arg   5
        mov     %1, %2
        and     %3, %4
        shr     %3, %5    
%endmacro

section .bss

cpu_state:      resq CORES

section .data

align           4
spin_lock:      dd 0

jmp_table_two_args:   dq op_mov, 0, op_or, 0, op_add, op_sub, op_adc, op_sbb
jmp_table_jump:       dq op_jmp, 0, op_jnc, op_jc, op_jnz, op_jz

section .text

; cpu_state_t so_emul(uint16_t const *code, uint8_t *data, size_t steps, size_t core);
; rdi - uint16_t const *code
; rsi - uint8_t *data
; rdx - size_t steps
; rcx - size_t core
;
; Value (8-bytes struct) returned in RAX.
; Modifies RDI, RSI, RDX, RCX, R8, R9, R10, R11.
so_emul:
        push    rbp
        mov     rbp, rsp

        push    r12
        push    r13
        push    r14
        push    r15

        lea     r14, [rel spin_lock]

        mov     r8, rdi ; r8 = uint16_t *code
        mov     r9, rdx ; r9 = size_t steps

        ; Retrieve current state of the core.
        lea     rdi, [rel cpu_state]
        lea     rdi, [rdi + rcx * 8]

        ; Retrieve PC.
        xor     rdx, rdx
        mov     dl, [rdi + 4]

        cmp     r9, 0
        jne     .main_loop
        jmp     .exit

.main_loop:
        ; Get current instruction code.
        mov     r10w, [r8 + rdx * 2]

        ; PC++
        inc     dl

        decode_arg  r11, ARG1, r11w, r10w, ARG1SH
        call    get_arg

        cmp     r10w, OPARGS
        jbe     .op_two_args

        cmp     r10w, BRK
        je      .exit

        jmp     .op_imm

.op_two_args:
        mov     cl, al ; CL = arg1
        mov     r15, r13 ; R15 = mem(arg1)

        ; Retrieve arg2
        decode_arg  r11, ARG2, r11w, r10w, ARG2SH
        call     get_arg
        xchg     r15, r13 ; R15 = mem(arg2), R13 = mem(arg1)
        xchg     cl, al ; CL = arg2, AL = arg1

        mov     r12, 0x000F
        and     r12w, r10w

        cmp     r12w, 8
        je      .atomic

        jmp     .not_atomic

; Operation = XCHG
.atomic:
        call    get_lock
        mov     cl, [r15]

        xchg    [r13], cl
        mov     [r15], cl

        call    release_lock

        jmp     .op_finished

.not_atomic:
        lea     r11, [rel jmp_table_two_args]
        call    [r11 + r12 * 8]

        jmp     .op_finished

.op_imm:
        ; Retrieve arg2.
        mov     cl, r10b

        jmp_op  r10w, 0x5800, .movi
        jmp_op  r10w, 0x6000, .xori
        jmp_op  r10w, 0x6800, .addi
        jmp_op  r10w, 0x7001, .cmpi
        jmp_op  r10w, 0x8000, .rcr
        jmp_op  r10w, 0x8100, .clc
        jmp_op  r10w, 0xC000, .stc

; Jumps
        lea     r11, [rel jmp_table_jump]

        mov     r12, 0x0700
        and     r12w, r10w
        shr     r12w, 8

        call    [r11 + r12 * 8]

        jmp     .op_finished

; MOVI is an exception since it should be atomic.
.movi:
        call_op_imm op_mov

.xori:
        call_op_imm op_xori

.addi:
        call_op_imm op_add

.cmpi:
        call_op_imm op_cmpi

.rcr:
        call_op_imm op_rcr

.clc:
        call_op_imm op_clc

.stc:
        call_op_imm op_stc

.op_finished:
        dec     r9
        jnz     .main_loop

.exit:
        mov     [rdi + 4], dl
        mov     rax, [rdi]

        pop     r15
        pop     r14
        pop     r13
        pop     r12

        leave
        ret


; Retrieves the argument's value from the memory.
; R11W holds the code of the argument.
; Value is stored in AL, and its address is stored in R13.
get_arg:
        cmp     r11w, MEMX
        jb      .reg

        xor     r13, r13

        cmp     r11w, MEMXD
        jb      .mem1

; [X + D] or [Y + D]
        mov     r13b, [rdi + r11 - 4]
        add     r13b, [rdi + 1]
        jmp     .memexit

; [X] or [Y]
.mem1:
        mov     r13b, [rdi + r11 - 2]

.memexit:
        lea     r13, [rsi + r13]
        jmp     .exit

; A, D, X or Y
.reg:
        lea     r13, [rdi + r11]

.exit:
        mov     al, [r13]
        ret

get_lock:
        mov     r11d, 1
.busy_wait:
        xchg    [r14], r11d
        test    r11d, r11d
        jnz     .busy_wait
        ret

release_lock:
        xor     r11d, r11d
        mov     [r14], r11d
        ret

;
; --- Implementation of the operations. ---
;

op_mov:
        mov  [r13], cl
        ret

op_or:
        or      [r13], cl
        setz    [rdi + 7]
        ret

op_add:
        add     [r13], cl
        setz    [rdi + 7]
        ret

op_sub:
        sub     [r13], cl
        setz    [rdi + 7]
        ret

op_adc:
        cmp     BYTE [rdi + 6], 1
        jne     .zero

        stc
        jmp     .after
.zero:
        clc
.after:

        adc     [r13], cl
        setc    [rdi + 6]
        setz    [rdi + 7]
        ret

op_sbb:
        cmp     BYTE [rdi + 6], 1
        jne     .zero

        stc
        jmp     .after

.zero:
        clc

.after:
        sbb     [r13], cl
        setc    [rdi + 6]
        setz    [rdi + 7]
        ret

op_xori:
        xor     [r13], cl
        setz    [rdi + 7]
        ret

op_cmpi:
        cmp     [r13], cl
        setc    [rdi + 6]
        setz    [rdi + 7]
        ret

op_rcr:
        cmp     BYTE [rdi + 6], 1
        jne     .zero

        stc
        jmp     .after

.zero:
        clc

.after:
        rcr     BYTE [r13], 1
        setc    [rdi + 6]
        ret

op_clc:
        mov     BYTE [rdi + 6], 0
        ret

op_stc:
        mov     BYTE [rdi + 6], 1
        ret

op_jmp:
        add     dl, cl
        ret

op_jnc:
        cmp     BYTE [rdi + 6], 0
        jne     .skip

        add     dl, cl
.skip:
        ret

op_jc:
        cmp     BYTE [rdi + 6], 1
        jne     .skip

        add     dl, cl
.skip:
        ret

op_jnz:
        cmp     BYTE [rdi + 7], 0
        jne     .skip

        add     dl, cl
.skip:
        ret

op_jz:
        cmp     BYTE [rdi + 7], 1
        jne     .skip

        add     dl, cl
.skip:
        ret