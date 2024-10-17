.align 2
.include "cfg.inc"
.equ UART_REG_TXFIFO,   0
.section .text
.globl _start

_start:


        csrr  tp, mhartid             # read hardware thread id (`hart` stands for `hardware thread`)
        bnez  tp, thread_startup      # all other threads besides the first one go to the wait loop to wait for work

        la    t0, trap_entry          # load the value of the trap entry address
        csrw  mtvec, t0               # set the trap entry location to our address

        la    a1, stack_top           # setup stack pointer for the first thread
        la    a2, thread_main         # set the code to run of our thread to thread_main
        li    a0, 0                   # set for thread id 0
        jal   set_thread

        la    a1, stack_top           # setup stack pointer for the second thread
        addi  a1, a1, 512             # offset into the stack pointer for the second thread
        la    a2, thread_main         # set the code to run of our thread to thread_main
        li    a0, 1                   # set for thread id 1
        jal   set_thread

        j done
        j     thread_startup


        #la    a0, msg                 # load address of `msg` to a0 argument register
        #jal   print_string                    # jump to `puts` subroutine, return address is stored in ra regster


        #la    t1, allocator
        #sd    x0, (t1)
main:
        #mv    a0, gp

        #jal   acquire_lock_w

        #la    a0, thread_pointer
        #jal   print_string
        #mv    a0, tp
        #jal   println_bin

        #mv    a0, gp
        #jal   release_lock_w

        #bnez  tp, done

thread_main:
        li    s5, 10
        #la    a0, sysout
        #jal   acquire_lock_d
        li    a0, 1
        slli  a0, a0, 62
        jal   println_int

        #la    a0, sysout
        #jal   release_lock_d



thread_main_loop:
        la    a0, sysout

        jal   acquire_lock_d
        la    a0, thread_pointer

        jal   print_string
        mv    a0, tp
        jal   println_int
        mv    a0, s5
        jal   println_int

        la    a0, sysout
        jal   release_lock_d

        addi  s5, s5, -1
        bnez  s5, thread_main_loop
        j done
main1:
        jal debug

        #jal alloc_memory
        #jal free_memory

        #la    t1, allocator
        #ld    a0, (t1)
        #li    a1, 1
        #jal print_int
        #jal register_dump


        #jal   alloc_list_node
        #mv    s1, a0 #save the list pointer to s1

        #li    a1, 0     #list length is 0
        #li    a2, 64     #item width is 8
        #jal   append_list_item
        #mv    s1, a0

        #jal   println_int
        #mv    a0, s1

        #li    t1, 1

        #jal println_bin
        #j debug

        #sd    t1, (a0) #write the value 1 to the returned write address


        #li    a1, 1     #list length is 1
        #li    a2, 64     #item width is 0
        #jal   append_list_item
        #mv    s1, a0

        #jal   println_int
        #mv    a0, s1
        #li    t1, 5
        #sd    t1, (a0)  #write the value 5 to the returned write address


        #li    a1, 0     #get item at index 0
        #li    a2, 8     #item width is 8 bytes
        #jal   get_list_item
        #ld    a0, (a0)
        #jal   println_int
        #mv    a0, s1

        #li    a1, 1     #get item at index 1
        #li    a2, 8     #item width is 8 bytes
        #jal get_list_item
        #ld    a0, (a0)
        #jal println_int




#        li    a4, 1
#        li    a5, 0
#        li    s4, 0
#        li    s5, 50
#fib:
#        beq   s5, s4, done
#        add   a6, a5, a4
#        addi  a4, a5, 0
#        addi  a5, a6, 0

#        addi  a0, a6, 0
#        la    sp, stack_top
#        jal print_int

#        addi  s4, s4, 1
#        j     fib                    # enter the infinite loop

done:   j     done


get_list_item:  #returns the index of the element int a0
                #a0 the linked list
                #a1 the item index
                #a2 the item width
        li    t1, 248
        div   t2, t1, a2              #the amount of items we can store in a node
get_list_item_loop:
        bge   a1, t2, get_list_item_0
        mul   a1, a1, a2
        add   a0, a0, a1
        addi  a0, a0, 8
        ret
