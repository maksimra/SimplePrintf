
section .text
;------------------------------------------------
global SimplePrintf

;------------------------------------------------
; SimplePrintf function
; printf parody
; Entry: rdi, rsi, rdx, rcx, r8, r9, stack
; rdi - string address
; Exit: rax -number of characters transmitted
;       to the output stream or negative value
;       if an output error or an encoding error
;       (for string and character conversion specifiers)
;       occurred.
;-----------------------------------------------
SimplePrintf:
    push rbp
    mov rbp, rsp

    sub rsp, 40d
    mov [rbp - 8],  rsi ; 1 arg
    mov [rbp - 16], rdx ; 2 arg
    mov [rbp - 24], rcx ; 3 arg
    mov [rbp - 32], r8  ; 4 arg
    mov [rbp - 40], r9  ; 5 arg

    push rbx
    push r12
    push r13

    xor rcx, rcx  ; argument counter
    mov r12, 10h ; start position for arguments, passed by stack

    PercentageCode equ 25h
    LineFeedCode   equ 0ah
    NullCode       equ 0h
    ZeroCode       equ 30h
    CodeLetterA    equ 61h
    MinusCode      equ 2dh
    MinInteger     equ 80000000h
    MaxInteger     equ 7fffffffh

    xor r10, r10 ; position in buffer
    lea r11, [rel Specifiers] ; jump table
    xor rbx, rbx ; cleaning rbx for symbol code storing
    xor rax, rax ; cleaning rax for arithmetics

process_next_symbol:
    mov bl, [rdi] ; get symbol
    inc rdi ; rdi - address of the next symbol in the format string

    cmp bl, NullCode
    je exit ; if '\0'

    cmp bl, PercentageCode
    je .specifier_processing ; if '%'

    .insert_symbol:
        mov [Buffer + r10], bl ; insert next character to the buffer
        inc r10
        call CheckBuffer   

        jmp process_next_symbol

    .specifier_processing:
        mov bl, [rdi] ; bl - name of specifier
        inc rdi
        cmp bl, PercentageCode
        je .insert_symbol

        inc rcx ; need get next argument, passed after format string
        cmp rcx, 5h
        ja .get_arg_passed_by_stack ; if all parameters passed by registers were used

        push rsi
        mov rsi, rbp
        shl rcx, 3h
        sub rsi, rcx ; mov rsi, rbp - rcx * 8
        shr rcx, 3h
        mov r13, [rsi] ; save next argument for processing
        pop rsi

        jmp [r11 + rbx * 8] ; jump to the corresponding processer

    .get_arg_passed_by_stack:
        mov r13, [rbp + r12] ; save next parameter passed via stack
        add r12, 8h ; [rbp + r12] - next stack argument
        jmp [r11 + rbx * 8] ; jump to the corresponding processer

char:
    mov [Buffer + r10], r13b ; write this byte to the buffer
    inc r10
    call CheckBuffer

    jmp process_next_symbol

dec_int:
    mov eax, r13d ; move argument to the rax
    cmp eax, 0h
    jge .positive_dec ; else print minus and work at the same as with positive value

    mov bl, MinusCode
    mov [Buffer + r10], bl
    inc r10
    call CheckBuffer

    neg eax ; get corresponding positive value

    .positive_dec:
        push rdx ; save register
        push rcx ; save argument counter for using rcx as digit counter
        xor rdx, rdx ; eax -> edx:eax
        xor rcx, rcx
        mov rbx, 0ah

    .next_dec_digit:
        inc rcx ; +1 digit in number
        div rbx
        push rdx ; store remainder
        xor rdx, rdx
        cmp rax, 0h 
        jne .next_dec_digit ; if number in eax still not less than 10

    .print_next_dec_digit:
        pop rbx
        add bl, ZeroCode
        mov [Buffer + r10], bl
        inc r10
        call CheckBuffer

        loop .print_next_dec_digit

    pop rcx
    pop rdx
    jmp process_next_symbol


octal_int:
    mov eax, r13d ; move argument to the rax

    push rdx ; save register
    push rcx ; save argument counter for using rcx as digit counter
    xor rdx, rdx ; eax -> edx:eax
    xor rcx, rcx
    mov rbx, 8h

    .next_oct_digit:
        inc rcx ; +1 digit in number
        div rbx
        push rdx ; store remainder
        xor rdx, rdx
        cmp rax, 0h 
        jne .next_oct_digit ; if number in eax still not less than 8
    
    .print_next_oct_digit:
        pop rbx
        add bl, ZeroCode
        mov [Buffer + r10], bl
        inc r10
        call CheckBuffer

        loop .print_next_oct_digit

    pop rcx
    pop rdx
    jmp process_next_symbol

