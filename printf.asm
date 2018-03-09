; nasm -f elf64 printf.asm; gcc -o printf printf.o -no-pie

global main

msg: db 0x0a, "Hello, Team %s %d!", 0x0a, 0
msg2: db "Minivet", 0

main:
    mov rax, 0x1234
    push rax
    push msg2
    push msg
    call printf_start
    add rsp, 8
    call exit

printf_start:
    push rbp
    mov rbp, rsp
    xor rax, rax
    mov al, 0x2
    push rax		    ; rbp-0x8 = argument number
    lea rbx, [rbp+rax*8]    ; rbx = printf argument pointer
    mov rsi, qword[rbx]	    ; string

printf_loop:
    mov bl, byte[rsi]
    test bl, bl
    jz printf_end

    cmp bl, 0x25
    jnz print_char
    inc rsi

    mov bl, byte[rsi]
    cmp bl, 0x73
    jz print_str
    cmp bl, 0x64
    jz print_int
;    cmp bl, 0x75
;    jz print_uint
    
print_char:
    xor rdi, rdi
    inc rdi		    ; stdout
    xor rdx, rdx
    inc rdx		    ; length
    xor rax, rax
    mov al, 0x1		    ; syscall number(write)
    syscall

    inc rsi		    ; string ptr += 1
    jmp printf_loop	    ; for loop

print_str:
    pop rax		    ; get argument number
    inc rax
    push rax		    ; restore argument number(rbp-0x8)

    inc rsi
    push rsi		    ; store main string ptr
    lea rbx, [rbp+rax*8]    ; rbx = printf argument pointer
    mov rsi, qword[rbx]	    ; string
   
print_str_loop: 
    mov bl, byte[rsi]
    test bl, bl
    jz print_str_end

    xor rdi, rdi
    inc rdi		    ; stdout
    xor rdx, rdx
    inc rdx		    ; length
    xor rax, rax
    mov al, 0x1		    ; syscall number(write)
    syscall

    inc rsi		    ; string ptr += 1
    jmp print_str_loop

print_str_end:
    pop rsi
    jmp printf_loop	    ; return printf

print_int:
    pop rax		    ; get argument number
    inc rax
    push rax		    ; restore argument number(rbp-0x8)

    inc rsi
    push rsi		    ; store main string ptr
    sub sp, 0x10	    ; for temp buffer
    lea rsi, [rbp-0x10]	    ; rsi = buffer ptr
    dec rsi		    
    mov byte[rsi], 0x00	    ; null
    lea rbx, [rbp+rax*8]    ; rbx = printf argument pointer
    mov rax, qword[rbx]	    ; rax = int value
    xor rcx, rcx	    ; index
    xor rdi, rdi
    mov di, 0xffff	    ; mask

print_int_loop:
    xor rbx, rbx
    mov bl, 10
    mov rdx, rax
    sar eax, 16
    xchg rdx, rax	    ; edx = dx*0x10000 + ax
    and rax, rdi
    idiv bx

    add dl, 0x30
    dec rsi		    ; buffer ptr -= 1
    mov byte[rsi], dl	    ; int value => string
    inc rcx		    ; index += 1
    test eax, eax
    jnz print_int_loop	    ; for loop

    xor rdi, rdi
    inc rdi		    ; stdout
    mov rdx, rcx
    inc rdx		    ; length
    xor rax, rax
    mov al, 0x1		    ; syscall number(write)
    syscall

    add sp, 0x10	    ; clean temp buffer
    pop rsi
    jmp printf_loop	    ; return printf

printf_end:
    leave
    ret

exit:
    xor rdi, rdi
    xor rax, rax
    mov al, 60
    syscall