get_list_item_0:
        sub   a1, a1, t2
        ld    a0, (a0)
        j     get_list_item_loop


append_list_item:  #returns in a0 the index to add the item
                #a0 the linked list
                #a1 the number of items
                #a2 the item width

        li    t1, 248
        div   t2, t1, a2              #the amount of items we can store in a node
append_list_item_loop:
        bge   a1, t2, append_list_item_0 #branch if a1 >= t2
        mul   a1, a1, a2
        add   a0, a0, a1
        addi  a0, a0, 8
        ret

append_list_item_0:
        ld    t3, (a0)
        bnez  t3, append_list_item_1
        #routine for allocating a new node
        sd    a0, (sp)
        sd    x1, 8(sp)
        addi  sp, sp, 16
        jal alloc_list_node
        addi  sp, sp, -16
        ld    t2, (sp)
        ld    x1, 8(sp)
        ld    a0, (t2)
        addi  a0, a0, 8
        jal println_int
        j    done
        ret

append_list_item_1:
        sub   a1, a1, t2
        ld    a0, (a0)
        j     append_list_item_loop



alloc_list_node:#allocates a linked list node
                #do not use t1, t2, t3 or t4
        sd    x1, (sp)
        addi  sp, sp, 8
        jal   alloc_memory
        sd    x0, (a0)
        addi  sp, sp, -8
        ld    x1, (sp)
        ret


#code I found on the internet
print_string:                                 # `puts` subroutine writes null-terminated string to UART (serial communication port)
                                      # input: a0 register specifies the starting address of a null-terminated string
                                      # clobbers: t0, t1, t2 temporary registers

        li    t0, UART_BASE           # t0 = UART_BASE
1:      lbu   t1, (a0)                # t1 = load unsigned byte from memory address specified by a0 register
        beqz  t1, 3f                  # break the loop, if loaded byte was null

                                      # wait until UART is ready
2:      lw    t2, UART_REG_TXFIFO(t0) # t2 = uart[UART_REG_TXFIFO]
        bltz  t2, 2b                  # t2 becomes positive once UART is ready for transmission
        sw    t1, UART_REG_TXFIFO(t0) # send byte, uart[UART_REG_TXFIFO] = t1

        addi  a0, a0, 1               # increment a0 address by 1 byte
        j     1b

3:      ret
#end of code I found on the internet


debug:
        la    a0, debug_msg           # load address of `msg` to a0 argument register
        jal   print_string
        ret







init_memory_2:
        la    t1, allocator2
        #li    t2, 0xFFFF
        #sd    t2, (t1)

        sd    x0, (t1)          #loc
        sd    x0, 8(t1)         #bitset

        sd    x0, 16(t1)        #loc
        sd    x0, 24(t1)        #bitset
        ret

alloc_memory_2: #allocates a block of memory of size a0, a0 must be a power of 2
        la    t1, allocator2
        li    t6, 0xFFFF
        li    t4, 0
        mv    t5, sp

alloc_memory_2_loop:
        beq   t6, a0, alloc_memory_2_allocation_found
        lw    t2, 12(t1)                #this bitset contains full entries in the table, so if its full we ignore it
        and   t2, t2, a1
        bnez  t2, alloc_memory_2_loop_1 #the bit will be set if its null which means this bit will be 1 if its full
        lw    t2, 8(t1)
        and   t2, t2, a1
        bnez  t2, alloc_memory_2_loop_2 #if we get to here and this bit is set that means a sub tree has our type and it isnt full
alloc_memory_2_loop_1:
        lw    t2, 28(t1)
        and   t2, t2, a1
        bnez  t2, alloc_memory_2_panic #if we somehow get here something very wrong has occured
        lw    t2, 24(t1)
        and   t2, t2, a1
        bnez  t2, alloc_memory_2_loop_3

alloc_memory_2_loop_2:
        ld    t1, (sp)
        addi  sp, sp, 8

        ld    t1, (t1)
        srli  t6, t6, 1
        j alloc_memory_2_loop
