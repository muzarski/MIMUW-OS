global polynomial_degree

section .text

; int polynomial_degree(int const *y, size_t n)
; rdi - int const *y
; rsi - size_t n
; Result placed in eax
; Modified registers: rcx, rdx, rsi, rdi, r8, r9, r10, r11
;
; Short description:
; We represent each number as a sequence of the 64-bit numbers.
; Firstly, we prepare for the algorithm, allocating memory on the stack.
; Then, we iterate through array and perform the subtraction of
; the neighboring numbers in the array (arr[i] = arr[i] - arr[i + 1]).
; Additionally, we remove (just by decreasing number of the iterations) the last element of the array.
; Algorithm stops when one of the following is true:
;       1) the array is empty,
;       2) we found a 'zero polynomial' (all elements in the array are equal to 0).
;
; Main usage of some of the registers:
; r8 - iterating over the stack,
; r9 - size of the arrays which are the representations of each number,
; r10 - temporary 'value holder', used when we want to perform operations on two operands which are <mem>
; rcx - iteration counter, if there is a nested loop,
;       we push its value on the stack, and pop it after the nested loop is finished,
; eax - stores the result
polynomial_degree:
        push    rbp
        mov     rbp, rsp

        ; Since 'n' is uint64_t, each number might
        ; potentially need to be represented using n + 31 bits.
        ; (n / 64 + 2) * 8 is a sane upper bound of the number of bytes needed for each number.
        mov     rdx, rsi
        shr     rdx, 6
        add     rdx, 2
        ; r9 = n / 64 + 2
        mov     r9, rdx
        ; rdx = (n / 64 + 2) * 8
        shl     rdx, 3

        ; rcx = n
        mov     rcx, rsi
        
        ; Let r8 point to the beginning of the array.
        lea     r8, [rbp - 8]
        
; Iterating n times.
.prepare_loop:

        ; Allocate memory for the current number.
        sub     rsp, rdx

        ; r10 = (int64_t) *rdi
        movsxd  r10, DWORD [rdi]
        mov     QWORD [r8], r10

        ; We want to represent each number in U2,
        ; which is why we need to duplicate 0/1 into the upper-order bits.
        xor     r11, r11
        cmp     r10, 0
        ; r11b is set to 1 if the number is negative, and to 0 otherwise.
        setl    r11b
        ; Negate it, so we can fill the bits with ones when needed.
        neg     r11

        ; Move the 'pointers'.
        sub     r8, 8
        add     rdi, 4
        
        ; Store the number of the iteration left in '.prepare_loop'.
        push    rcx
        ; rcx = n / 64 + 1
        lea     rcx, [r9 - 1]
        
; Iterating (n / 64 + 1) times, filling the upper-order bits with 0/1.
.fill_upper_order_loop:

        ; Duplicate 0/1 into the upper-order bits.
        mov     QWORD [r8], r11
        ; Move the 'pointer'.
        sub     r8, 8
        loop    .fill_upper_order_loop
        
        ; Retrieve the number of the iteration left in '.prepare_loop'.
        pop     rcx
        loop    .prepare_loop
        
; --------------------------------------
; The main part of the algorithm begins.
; --------------------------------------

        ; The result.
        mov     eax, -1

        ; rcx = n
        mov     rcx, rsi
        
; Iterating until the algorithm needs to be stopped (at most n times).
.while_not_empty_nor_zero_loop:

        ; Store the number of the iteration left in '.while_not_empty_nor_zero_loop'.
        push    rcx

        ; rsi holds the boolean value.
        ; True meaning we found the 'zero polynomial'.
        mov     sil, 1
        
        ; Hold the current size of the array.
        mov     rdx, rcx
        ; Let r8 point to the beginning of the array.
        lea     r8, [rbp - 8]

; Iterating x times, where x is the current size of the array.
; NOTE: We don't assign any new value to the rcx, since with each iteration of the '.while_not_empty_nor_zero_loop',
;       we want to decrease the number of the iterations of the '.main_loop' by one.
.main_loop:

        ; Store the number of the iteration left in '.while_not_empty_nor_zero_loop'.
        push    rcx

        ; rcx = n / 64 + 2
        mov     rcx, r9

        ; Zero the carry bit and push the FLAG register onto the stack.
        ; We do it, so there is no need to use 'sub' instead of 'sbb' in the first iteration.
        clc
        pushf
        
; Iterating (n / 64 + 2) times.
.check_if_zero_and_subtract_loop:

        ; Check whether the current 8 bytes of the current number are 0.
        ; Then, override the boolean value being held in sil.
        cmp     QWORD [r8], 0
        sete    r11b
        and     sil, r11b

        ; Check whether it is the last iteration of the '.check_if_zero_and_subtract_loop'.
        ; If yes, we don't perform subtraction (since there is no successor).
        cmp     rdx, 1
        je     .skip_sub

        ; r9 holds the length of the array which is the representation of each bignum.
        ; We need to negate it, since stack grows downward.
        neg     r9
        ; Assign value of the corresponding bits of the successor to r10.
        mov     r10, [r8 + r9 * 8]
        ; Back to the positive value.
        neg     r9

        ; Retrieve the FLAG register (holding the carry bit) saved after the previous subtraction.
        popf
        ; Perform subtraction with carry.
        sbb     [r8], r10
        ; Save the current value of the FLAG register.
        pushf

.skip_sub:

        ; Move the 'pointer'.
        sub     r8, 8
        loop    .check_if_zero_and_subtract_loop

        ; The remaining value of the FLAG register (pushed after the last subtraction).
        popf
        ; Retrieve the number of the iteration left in '.main_loop'.
        pop     rcx
        loop    .main_loop

        ; Check whether we found the 'zero polynomial'.
        ; If yes, we break out of the loop and we are ready to return our result stored in eax.
        cmp     sil, 1
        je     .break

        ; Increase the result by one.
        inc     eax
        ; Retrieve the number of the iteration left in '.while_not_empty_nor_zero_loop'.
        pop     rcx
        loop    .while_not_empty_nor_zero_loop

.break:
        leave
        ret