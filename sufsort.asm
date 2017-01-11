%include "asm_io.inc"

SECTION .data
msg2: db "Incorrect number of command line arguments",10,0
msg3: db "Incorrect length of command line agrgument",10,0
msg5: db "Incorrect command line argument",10,0
msg10: db "sorted suffixes",10,0
check: dd 2
check2: dd 30

SECTION .bss
X: resd 30
Y: resd 30
count1: resd 1
count2: resd 1
N: resd 1
i: resd 1
j: resd 1
y1: resd 1

SECTION .text
	global asm_main

;subroutine sufcmp(Z, i, j)
sufcmp:
	enter 0,0
	pusha

	; get param from stack
	mov ebx, ebp
	mov ecx, [ebx+8] ; array
	mov edx, [ebx+12] ; i lowest always
	mov edi, [ebx+16] ; j

	; since j is always > i
	; min(len(Z)-i,len(Z)-j)
	; always equals len(Z)-j
	mov [count2], dword 0
	LOOP1:
		mov al, byte [ecx+edx] ; check if == 0
		cmp al, 0
		je RETMINUS

		mov al, byte [ecx+edi]
		cmp al, 0
		je RETPLUS


		mov al, byte [ecx+edx]
		cmp al, byte [ecx+edi] ; Z[i+o] < Z[j+o]
		jb RETMINUS
		cmp al, byte [ecx+edi] ; Z[i+o] > Z[j+o]
		ja RETPLUS

		inc edx
		inc edi
		jmp LOOP1

	RETPLUS:
		popa
		mov eax, 1
		jmp END
	RETMINUS:
		popa
		mov eax,-1
	END:
	leave
	ret

asm_main:
	enter 0,0
	pusha

	; # of arguments
	mov eax, dword [ebp+8]

	;compare # of args from argc
	cmp eax, [check]
	jne ERR1

	mov ebx, dword [ebp+12] ;address of argv[]
	mov eax, dword [ebx+4] ;argv[1] our input string

	mov edx, dword [ebx+4] ;edx has argument
	mov [count1], dword 0
	COUNT:
		;increment argument length
		add [count1], dword 1
		;count1 contains len of arugment

		;check characters
		mov al, byte[edx]
		try1: ; check if byte = 0
		cmp al, '0'
		jne try2 ;if not = 0 go to next check
		jmp byte_ok ;byte is ok
		try2: ; check if byte = 1
		cmp al, '1'
		jne try3 ;if not = 1 go to next check
		jmp byte_ok ;byte is ok
		try3: ; check if byte = 2
		cmp al, '2'
		jne ERR3

		byte_ok:
		add edx, dword 1 ;move character pointer

		mov eax, [count1]
		cmp eax,[check2] ;check if count1 > 30
		ja ERR2

		cmp byte[edx],0
		jne COUNT

	;program can start normally
	mov edx, dword [ebx+4] ;edx has argument
	mov [N], dword 0 ; length of input
	mov ecx, X ; ecx = X[]
	mov [y1], dword Y
	mov edi, 0
	COPYLOOP:
		;copy input to an array X
		mov al, byte[edx] ; get byte of input
		mov [ecx], al ; set X array element
		inc ecx ; shift array counter
		add [N], dword 1; increment N counter
		add edx, dword 1; shift input bytes
		
		; copy suffix indices in array y
		mov eax, edi
		mov ebx, dword[y1]
		mov [ebx], eax
		add [y1], dword 4
		add edi, dword 1

		cmp byte[edx],0; loop until end of input string
	jne COPYLOOP

	; check if array was copied properly
	mov eax, X
	call print_string
	call print_nl

	; bubble sort 
	mov edi, [N] ; i
	mov [i], edi
	FOR1:
		mov esi, [i]
		mov [j], dword 1
		mov [y1], dword Y
		FOR2:
			;enter inner for loop

			; call subroutine
			add [y1], dword 4
			mov ebx, dword [y1]
			mov eax, dword [ebx] ;eax = y[j]
			push eax ;push j param

			sub [y1], dword 4
			mov ebx, dword [y1]
			mov eax, dword [ebx] ;eax = y[j-1]
			push eax ;push i param

			mov eax, X
			push eax ;push array param
			call sufcmp
			add esp, 12 ; restore stack pointer

			cmp eax, 0 ; eax contains result from subroutine
			jl NOSWAP ; if result < 0 then don't swap
			SWAP:
				add [y1], dword 4
				mov ebx, dword [y1]
				mov ecx, dword [ebx] ; ecx = y[j]

				sub [y1], dword 4
				mov ebx, dword [y1]
				mov eax, dword [ebx] ; eax = y[j-1]
				mov [ebx], ecx ; y[j-1] = y[j]
				
				add [y1], dword 4
				mov ebx, dword [y1]
				mov [ebx], eax ; y[j] = t(eax)

				sub [y1], dword 4 ; adjust array pointer
			NOSWAP:
			add [y1], dword 4
			add [j], dword 1
			cmp [j], esi
			jb FOR2
		FOR2DONE:
		sub [i], dword 1
		cmp [i], dword 0
		jne FOR1

	mov eax, msg10
	call print_string

	mov edi,[N]
	mov [i], dword 0
	mov [y1], dword Y
	DISPLAY:
		mov ebx, dword [y1]
		mov ecx, dword [ebx] ; y[i]
		mov [j], dword 0
		mov [j], dword ecx
		mov edx, X
		add edx, dword [j]
		DISPLAY2: ; loop from y[i]:N for X[]
			mov al, byte [edx]
			call print_char
			add edx, dword 1
			add [j], dword 1
			cmp [j], edi
			jb DISPLAY2
		call print_nl

		add [y1], dword 4
		add [i], dword 1
		cmp [i], edi
		jb DISPLAY

	;program termination
	jmp NORMALEND

	ERR1:
	;termination from wrong # of arguments
	mov eax, msg2
	call print_string
	jmp NORMALEND

	ERR2:
	;termination from length of arguments
	mov eax, msg3
	call print_string
	jmp NORMALEND

	ERR3:
	;termination from arguments not '0' or '1' or '2'
	mov eax, msg5
	call print_string
	jmp NORMALEND

	NORMALEND:
	;standard program end
	popa
	leave
	ret