alloc_memory_2_loop_3:
        ld    t1, (sp)
        addi  sp, sp, 8

        ld    t1, 16(t1)
        add   t4, t4, t6
        srli  t6, t6, 1
        j alloc_memory_2_loop

alloc_memory_2_loop_4: #when we get here this signifies that we need to allocate a sub table for the type we are trying to get




alloc_memory_2_panic:
        la    a0, memory_panic
        jal   print_string
alloc_memory_2_panic_2:
        j     alloc_memory_2_panic_2


alloc_memory_2_allocation_found:
























alloc_memory: #allocates a 256 byte block of memory and places that address on a0, do not use t1, t2, t3 or t4
        la    t1, allocator     #address of beginning of regular ram
        ld    t2, (t1)          #t2 = value of address of t1
        li    t3, 1             #t3 = 1
        li    t4, 1             #t4 = 1

loop_alloc:
        and   t5, t2, t3        #t5 = t2 & t3
        beqz  t5, end_alloc     #if t5 == 0 goto end_alloc
        slli  t3, t3, 1         #t3 <<= 1
        addi  t4, t4, 1         #t4 += 1
        j     loop_alloc        #goto loop_alloc
end_alloc:
        or    t2, t2, t3        #t2 = t2 | t3
        sd    t2, (t1)          #address of t1 = t2
        li    t2, 256
        mul   t4, t4, t2       #t4 *= 256
        add   a0, t1, t4        #a0 = t1 + t4
        ret                     #return a0


free_memory: #frees the memory allocated at a0, do not use t1, t2, t3
        la    t1, allocator     #address of beginning of regular ram
        sub   a0, a0, t1
        srli  a0, a0, 8         #a0 >> 8
        addi  a0, a0, -1        #the memory at the 0th index starts at 1 so we decrement it
        li    t3, 1             #t3 = 1
        sll   t3, t3, a0        #t3 <<= a0

        addi a0, t3, 0
        not   t3, t3            #t3 ~= t1

        ld    t2, (t1)          #t2 = value of address of t1
        and   t2, t2, t3        #t2 = t2 & t3
        sd    t2, (t1)          #address of t1 = t2
        ret

println_bin:
        li   t1, 0x80000000
        li   t0, UART_BASE
println_bin_loop:
        and  t2, a0, t1
        beqz t2, println_bin_zero
        li   t4, 49                             #ascii code for 1
        j    println_bin_wait_for_uart
println_bin_zero:
        li   t4, 48                             #ascii code for 0
println_bin_wait_for_uart:
        lw    t3, UART_REG_TXFIFO(t0)           # t2 = uart[UART_REG_TXFIFO]
        bltz  t3, println_bin_wait_for_uart     # t2 becomes positive once UART is ready for transmission
        sw    t4, UART_REG_TXFIFO(t0)
println_bin_skip:
        srli t1, t1, 1
        bnez t1, println_bin_loop
println_bin_wait_for_uart1:
        lw    t3, UART_REG_TXFIFO(t0)           # t2 = uart[UART_REG_TXFIFO]
        bltz  t3, println_bin_wait_for_uart1     # t2 becomes positive once UART is ready for transmission
        li    t4, 10
        sw    t4, UART_REG_TXFIFO(t0)
        ret


println_int:
        sd    x1, (sp)
        sd    a1, 8(sp)
        li    a1, 1
        addi  sp, sp, 16
        jal   print_int
        addi  sp, sp, -16
        ld    x1, (sp)
        ld    a1, 8(sp)
        ret


print_int: #prints the integer located at a0, if a1 is 0 then a newline is not included
           #do not use t1, t2, t3, t4, and t6
        sd    x1, (sp)
        addi  sp, sp, 8

        li    t6, 0             #sets the t6 flag to 0 initially
        addi  a2, a0, 0
        bgez  a0, print_int_over#goes to 1 if a0 is greater than 0
        li    t6, 1             #sets the t6 flag to 1 if the number is negative
        neg   a2, a0            #makes a0 positive and sets it to a2
