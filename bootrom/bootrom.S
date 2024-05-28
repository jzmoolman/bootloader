
#define DRAM_BASE 0x80000000

.section .text.start, "ax", @progbits
.globl _start
_start:
	#csrwi 0x7c1, 0 // disable chicken bits
	#li s0, DRAM_BASE
	csrr a0, mhartid
	bnez a0, _hang

1:
	la a0, msg
	call _write_uart
	la a0, msg
	call _write_uart
	j 1b


.section .text.hang, "ax", @progbits
.globl _hang
_hang:
  #csrwi 0x7c1, 0 // disable chicken bits
  #csrr a0, mhartid
  #la a1, _dtb
	csrwi mie, 0
	la a0, msg1
	call _write_uart
1:
  wfi
  j 1b

	.section .text.uart, "ax", @progbits
	.globl _uart
	
_putchar_uart:
	li t0, 0x10000000        # Base Address fo UART
	li t1, 3 		 # Set to 8 bit
	sb t1, 3(t0)             # 3 offset  = Line Control register 
	li t1, 1 		 # Enable FIFO
	sb t1, 2(t0)             # 2 offset  = FIFO Contol Register
	lb t1, (a0)
	sb t1, (t0)              # write to char to UART
	ret

_write_uart:
	mv s0, ra
1:
	call _putchar_uart
	addi a0, a0, 1
	lb t1, (a0)
	bnez t1, 1b

	mv  ra, s0
	ret
	
.section .rodata.dtb, "a", @progbits
.globl _dtb
_dtb:
msg:	.ascii "ZBootloader\n\0"
msg1: 	.ascii "Reset\n\0"
