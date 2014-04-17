[ORG 0x00007C00]
[BITS 16]

	rdtsc
	mov [0x7500], eax
	mov [0x7504], edx

	cli
	; disable the NMI
	in al, 0x70
	or al, 0x80
	out 0x70, al

	;load the gdt
	lgdt [gdt.pointer]

	;Actually enter protected mode
	mov eax, cr0
	or ax, 1
	mov cr0, eax

	;jump into protected mode code
	jmp gdt.code:initipi
[BITS 32]
initipi:
	mov ax, gdt.data
	mov ds, ax

	;Send INIT IPI
	; Destination shorthand = All excluding self
	; Level=1
	; Trigger Mode is ignored
	; Delivery Status is unused
	; Destination mode=Physical
	; Vector=0x00
	mov [0xFEE00300], dword 0x000C4500
	
	jmp gdt.codereal:returntoreal
[BITS 16]
returntoreal:
	;Exit protected mode
	mov eax, cr0
	and al, 0xFE
	mov cr0, eax

	jmp 0x0000:loaddisk

loaddisk:
	sti
	;Load remaining data from disk
	mov ax, 0x0240 ; command, sectors to read
	mov cx, 0x0002 ; track, sector
	xor dx, dx ; head
	; dl set to drive already
	mov es, dx
	mov ds, dx
	mov bx, 0x7E00

	int 0x13

; Go back to send the SIPI
	cli
	;load the gdt
	lgdt [gdt.pointer]

	;Actually enter protected mode
	mov eax, cr0
	or ax, 1
	mov cr0, eax

	;jump into protected mode code
	jmp gdt.code:sipi

[BITS 32]
sipi:
	mov ax, gdt.data
	mov ds, ax
	
	; Destination shorthand = All but self
	; Trigger Mode is ignored
	; Level = 1
	; Delivery status is ignored
	; Destination mode=Physical
	; Delivery Mode = Start Up
	; Vector = 0x08
	mov [0xFEE00300], dword 0x000C4608
	
	rdtsc
halt:
	hlt
	jmp halt


ALIGN 8
	;Global Descriptor Table
	gdt:
	dw 0x00 ; unused at the moment. Rest of null descriptor used for gdtr
	.pointer:
	dw .end-1 ; limit for gdt
	dd gdt ; pointer to gdt

	.code equ $ - gdt
	;Base = 0x0000
	;Granularity=No
	;Default operation size = 32-bit segment
	;64-bit segment=No
	;AVL=0 (unused)
	;Segment Limit = 0x0FFFF
	;Present=Yes
	;Privilege level=0
	;Descriptor type=code/data
	;Type=Execute/read, nonconforming, unaccessed
	dq 0x00409A000000FFFF

	.codereal equ $ - gdt
	;Base = 0x0000
	;Granularity=No
	;Default operation size = 16-bit segment
	;64-bit segment=No
	;AVL=0 (unused)
	;Segment Limit = 0x0FFFF
	;Present=Yes
	;Privilege level=0
	;Descriptor type=code/data
	;Type=Execute/read, nonconforming, unaccessed
	dq 0x00009A000000FFFF
	
	.data equ $ - gdt
	;Base = 0x0000
	;Granularity=Yes
	;Operation Size=32-bit
	;64-bit segment=No
	;AVL=0 (unused)
	;Segment Limit = 0xFFFFF
	;Present=Yes
	;Privilege level=0
	;Descriptor type=code/data
	;Type=Read/Write, expand-up, unaccessed
	dq 0x00CF92000000FFFF
	
	.end equ $ - gdt
	
TIMES 510-($-$$) db 0x90
dw 0xAA55
TIMES 512 db 0x90

[BITS 16]
; At 0x8000; AP starts here!
	mov ax, 0xb800
	mov ds, ax
	mov [0x0000], word 0x0F54

	cli
aphalt:
	hlt
	jmp aphalt