hex_int:
    mov eax, r13d ; move argument to the rax

    push rdx ; save register
    push rcx ; save argument counter for using rcx as digit counter
    xor rdx, rdx ; eax -> edx:eax
    xor rcx, rcx
    mov rbx, 10h

    .next_hex_digit:
        inc rcx ; +1 digit in number
        div rbx
        push rdx ; store remainder
        xor rdx, rdx
        cmp rax, 0h 
        jne .next_hex_digit ; if number in eax still not less than 10h
    
    .process_next_hex_digit:
        pop rbx
        cmp bl, 0ah
        jae .letter_digit
        add bl, ZeroCode
        jmp .print_hex_digit

        .letter_digit:
            add bl, CodeLetterA
            sub bl, 0ah
        
        .print_hex_digit:
            mov [Buffer + r10], bl
            inc r10
            call CheckBuffer

            loop .process_next_hex_digit

    pop rcx
    pop rdx
    jmp process_next_symbol

string:
    push rcx ; save for string length storing
    xor rcx, rcx
    push rdx ; save for storing charachters
    push r13 ; save string address

    .next_char:
        mov dl, [r13]
        cmp dl, NullCode
        je .counting_end

        inc rcx ; string length += 1
        inc r13 ; point to the next charachter
        jmp .next_char   

    .counting_end:
        pop r13 ; string address
        cmp rcx, BufferCapacity
        ja .dump_string ; if length of the string bigger than all buffer capacity
                        ; we dump string by separate syscall

        push rbx
        xor rbx, rbx
        mov rbx, BufferCapacity
        sub rbx, r10 ; rbx - free buffer space
        cmp rcx, rbx
        jb .fill_buffer ; if we have enough space - write string to the buffer

        call DumpBuffer ; if string bigger than free space in buffer

    .fill_buffer:
        pop rbx

        .store_next_char:
            mov cl, [r13] ; get next string element
            inc r13
            cmp cl, NullCode
            je .string_end

            mov [Buffer + r10], cl ; store charachter in the buffer
            inc r10
            jmp .store_next_char


    .dump_string:
        push rsi
        mov rsi, r13 ; save argument string for dump
        xor rdx, rdx
        mov rdx, rcx ; rdx - string length
        call WriteSyscall ; write (1, buffer (rsi), buffer_size (rdx))
        pop rsi

.string_end:
    pop rdx
    pop rcx
    jmp process_next_symbol
    

exit:
    call DumpBuffer

    pop r13
    pop r12
    pop rbx

    mov rsp, rbp ; for local variables
    pop rbp
    ret
;------------------------------------------------


;------------------------------------------------
; Description: This function dump all buffer in stdout
;              and update buffer position
; Entry: r10 - buffer size
;------------------------------------------------
DumpBuffer:
    push rsi
    push rdx

    mov rsi, Buffer
    xor rdx, rdx
    mov rdx, r10
    call WriteSyscall ; write (1, buffer (rsi), buffer_size (rdx))

    xor r10, r10

    pop rdx
    pop rsi
    ret
;------------------------------------------------


;------------------------------------------------
; Description: Wrapper for write syscall (write in stdout)
; Entry: rsi - buffer address
;        rdx - buffer size
;------------------------------------------------
WriteSyscall:
    push rax
    push rdi
    push rcx
    push r11

    StdOutDescr equ 1
    mov rax, 1h ; write syscall number
    mov rdi, StdOutDescr
    syscall

    pop r11
    pop rcx
    pop rdi
    pop rax
    ret   
;------------------------------------------------


;------------------------------------------------
; Description: This function check buffer fullness
;              and dump it if full.
; Entry: r10 - buffer's current size
;------------------------------------------------
CheckBuffer:
    cmp r10, BufferCapacity
    jb .exit

    call DumpBuffer
    xor r10, r10

.exit:
    ret
;------------------------------------------------


section .rodata
;------------------------------------------------
Specifiers:
    dq 63h dup(0) ; 'c' - 0
    dq char       ; %c
    dq dec_int    ; %d
    dq 0ah dup(0) ; 'o' - 'd'
    dq octal_int  ; %o
    dq 3h dup(0)  ; 's' - 'o'
    dq string     ; %s
    dq 4h dup(0)  ; 'x' - 's'
    dq hex_int    ; %x
;------------------------------------------------
;------------------------------------------------


section .bss
;------------------------------------------------
BufferCapacity equ 128
Buffer: resb BufferCapacity
;------------------------------------------------
;------------------------------------------------