print_int_over:
        jal   alloc_memory      #allocate a block of memory and put it on a0
        li    t1, 1             #our global 1 number
        li    t2, 10            #our global 10 number
        addi  a0, a0, 255       #adds 255 to the memory address which is the end of our allocated block
        sb    x0, (a0)          #sets the value of our memory address at a0 to 0
        beqz  a1, print_int_skip
        sub   a0, a0, t1        #decrements our mem address by 1
        sb    t2, (a0)          #adds a newline
print_int_skip:
        sub   a0, a0, t1        #decrements our mem address by 1
        beqz  a2, print_int_zero#check if our number is initially 0 and if so go to the zero handling section
print_int_loop:
        beqz  a2, print_int_out #if our number is 0 jump out

        div   t3, a2, t2        #t3 = a2 / 10
        mul   t4, t3, t2        #t4 = t3 * 10
        sub   t4, a2, t4        #t4 = a2 - t4 last 3 instructions are to get modulo into t4
        addi  a2, t3, 0         #a2 = t3
        addi  t4, t4, 48        #add ascii value 48 to t4
        sb    t4, (a0)          #set our memory address to t4
        sub   a0, a0, t1        #decrement out memory address by 1
        j     print_int_loop
print_int_zero:
        li    t2, 48
        sb    t2, (a0)          #set the byte to 0
        sub   a0, a0, t1        #decrement out memory address by 1
print_int_out:
        beqz  t6, print_int_skip_neg
        li    t2, 45            #loads the - sign
        sb    t2, (a0)          #sets the memory
        sub   a0, a0, t1        #decrement out memory address by 1
print_int_skip_neg:
        addi  a0, a0, 1         #increment out memory address by 1
        jal   print_string
        jal   free_memory

        addi  sp, sp, -8
        ld    x1, (sp)
        ret

register_dump: #prints the value of each register excluding x0
        sd    x1, (sp)   #-72
        sd    a0, 8(sp)  #-64
        sd    a1, 16(sp) #-56
        sd    a2, 24(sp) #-48
        sd    t1, 32(sp) #-40
        sd    t2, 40(sp) #-32
        sd    t3, 48(sp) #-24
        sd    t4, 56(sp) #-16
        sd    t6, 64(sp) #-8
        addi  sp, sp, 72

        li    a1, 1

        la    a0, .ra
        jal   print_string
        lw    a0, -72(sp)
        jal   print_int

        la    a0, .sp
        jal   print_string
        addi  a0, sp, -76       #-40 to account for what it was before calling this
        jal   print_int

        la    a0, .gp
        jal   print_string
        addi  a0, gp, 0
        jal   print_int

        la    a0, .tp
        jal   print_string
        addi  a0, tp, 0
        jal   print_int

        la    a0, .t
        li    a1, 0
        addi  a2, t0, 1
        jal   register_dump_numeric

        la    a0, .t
        li    a1, 1
        ld    a2, -40(sp)
        jal   register_dump_numeric

        la    a0, .t
        li    a1, 2
        ld    a2, -32(sp)
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 0
        addi  a2, s0, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 1
        addi  a2, s1, 0
        jal   register_dump_numeric

        la    a0, .a
        li    a1, 0
        ld    a2, -64(sp)
        jal   register_dump_numeric

        la    a0, .a
        li    a1, 1
        ld    a2, -56(sp)
        jal   register_dump_numeric

        la    a0, .a
        li    a1, 2
        ld    a2, -48(sp)
        jal   register_dump_numeric

        la    a0, .a
        li    a1, 3
        addi  a2, a3, 0
        jal   register_dump_numeric

        la    a0, .a
        li    a1, 4
        addi  a2, a4, 0
        jal   register_dump_numeric

        la    a0, .a
        li    a1, 5
        addi  a2, a5, 0
        jal   register_dump_numeric

        la    a0, .a
        li    a1, 6
        addi  a2, a6, 0
        jal   register_dump_numeric

        la    a0, .a
        li    a1, 7
        addi  a2, a7, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 2
        addi  a2, s2, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 3
        addi  a2, s3, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 4
        addi  a2, s4, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 5
        addi  a2, s5, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 6
        addi  a2, s6, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 7
        addi  a2, s7, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 8
        addi  a2, s8, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 9
        addi  a2, s9, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 10
        addi  a2, s10, 0
        jal   register_dump_numeric

        la    a0, .s
        li    a1, 11
        addi  a2, s11, 0
        jal   register_dump_numeric

        la    a0, .t
        li    a1, 3
        ld    a2, -24(sp)
        jal   register_dump_numeric

        la    a0, .t
        li    a1, 4
        ld    a2, -16(sp)
        jal   register_dump_numeric

        la    a0, .t
        li    a1, 5
        addi  a2, t5, 0
        jal   register_dump_numeric

        la    a0, .t
        li    a1, 6
        ld    a2, -8(sp)
        jal   register_dump_numeric


        addi  sp, sp, -72
        ret


