
section .text
;------------------------------------------------
global _start

;------------------------------------------------
; Printf function
; calling convention:
;       Entry: rdi, rsi, rdx, rcx, r8, r9, stack
;       rdi - string address
;       Exit: rax -number of characters transmitted
;             to the output stream or negative value
;             if an output error or an encoding error
;             (for string and character conversion specifiers)
;             occurred.
;       Convention:
;       rax, rcx, rdx, rsi, rdi, r8-r11 - caller-saved
;       rbx, rbp, r12-15 - callee-saved
;-----------------------------------------------

_start:
    push rbp
    mov rbp, rsp

    push rbx r12 r13

    mov [rbp - 8],  rsi ; 1 arg
    mov [rbp - 16], rdx ; 2 arg
    mov [rbp - 24], rcx ; 3 arg
    mov [rbp - 32], r8  ; 4 arg
    mov [rbp - 40], r9  ; 5 arg
    xor rcx, rcx  ; argument counter
    mov r12, 10h ; start position for arguments, passed by stack

    PercentageCode equ 25h
    LineFeedCode   equ 0ah
    NullCode       equ 0h

    mov r10, offset Buffer
    mov r11, [Specifiers] ; jump table
    xor rbx, rbx ; cleaning rbx for symbol code storing

.next_symbol:
    call CheckBuffer ; check if buffer need to flush
                     ; (if buffer has become full)

    mov bl, [rdi] ; get symbol

    cmp bl, NullCode
    je .exit ; if '\0'

    cmp bl, PercentageCode
    je .specifier_processing ; if '%'

.insert_symbol
    mov [r10], bl ; insert next character to the buffer

    inc r10 ; r10 - actual buffer pointer
    inc rdi ; rdi - address of the next symbol in the format string
    jmp .next_symbol

.specifier_processing:
    inc rdi ; rdi - address of the next symbol in the format string
    mov bl, [rdi] ; bl - name of specifier
    cmp bl, PercentageCode
    je .insert_symbol

    inc rcx ; need get next argument, passed after format string
    cmp rcx, 5h
    ja .get_arg_passed_by_stack ; if all parameters passed by registers were used
    mov r13, [rbp - rcx * 8] ; save next argument for processing
    jmp [r11 + rbx * 8] ; jump to the corresponding processer

.get_arg_passed_by_stack:
    mov r13, [rbp + r12] ; save next parameter passed via stack
    add r12, 8h ; [rbp + r12] - next stack argument
    jmp [r11 + rbx * 8] ; jump to the corresponding processer

char:
    mov [r10], r13b ; write this byte to the buffer
    jmp .next_symbol

dec_int:
    i have binary representation of the number
    but should convert it to the decimal...
    4 bytes if first is 1, then negative value
    mov rax, r13 ; move argument to the rax
    push rdx ; save rdx
    cqo ; Convert Quadword to Octword
    mov rbx, 0ah
    idiv rbx


octal_int:


hex_int:


string:

.exit:
    call DumpBuffer

    pop r13 r12 rbx

    mov rsp, rbp ; for local variables
    pop rbp
    ret
;------------------------------------------------

;------------------------------------------------
; EstimateStoringStrategy function
; Description:
;   This function counts
;------------------------------------------------

;------------------------------------------------
; SpecifierProcessing function
; Entry: rdi address after percentage symbol
;        rsi, ..., r9, stack - other arguments
; Description:
;
;------------------------------------------------

SpecifierProcessing proc
    push rbp
    mov rbp, rsp

    push rbx

    xor rbx, rbx
    mov bl, [rdi]
    add rbx, offset Specifiers
    jmp [rbx]

integer:


    pop rbx

    pop rbp
    ret
SpecifierProcessing endp
;------------------------------------------------

DumpBuffer proc

DumpBuffer endp
;------------------------------------------------

CheckBuffer proc

CheckBuffer endp
;------------------------------------------------

section .data
;------------------------------------------------
BufferSize: db 0
;------------------------------------------------
;------------------------------------------------


section .rodata
;------------------------------------------------
Specifiers:
    dq 63h dup(0) ; 'c' - 0
    dq char       ; %c
    dq dec_int    ; %d
    dq 0bh dup(0) ; 'o' - 'd'
    dq octal_int  ; %o
    dq 4h dup(0)  ; 's' - 'o'
    dq string     ; %s
    dq 5h dup(0)  ; 'x' - 's'
    dq hex_int    ; %x
;------------------------------------------------
;------------------------------------------------


section .bss
;------------------------------------------------
BufferCapacity equ 128
Buffer: db BufferCapacity dup(?)
;------------------------------------------------
;------------------------------------------------
