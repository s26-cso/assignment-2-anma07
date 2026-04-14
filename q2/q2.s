.section .data
newline: .string "\n"               # newline string 
space: .string " "                  # space string
minus_one: .string "-1"             # for default answer
.section .text
.globl main                    

main:                               # a0 = argc(number of arguments) & a1 = argv(pointer to array)
    addi sp, sp, -64                # make space in stack
    sd ra, 56(sp)                   # save return address on stack
    sd s0, 48(sp)                   # save register s0 (argc)
    sd s1, 40(sp)                   # save register s1 (argv)
    sd s2, 32(sp)                   # save register s2 (n)
    sd s3, 24(sp)                   # save register s3 (result array pointer)
    sd s4, 16(sp)                   # save register s4 (array pointer)
    sd s5, 8(sp)                    # save register s5 (stack base pointer)
    sd s6, 0(sp)                    # save register s6 (stack top index)

    mv s0, a0                       # s0 = argc (total arg count including program name)
    mv s1, a1                       # s1 = argv base pointer

    addi s2, s0, -1                 # s2 = n = number of array elements

    beqz s2, end                    # if n == 0, nothing to do, go to end loop

    slli a0, s2, 3                  # a0 = n * 8 (bytes needed for result[])
    call malloc                     # allocate heap memory for result array
    mv s3, a0                       # s3 = pointer to result[] array

    li t0, 0                        # t0 = loop index i = 0

loop:
    bge t0, s2, allocate            # if i >= n, done initialising
    slli t1, t0, 3                  # t1 = i * 8 (byte offset)
    add t2, s3, t1                  # t2 = &result[i]
    li t3, -1                       # t3 = -1
    sd t3, 0(t2)                    # result[i] = -1
    addi t0, t0, 1                  # i++
    j loop                          # repeat

allocate:
    slli a0, s2, 3                  # a0 = n * 8 bytes (allocate memory to result array)
    call malloc                     # allocate memory for arr[]
    mv s4, a0                       # s4 = pointer to arr[] (parsed integers)

    li s6, 0                        # Use s6 for loop index i (safe across atoll)

loop2:
    bge  s6, s2, done               # if i >= n, done parsing
    addi t2, s6, 1                  # t2 = i + 1  (argv[0] is program name, so shift by 1)
    slli t3, t2, 3                  # t3 = (i+1) * 8 (byte offset into argv)
    add t4, s1, t3                  # t4 = &argv[i+1]
    ld a0, 0(t4)                    # a0 = argv[i+1]  (char* pointer to the string)
    call atoll                      # convert string to integer; result in a0
    slli t1, s6, 3                  # t1 = i * 8
    add t5, s4, t1                  # t5 = &arr[i]
    sd a0, 0(t5)                    # arr[i] = parsed integer
    addi s6, s6, 1                  # s6 = s6 + 1 (i++)
    j loop2                         # repeat

done:
    slli a0, s2, 3                  # a0 = n * 8 bytes
    call malloc                     # allocate heap memory for stack[]
    mv   s5, a0                     # s5 = pointer to stack[] (index stack)
    li   s6, -1                     # s6 = stack top index (-1 means empty)

    addi t0, s2, -1                 # t0 = i = n - 1  (start at rightmost element)
loop3:
    bltz t0, startprint             # if i < 0, done

    slli t2, t0, 3                  # t2 = i * 8
    add  t3, s4, t2                 # t3 = pointer to current ith element of arr
    ld   t1, 0(t3)                  # t1 = arr[i]

pop_loop:
    bltz s6, pop_done               # if stack is empty (top == -1), stop popping
    slli t4, s6, 3                  # t4 = top * 8
    add t5, s5, t4                  # t5 = &stack[top]
    ld t6, 0(t5)                    # t6 = stack.top()
    slli t4, t6, 3                  # t4 = stack.top() * 8
    add t4, s4, t4                  # t4 = &arr[stack.top()]
    ld t4, 0(t4)                    # t4 = arr[stack.top()]
    bgt t4, t1, pop_done            # if arr[stack.top()] > arr[i], stop popping
    addi s6, s6, -1                 # pop: top--
    j pop_loop                      # continue popping

pop_done:                           # if stack is not empty, result[i] = stack.top()
    bltz s6, pushi                  # if stack empty, skip 
    slli t4, s6, 3                  
    add t5, s5, t4                 
    ld t6, 0(t5)                    # t6 = stack.top() (index of next greater)
    slli t4, t0, 3                  
    add t5, s3, t4                 
    sd t6, 0(t5)                    # result[i] = stack.top()

pushi:                              # push i onto stack
    addi s6, s6, 1                  # top++
    slli t4, s6, 3                  
    add  t5, s5, t4                 
    sd t0, 0(t5)                    # stack[top] = i

    addi t0, t0, -1                 # t0 = t0 - 1 (i--)
    j loop3                         # go to next loop

startprint:
    li s6, 0                       # Use s6 for loop index i 

printloop:
    bge s6, s2, printdone          # if s6>=n(i>=n), go to print done function
    slli t1, s6, 3                  
    add t2, s3, t1                 
    ld s0, 0(t2)                   # Use s0 to hold result[i] value (safe across printf)

    beqz s6, nospace               # if s6==0(i == 0), skip space
    la a0, space                   # a0 = pointer to " "
    call printf                    # print space

nospace:                           # if result[i] == -1, print the string "-1" or else print the integer
    li   t4, -1                     
    beq  s0, t4, printdefault      # if result[i] == -1, branch

    la a0, fmt_int                 # a0 = format string pointer "%ld"
    mv a1, s0                      # a1 = the integer value
    call printf                    # print the integer
    j printnext                    # jump to printnext

printdefault:
    la a0, minus_one               # a0 = "-1" string pointer
    call printf                    # print "-1"
    j printnext

printnext:
    addi s6, s6, 1                  # s6 = s6 + 1 (i++)
    j printloop                     # next element

printdone:
    la a0, fmt_newline              # a0 = "\n" format string
    call printf                     # print newline

end:
    li a0, 0                        # a0 = 0
    ld ra, 56(sp)                   # load the return address
    ld s0, 48(sp)                   # restore s0
    ld s1, 40(sp)                   # restore s1
    ld s2, 32(sp)                   # restore s2
    ld s3, 24(sp)                   # restore s3
    ld s4, 16(sp)                   # restore s4
    ld s5, 8(sp)                    # restore s5
    ld s6, 0(sp)                    # restore s6
    addi sp, sp, 64                 # restore space in stack
    ret                             # return 

.section .rodata
fmt_int: .string "%ld"              # format string: print a 64-bit signed integer
fmt_newline: .string "\n"           # format string: newline character