register_dump_numeric: #a0 first string a1 second string a2 numeric value
        sd    a1, (sp)
        sd    a2, 8(sp)
        sd    ra, 16(sp)
        addi  sp, sp, 24

        jal   print_string
        li    a1, 0
        ld    a0, -24(sp)
        jal   print_int
        la    a0, .extra
        jal   print_string
        li    a1, 1
        ld    a0, -16(sp)
        jal   print_int
        addi  sp, sp, -24
        ld    ra, 16(sp)
        ret

store_registers:
        addi  sp, sp, 240
        sd    x2,  -240(sp)
        sd    x3,  -232(sp)
        sd    x4,  -224(sp)
        sd    x5,  -216(sp)
        sd    x6,  -208(sp)
        sd    x7,  -200(sp)
        sd    x8,  -192(sp)
        sd    x9,  -184(sp)
        sd    x10, -176(sp)
        sd    x11, -168(sp)
        sd    x12, -160(sp)
        sd    x13, -152(sp)
        sd    x14, -144(sp)
        sd    x15, -136(sp)
        sd    x16, -128(sp)
        sd    x17, -120(sp)
        sd    x18, -112(sp)
        sd    x19, -104(sp)
        sd    x20,  -96(sp)
        sd    x21,  -88(sp)
        sd    x22,  -80(sp)
        sd    x23,  -72(sp)
        sd    x24,  -64(sp)
        sd    x25,  -56(sp)
        sd    x26,  -48(sp)
        sd    x27,  -40(sp)
        sd    x28,  -32(sp)
        sd    x29,  -24(sp)
        sd    x30,  -16(sp)
        sd    x31,   -8(sp)
        ret


load_registers:
        ld    x2,  -240(sp)
        ld    x3,  -232(sp)
        ld    x4,  -224(sp)
        ld    x5,  -216(sp)
        ld    x6,  -208(sp)
        ld    x7,  -200(sp)
        ld    x8,  -192(sp)
        ld    x9,  -184(sp)
        ld    x10, -176(sp)
        ld    x11, -168(sp)
        ld    x12, -160(sp)
        ld    x13, -152(sp)
        ld    x14, -144(sp)
        ld    x15, -136(sp)
        ld    x16, -128(sp)
        ld    x17, -120(sp)
        ld    x18, -112(sp)
        ld    x19, -104(sp)
        ld    x20,  -96(sp)
        ld    x21,  -88(sp)
        ld    x22,  -80(sp)
        ld    x23,  -72(sp)
        ld    x24,  -64(sp)
        ld    x25,  -56(sp)
        ld    x26,  -48(sp)
        ld    x27,  -40(sp)
        ld    x28,  -32(sp)
        ld    x29,  -24(sp)
        ld    x30,  -16(sp)
        ld    x31,   -8(sp)
        addi  sp, sp, -240
        ret


trap_entry:
        sd    x1, (sp)
        addi  sp, sp, 8
        jal   store_registers

        csrr  s1, mcause

        li    t1, 0x80000000
        and   t2, t1, s1
        not   t1, t1
        and   s1, s1, t1


        beqz  t2, trap_entry_sync

