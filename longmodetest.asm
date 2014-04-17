[ORG 0x00007C00]
[BITS 16]
 
	;Build page tables
	;The page tables will look like this:
	;PML4:
	;dq 0x000000000000200f = 00000000 00000000 00000000 00000000 00000000 00000000 00100000 00001111
	;times 511 dq 0x0000000000000000
 
	;PDP:
	;dq 0x000000000000300f = 00000000 00000000 00000000 00000000 00000000 00000000 00110000 00001111
	;times 511 dq 0x0000000000000000
 
	;PD:
	;dq 0x000000000000018f = 00000000 00000000 00000000 00000000 00000000 00000000 00000001 10001111
	;times 511 dq 0x0000000000000000
 
	;This defines one 2MB page at the start of memory, so we can access the first 2MBs as if paging was disabled
 
	; build the necessary tables
	xor eax,eax
	
	mov [0x1000],dword 0x0000200f
	mov [0x1004],eax
	mov [0x2000],dword 0x0000300f
	mov [0x2004],eax
	mov [0x3000],dword 0x0000018f
	mov [0x3004],eax

	; Virtual interrupt flag in virtual-8086 mode:	off
	; Virtual interrupt flag in protected mode: 	off
	; Timestamp disable:							off
	; Debugging Extensions:							off
	; Page Size Extension:							off (?)
	; Physical address extension:					on
	; Machine check exception:						off (?)
	; Page global enabled:							on
	; Performance-monitoring counter enable:		on
	; OS Support for FXSAVE/FXSTOR instructions		on
	; OS Support for unmasked SIMD FP Exceptions	off
	; 2 reserved bits
	; VMX-Enable									off
	; SMX-Enable									off
	; 1 reserved bit
	; FSGSBASE-Enable								on
	; PCID-Enable									off (can't turn on until 64 bit on)
	; XSAVE and processor extended states-enable	on
	; 1 reserved bit
	; SMEP-Enable									off
	mov ebx,0x000503A0
	mov cr4,ebx
 
	; Page-level write-through						off (?)
	; Page-level cache disable						off (?)
	mov esi,0x00001000				;Point CR3 at PML4
	mov cr3,esi
 
	mov ecx,0xC0000080				;Specify EFER MSR
 
	rdmsr						;Enable Long Mode
	; Execute Disable Bit Enable					off
	; IA-32e mode active							off
	; IA-32e mode enable							on
	; SYSCALL enable								on
	or ax,0x00000101
	wrmsr
	
	; Activate long mode by enablng paging and protection simultaneously, skipping protected mode
	mov edx,cr0
	; Protection enable								on
	; Monitor coprocessor							on
	; Emulation [of x87 proc]						off
	; Task switched									off
	; Extension Type								on
	; Numeric Error									on  (?)
	; Write protect									off
	; Alignment mask								off
	; Not Write-through								off
	; Cache Disable									off
	; Paging										on
	or edx,0x80000033
	mov cr0,edx

	lgdt [gdt.pointer]				;load 80-bit gdt.pointer below

	jmp gdt.code:startLongMode			;Load CS with 64 bit segment and flush the instruction cache
 
	;Global Descriptor Table
	gdt:
	dq 0x0000000000000000				;Null Descriptor
 
	.code equ $ - gdt
	dq 0x0020980000000000
 
	.data equ $ - gdt
	dq 0x0000900000000000						 

	.pointer:
	dw $-gdt-1					;16-bit Size (Limit)
	dq gdt						;64-bit Base Address
	 
[BITS 64]
	 
startLongMode:
	mov rax,0x0F540F530F450F54
	mov [0xb8000],rax

; halt as we are basically done now
halt:
	cli
	hlt
	jmp halt

TIMES 510-($-$$) db 0x00

dw 0x55AA