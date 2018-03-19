section .data
	DEV_FILE db '/dev/urandom', 0x0
	sigterm_msg db 'SIGTERM received', 0x0a
	sigterm_msg_len equ $ - sigterm_msg

section .bss
	random_fd: resq 1
	random_q: resq 2
	password: resb 21
	term_handler: resq 4

section .text
global _start
_start:
	; SET SIGNAL LISTENER
	mov qword [term_handler], exit_handler
	mov [term_handler + 8], dword 0x04000000
	mov rax, 13d       ; sys_rt_sigaction
	mov rdi, 15d       ; SIGTERM
	mov rsi, term_handler
	mov rdx, 0
	mov r10, 0x08
	syscall

	cmp rax, 0
	jne exit_handler

	mov rdi, 2d ; SIGINT
	mov rax, 13d
	syscall

	cmp rax, 0
	jne exit_handler
	; END SET SIGNAL LISTENER



	mov rax, 2d           ; SYS_OPEN
	mov rdi, DEV_FILE     ; /dev/urandom
	mov rsi, 0            ; RDONLY
	mov rdx, 0            ; no Flags
	syscall               ; open /dev/urandom
	cmp rax, 0            ;
	jl early_exit         ;
	mov [random_fd], rax  ; save file descriptor


	loop:
		mov rdi, [random_fd] ; move file_descriptor to rdi
		mov rax, 0           ; SYS_READ
		mov rsi, random_q    ; buffer target
		mov rdx, 16d         ; read 16 bytes
		syscall              ; read 16 bytes into random_q
		; TODO CODE HERE
		xor rbx, rbx
		mov rax, [random_q]  ;
		next_byte:
			xor dx, dx
			mov cx, 10d
			div cx
			add dl, 0x30
			mov byte [password + rbx], dl
			shr rax, 4
			inc rbx
			cmp rbx, 10d
			jne after_new_rand
			mov rax, [random_q + 8]
			after_new_rand:
			cmp rbx, 20d
			je output
			jmp next_byte
	jmp loop
	output:
		mov byte [password + 20], 0x0A
		mov rax, 1d
		mov rdi, 1d
		mov rsi, password
		mov rdx, 21d
		syscall
		jmp loop


exit_handler:
	mov rax, 1d
	mov rdi, 1d
	mov rsi, sigterm_msg
	mov rdx, sigterm_msg_len
	syscall

	mov rax, 3d        ; SYS_CLOSE (fd is still in rdi)
	mov rdi, [random_fd]
	syscall            ; close /dev/urandom
early_exit:
	mov rax, 60d       ; SYS_EXIT
	mov rdi, 0         ; exit code 0
	syscall            ; EOP