trap_entry_async:
        li    t2, 7
        beq   t2, s1, async_trap_mtimer
        li    t2, 1
        beq   t2, s1, async_trap_ssi
        li    t2, 5
        beq   t2, s1, async_trap_stimer

        la    a0, async_trap
        jal   print_string
        mv    a0, s1
        jal   println_int

        jal   load_registers
        addi  sp, sp, -8
        ld    x1, (sp)
        j     trap_internal

async_trap_mtimer:
        la    a0, timer_trap
        jal   print_string

        la    t1, 0x0204000 #next time
        la    t2, 0x020bff8 #current time
        ld    t3, (t2)
        li    t2, 10000000
        add   t3, t3, t2 #1 second in the future
        sd    t3, (t1)


        li    t1, 128  #supervisor timer bit, stip
        csrc  mip, t1

        jal   load_registers
        addi  sp, sp, -8
        ld    x1, (sp)
        #csrr  t0, mtinst
        #jalr  x0, t0, 0
        mret

async_trap_stimer:
        la    a0, stimer_trap
        jal   print_string

        li    t1, 32  #supervisor timer bit, stip
        csrc  mie, t1
        csrc  mip, t1


        jal   load_registers
        addi  sp, sp, -8
        ld    x1, (sp)
        #j     trap_internal
        mret

async_trap_ssi: #supervisor software interrupt
        li    t1, 2 #we want to clear bit 2 in the sip register, ssip
        csrc  mip, t1

        la    a0, ssi_trap
        jal   print_string

        jal   load_registers
        addi  sp, sp, -8
        ld    x1, (sp)
        mret

trap_entry_sync:
        la    a0, trap_line
        jal   print_string
        mv    a0, s1
        jal   println_bin
        #jal   load_registers
        li    t2, 7
        bne   t2, s1, trap_entry_1

        #csrr  a0, mtinst


        la    a0, memory_trap
        jal   print_string
        csrr  a0, mtval
        jal   println_int
        j     trap_internal

trap_entry_1:
        la    a0, trap
        jal   print_string
        mv    s1, a0
        jal   println_int

trap_internal:
        j     trap_internal

trap_1:
        la    a0, msg
        jal   print_string
trap_2:
        j trap_2


acquire_lock_w: # aquires the lock at memory location a0
        li    t2, 1
        lr.w  t1, (a0)
        bne   t1, x0, acquire_lock_w
        sc.w  t1, t2, (a0)
        bnez  t1, acquire_lock_w
        ret

release_lock_w: #unlocks the lock at memory location a0
                #do not use t1, t2
        li    t1, 0
        sw    t1, (a0)

acquire_lock_d: # aquires the lock at memory location a0
        li    t2, 1
        lr.d  t1, (a0)
        bne   t1, x0, acquire_lock_d
        sc.d  t1, t2, (a0)
        bnez  t1, acquire_lock_d
        ret

release_lock_d: #unlocks the lock at memory location a0
        li    t1, 0
        sd    t1, (a0)


try_acquire_lock_d:
        li    t2, 1
        lr.d  t1, (a0)
        bne   t1, x0, try_acquire_lock_d_fail
        sc.d  a1, t2, (a0)
        ret
try_acquire_lock_d_fail:
        li    a1, 1
        ret


# a0 holds address of memory location
# a1 holds expected value
# a2 holds desired value
# a0 holds return value, 0 if successful, !0 otherwise
cas:
        lr.w  t0, (a0)           # Load original value.
        bne   t0, a1, cas_fail        # Doesn’t match, so fail.
        sc.w  a0, a2, (a0)       # Try to update.
        ret
cas_fail:
        li    a0, 1                # Set return to failure.
        ret


thread_startup: #initlizes thread a0 to run work placed into the thread pointer pool
        la    t1, thread_pointers
        li    t2, 16
        mul   a0, a0, t2
        add   t1, t1, t2

thread_startup_loop:
        ld    ra, 8(t1)
        beqz  ra, thread_startup_loop
        ld    sp, (t1)
        beqz  sp, thread_startup_loop
        ret


