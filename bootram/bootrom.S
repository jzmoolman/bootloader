	.option norvc

.macro push reg
	addi sp,sp, -8
	sd \reg, (sp)
.endm

.macro pop reg
	ld \reg, (sp)
	addi sp,sp, 8
.endm

	.equ STACKSIZE, 512
	.equ DRAM_BASE, 0x80000000
	
	.section .data
msg:	.ascii "ZBootloader\0"
hart_msg:	.ascii "I am hart \0"
newline:	.ascii "\n\0"
machinemode:	 .ascii "Mode: Machine\0"
unknownmode:	 .ascii "Mode: Unknown\0"
interupt_enabled:	 .ascii "Intertupts: Enabled\0"
interupt_disabled:	 .ascii "Intertupts: Disabled\0"
	
scratchpad:
	.skip 8, 0
	
stack:
	.skip STACKSIZE, 0

	.section .text
reset:
	# Initialization 
	la sp, stack  		    # setting up stack
	addi sp, sp, STACKSIZE

	li a0, DRAM_BASE
	sd x0, (a0)

	csrr t0, mhartid
	bnez t0, 3f



1:
        li  a0, DRAM_BASE
	li a1, 0
	li a2, 1
	call _cas            
	bnez a0, 1b	      	 # !0 then try again, spin

	la a1, msg
	call _writeln
	call _sanity_check

2:
        li a0, DRAM_BASE
	li a1, 1
	li a2, 0
	call _cas            
	bnez a0, 2b	       # !0 then try again, spin
	
3:
	# call _announce		
	j _hang


_putchar_uart:
	li t0, 0x10000000        # Base Address fo UART
	li t1, 3 		 # Set to 8 bit
	sb t1, 3(t0)             # 3 offset  = Line Control register 
	li t1, 1 		 # Enable FIFO
	sb t1, 2(t0)             # 2 offset  = FIFO Contorl Register
	lb t1, (a1)
	sb t1, (t0)              # write to char to UART
	ret

_write_uart:
	push ra
1:	call _putchar_uart
	addi a1, a1, 1
	lb t1, (a1)
	bnez t1, 1b
	pop ra
	ret

_writeln:
        push ra
	call _write_uart
	la a1, newline
	call _write_uart
	pop ra
	ret

_announce:
	mv s5, ra                # save return address

1:
        li a0, DRAM_BASE
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
	
2:
        li a0, DRAM_BASE
	#lui  a0, %hi(DRAM_BASE)
	#addi a0, a0, %lo(DRAM_BASE)
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


	# Display inforation of hart
	
_sanity_check:
	push ra
	
	csrr t0, mstatus
	li t1, 3   		# 0000 0011
	slli t1, t1, 11         # set bit 11 and 12 (lsb  = 0)
	and t2, t1, t0
	xor t3,	 t2, t1

	bnez t2, 1f        	# branch if not machine mode
	la a1, machinemode
	call _writeln

	li t1, 1
	slli t1, t1, 3          # bit 3(lsb=0) is set if enterupts are enabled, otherwise 0  
	add t2, t1, t0
	xor t3, t2, t1
	bnez t2, 3f        	# branch if interupt is disabled 
	
	la a1, interupt_enabled
	call _writeln
	j 2f
3:
	la a1, interupt_disabled
	call _writeln
	j 2f
	
1:
	la a1, unknownmode
	call _writeln

2:
	pop ra
	ret
	

_hang:	

	wfi
