	.option norvc

	.section .data
msg:	.ascii "ZBootloader\0"
hart_msg:	.ascii "I am hart \0"
newline:	.ascii "\n\0"
	.balign 8
hartlock:	.dword 0
scratchpad:
	.skip 512
	
	.section .text

reset:
	csrr t0, mhartid
	bnez t0, 3f

1:
	la a0, hartlock
	li a1, 0
	li a2, 1
	call _cas            
	bnez a0, 1b	       # !0 then try again, spin

	la a1, msg
	call _writeln

2:
	la a0, hartlock
	li a1, 1
	li a2, 0
	call _cas            
	bnez a0, 2b	       # !0 then try again, spin
	
3:
	call _announce
	j _hang


_putchar_uart:
	mv s4, ra                # save return address
	li t0, 0x10000000        # Base Address fo UART
	li t1, 3 		 # Set to 8 bit
	sb t1, 3(t0)             # 3 offset  = Line Control register 
	li t1, 1 		 # Enable FIFO
	sb t1, 2(t0)             # 2 offset  = FIFO Contorl Register
	lb t1, (a1)
	sb t1, (t0)              # write to char to UART
	mv ra, s4                # restore return address
	ret

_write_uart:
	mv s3, ra                # save return address
1:	call _putchar_uart
	addi a1, a1, 1
	lb t1, (a1)
	bnez t1, 1b 
	mv ra, s3                # restore return address
	ret

_writeln:
	mv s2, ra                # save return address
	call _write_uart
	la a1, newline
	call _write_uart
	mv ra, s2                # restore return address
	ret

_announce:
	mv s5, ra                # save return address

1:
	la a0, hartlock
	li a1, 0
	li a2, 1

	call _cas            
	bnez a0, 1b	       # !0 then try again, spin

	# enter critial section
	
	la a1, hart_msg
	call _write_uart

	la a1, scratchpad
	li t1, 0x30
	csrr t0, mhartid
	add t1, t1, t0
	sb t1, (a1)  		# HART ID
	sb x0, 1(a1) 		# NULL 
	call _writeln

	#exit critical section, not sure what is the most effect way
	
2:	la a0, hartlock
	li a1, 1
	li a2, 0

	call _cas            
	bnez a0, 2b       	# !0 then try again

	mv ra, s5                # restore return address
	ret

	# from specifications
	# a0 holds address of memory location
	# a1 holds expected value
	# a2 holds the desired value
	# a0 holds the return value, 0 if sucess, !0 otherwise
_cas:
	lr.d t0, (a0)   	# Load original value
	bne t0, a1, 1f  	# Doesn't match fail
	sc.d t0, a2, (a0)       # try to update
	bnez t0, _cas           # retry if failed
	li a0, 0		# set to success
	ret			# return
	
1:	li a0, 1        	# set to fail
	ret			# return

_hang:	

	wfi