set_thread:     #sets the thread a0 to stack pointer a1 and ra a2
        la    t1, thread_pointers
        li    t2, 16
        mul   a0, a0, t2
        add   t1, t1, t2

        sd    a1, (t1)
        sd    a2, 8(t1)
        ret


create_virtual_thread: #creates a virtual thread with the stack pointer a1 and ra a2 and places the virtual thread id on a0
        addi  sp, sp, 8
        sd    ra, -8(sp)
        la    a0, virtual_thread_space
        addi  a0, a0, 16                        #offset to the lock position
        li    t4, 0
create_virtual_thread_loop:
        jal   try_acquire_lock_d                #acquire the lock at the index a0
        bnez  a1, create_virtual_thread_loop_skip #if the result is not 1 that means we failed and something is holding the lock
        ld    t1, -16(a0)                       #load the first double of the entry which is the stack poiunter
        beqz  t1, create_virtual_thread_found   #if the entry is zero that means its empty and we can put something there
        jal   release_lock_d
create_virtual_thread_loop_skip:
        addi  t4, t4, 1
        addi  a0, a0, 24
        li    t2, 31
        bne   t4, t2, create_virtual_thread_loop
                        #routine for if no space is found
        li    a0, -1
        ld    ra, -8(sp)
        addi  sp, sp, -8
        ret             #if no space is found we return -1

create_virtual_thread_found:
        sd    a1, -16(a0)
        sd    a2, -8(a1)
        jal   release_lock_d
        mv    a0, t4
        ld    ra, -8(sp)
        addi  sp, sp, -8
        ret

destroy_virtual_thread:
        #deletes the virtual thread in the gp register
        addi  sp, sp, 8
        sd    ra, -8(sp)

        la    a0, virtual_thread_space  #math for getting the address of the lock
        li    t2, 24
        mul   t2, t2, gp
        addi  t2, t2, 16
        add   a0, a0, t2

        sd    x0, -16(a0)               #set the stack pointer and address for the specific virtual thread to 0
        sd    x0, -8(a0)
        jal   release_lock_d            #release the lock

        ld    ra, -8(sp)
        addi  sp, sp, -8
        ret

find_and_execute_virtual_thread:
        la    a0, virtual_thread_space
        addi  a0, a0, 16
        li    t4, 0
find_and_execute_virtual_thread_loop:
        jal   try_acquire_lock_d
        bnez  a1, find_and_execute_virtual_thread_skip
        ld    t1, -16(a0)                               #load the first double of the entry which is the stack poiunter
        beqz  t1, find_and_execute_virtual_thread_found #if the entry is zero that means its empty and we can put something there
        jal   release_lock_d
find_and_execute_virtual_thread_skip:
        addi  t4, t4, 1
        addi  a0, a0, 24
        li    t2, 31
        bne   t4, t2, find_and_execute_virtual_thread_loop
                        #if we didnt find anything we just go back to the top and keep looping until something else gets added
        j     find_and_execute_virtual_thread

find_and_execute_virtual_thread_found:
        ld    sp, -16(a0)
        jal   load_registers
        ld    ra, -8(a0)
        ret


.align 8
.section .data
sysout:
     .space 8
thread_pointers:
     .space 32
virtual_thread_space: # 3 bytes per thread, the stack pointer, ra and the lock double
                      # 32 entries
     .space 1536

.section .rodata
msg:
     .string "Fib Sequence:\n"
debug_msg:
     .string "Debug Message\n"

memory_panic:
     .string "Memory Panic\n"

ssi_trap:
     .string "Software interrupt trap:\n"

timer_trap:
     .string "Timer Trap\n"

stimer_trap:
     .string "Software Timer Trap\n"

async_trap:
     .string "Async Trap:"

trap_line:
     .string "Trap Line:"

trap:
     .string "Trap Code:"

memory_trap:
     .string "Invalid Memory Write Address:"
thread_pointer:
     .string "Thread pointer:"

.extra:
     .string ": "
.ra:
     .string "ra: "
.sp:
     .string "sp: "
.gp:
     .string "gp: "
.tp:
     .string "tp: "
.t:
     .string "t"
.s:
     .string "s"
.a:
     .string "a"
