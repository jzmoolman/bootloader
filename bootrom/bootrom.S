
.equ DRAM_BASE, 0x80000000
#.equ UART_BASE, 0x10000000
.equ UART_BASE, 0x60010000

.equ UART_RBR, 0x00         # RBR: Receiver buffer register [Read, LCR[6] == 0]
.equ UART_THR, 0x00         # THR: Transmitter Holding register [Write, LCR[6] == 0]
.equ UART_IER, 0x01         # IER: Interupt Enable Register [Read/Write, LCR[7] == 0]
.equ UART_FCR, 0x02         # FCR: FIFO control
.equ UART_LCR, 0x03         # LCR: Line Conrol register [read/write]
.equ UART_MCR, 0x04         # Modem
.equ UART_LSR, 0x05         # LSR: Line Status Register [read/write] 
.equ UART_SCR, 0x07         # Scratch
.equ UART_DLL, 0x00         # DDL: Divisor latch(lsb) [read/write] 
.equ UART_DLM, 0x01         # DLM: Divosor latch(msb) [read/write]


.section .text.start, "ax", @progbits
.globl _start
_start:
	#csrwi 0x7c1, 0 // disable chicken bits
	#li s0, DRAM_BASE
	csrr a0, mhartid
	bnez a0, _hang

	li a0, UART_BASE
	call  _init_uart
1:
	li a0, UART_BASE
	la a1, msg
	call _write_uart
	j 1b


.section .text.hang, "ax", @progbits
.globl _hang
_hang:
  #csrwi 0x7c1, 0 // disable chicken bits
  #csrr a0, mhartid
  #la a1, _dtb
	csrwi mie, 0
	li a0, UART_BASE
	li a2, 65
	call _putchar_uart
	#la a1, msg
	#call _write_uart
1:
  wfi
  j 1b

	.section .text.uart, "ax", @progbits
	.globl _uart

	# a0 UART Base adress
_init_uart:
	# IRQ
	li t0, 0x00              # Disable interupt
	sb t0, UART_IER(a0)

	// set 0x0080 to UART.LCR to enable DLL and DLM write
	# configure baud rate (DLAB)
        # divisor = clk_freq / (16 * Baud)
	# DLL = clock freq / (16 * baudrate) % 0x100
	# 100MHz and 115200 = 54 = 0x36
	# DLM = clock freq / (16*baudrate) >> 8
	# 100MHz and 115200 = 0
	li t0, 0x80
	sb t0, UART_LCR(a0) 	# Enable DLL  & DLM write

	li t0, 0x36 
	sb t0, UART_DLL(a0)
	sb x0, UART_DLM(a0)


        # 8-bit data, 1-bit odd parity
	#li t0, 0x0b         	# 0x0b for 8 bit data, 1 stop bit, odd parity
	li t0, 0x03         	# 0x03 for 8 bit data, 1 stop bit, no parity
	sb t0, UART_LCR(a0)

	li t0, 0x01         	# Enable FIFI
	sb t0, UART_FCR(a0)

	li t0, 0x00
	sb t0, UART_MCR(a0)     # No modem control
 
	lb t0, UART_LCR(a0)    # Clear line status

	lb t0, UART_RBR(a0)    # Read buffer

	li t0, 0x00
	sb t0, UART_SCR(a0)    # set scratchpad
	
	
	ret

	
	# a0 UART_BASE address
	# a2 char to send
_putchar_uart:
1:	lb t0, UART_LSR(a0)
	andi t0, t0, 0x40    # 6 bit
	beqz t0, 1b
	sb a2, UART_THR(a0)
	ret

	# a0 UART BASE Address
	# a1 Address of string 
_write_uart:
	mv s0, ra

1:	lb a2, (a1)
	beqz a2, 2f         #  value at a1 = \0  jump ret
	call _putchar_uart
	addi a1, a1, 1
	j 1b

2:	mv  ra, s0
	ret
	
.section .rodata.dtb, "a", @progbits
.globl _dtb
_dtb:
msg:	.ascii "ZBootloader\n\0"
msg1: 	.ascii "Reset\n\0"
