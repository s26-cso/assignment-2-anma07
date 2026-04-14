.section .data
filename: .string "input.txt"       # Name of the file we need to check
yes_msg: .string "Yes\n"            # Output when the string is a palindrome
no_msg: .string "No\n"              # Output when the string is not a palindrome

.section .text
.globl main

main:
    addi sp, sp, -32                # Reserve 32 bytes on the stack for safety
    sd ra, 24(sp)                   # Save the return address to the stack

    li a0, -100                     # look for file in current directory
    la a1, filename                 # Pointer to the filename "input.txt"
    li a2, 0                        # open the file in read-only mode
    li a7, 56                       # Linux syscall number for openat
    ecall                           # Request the kernel to open the file
    bltz a0, exit_program           # If result is negative, the file open failed
    mv s0, a0                       # Save the file descriptor in s0 for later use

    mv a0, s0                       # Provide our file descriptor
    li a1, 0                        # Offset of 0 from the reference point
    li a2, 2                        # jump to the very end of the file
    li a7, 62                       # Linux syscall number for lseek
    ecall                           # Execute seek to find the total byte count
    mv s1, a0                       # s1 now stores the total length of the file

    li s2, 0                        # s2 is our 'left' pointer, starting at index 0
    addi s3, s1, -1                 # s3 is our 'right' pointer, starting at index n-1

palindrome_loop:
    bge s2, s3, is_palindrome       # If pointers meet or cross, everything matched

    mv a0, s0                       # File descriptor
    mv a1, s2                       # Set the offset to the current left index
    li a2, 0                        # offset from the start of the file
    li a7, 62                       # Syscall for lseek
    ecall                           # Move the file's internal pointer
    
    mv a0, s0                       # File descriptor
    addi a1, sp, 0                  # Buffer address is the start of our stack space
    li a2, 1                        # Ask to read exactly 1 byte
    li a7, 63                       # Syscall for read
    ecall                           # Pull one character into our stack buffer
    lbu s4, 0(sp)                   # Load that unsigned byte into register s4

    mv a0, s0                       # File descriptor
    mv a1, s3                       # Set the offset to the current right index
    li a2, 0                        # offset from the start of the file
    li a7, 62                       # Syscall for lseek
    ecall                           # Move the file's internal pointer

    mv a0, s0                       # File descriptor
    addi a1, sp, 1                  # Buffer address is the next byte on our stack
    li a2, 1                        # Ask to read exactly 1 byte
    li a7, 63                       # Syscall for read
    ecall                           # Pull one character into our stack buffer
    lbu s5, 1(sp)                   # Load that unsigned byte into register s5

    li t0, 10                       # Load the ASCII value for newline 
    beq s5, t0, skip_newline        # If the right char is a newline, ignore it
    
    bne s4, s5, not_palindrome      # If characters differ, it is not a palindrome

    addi s2, s2, 1                  # Increment the left index to move forward
    addi s3, s3, -1                 # Decrement the right index to move backward
    j palindrome_loop               # Repeat the process for the next pair

skip_newline:
    addi s3, s3, -1                 # Just move the right pointer back one more step
    j palindrome_loop               # Go back to the loop start

is_palindrome:
    la a0, yes_msg                  # Load the "Yes\n" message address
    call printf                     # Print success to the console
    j exit_program                  # Go to cleanup

not_palindrome:
    la a0, no_msg                   # Load the "No\n" message address
    call printf                     # Print failure to the console
    j exit_program                  # Go to cleanup

exit_program:
    mv a0, s0                       # Provide the file descriptor to close
    li a7, 57                       # Linux syscall number for close
    ecall                           # Close the input file safely

    li a0, 0                        # Set return value to 0
    ld ra, 24(sp)                   # load the saved return address
    addi sp, sp, 32                 # Restore the stack space
    ret                             # return
    