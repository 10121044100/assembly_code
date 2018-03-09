; nasm -f elf64 scanf.asm; gcc -o scanf scanf.o -no-pie

global main

msg: db "%d", 0

main:
    push rbp
    mov rbp, rsp
    sub sp, 0x410	    ; real buffer

    lea rbx, [rbp-0x410]
    push rbx
    push msg
    call scanf_start
    add rsp, 0x10

    jmp exit

scanf_start:
    push rbp
    mov rbp, rsp
    sub sp, 0x410	    ; buffer(temp)
    xor rax, rax
    mov al, 0x2
    push rax		    ; rbp-0x8 = argument number
    lea rbx, [rbp+rax*8]    ; rbx = printf argument pointer
    mov rsi, qword[rbx]	    ; string

scanf_loop:
    mov bl, byte[rsi]
    test bl, bl
    jz scanf_end

    cmp bl, 0x25
    jnz scanf_loop
    inc rsi

    mov bl, byte[rsi]
    cmp bl, 0x73
    jz get_str
    cmp bl, 0x64
    jz get_int
    
get_str:
    pop rax
    inc rax
    push rax

    push rsi
    lea rbx, [rbp+rax*8]
    mov rsi, qword[rbx]
    call input_data
    pop rsi
    inc rsi		    ; string ptr += 1

    jmp scanf_loop	    ; for loop

get_int:
    push rsi
    lea rsi, [rbp-0x410]
    call input_data

    mov rcx, rax	    ; rcx = rax = inputed size
    dec rcx
    xor rax, rax
    xor rbx, rbx
    xor rdx, rdx

get_int_loop:
    mov bl, byte[rsi]
    cmp bl, 0x30
    jb return_scanf_loop
    cmp bl, 0x39
    jg return_scanf_loop
    sub bl, 0x30
    mov dl, 10
    mul dl
    add rax, rbx	    ; convert

    dec rcx
    inc rsi
    test rcx, rcx
    jnz get_int_loop

return_scanf_loop:
    pop rsi
    inc rsi		    ; string ptr += 1

    ; copy
    pop rbx
    inc rbx
    push rbx

    lea rdi, [rbp+rbx*8]
    mov rdi, qword[rdi]
    mov dword[rdi], eax
    jmp scanf_loop	    ; for loop

input_data:
    xor rdi, rdi	    ; stdin
    xor rdx, rdx
    mov dx, 0x400	    ; length(temp)
    xor rax, rax	    ; syscall number(read)
    syscall

    ret

scanf_end:
    leave
    ret

exit:
    xor rdi, rdi
    xor rax, rax
    mov al, 60
    syscall

