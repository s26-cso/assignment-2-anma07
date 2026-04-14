.section .data
filename: .string "input.txt"       
yes_msg: .string "Yes\n"            
no_msg: .string "No\n"              

.section .text
.globl main

main:
    addi sp, sp, -32                # create stack space
    sd ra, 24(sp)                   # store the return address

    li a0, -100                     # Search in current directory
    la a1, filename                 # Point to the file we want to open
    li a2, 0                        # Open it in read-only mode
    li a7, 56                       # Trigger the 'open' system call
    ecall                           
    bltz a0, exit_program           # If opening failed, just quit
    mv s0, a0                       # Save the file handle for later use

    mv a0, s0                       
    li a1, 0                        
    li a2, 2                        # Jump straight to the end of the file
    li a7, 62                       # Use lseek to move the "cursor"
    ecall                           
    mv s1, a0                       # The cursor position is now effectively the file size

    li s2, 0                        # Start a pointer at the very first character (index 0)
    addi s3, s1, -1                 # Start a pointer at the very last character (n-1)

palindrome_loop:
    bge s2, s3, is_palindrome       # If the pointers meet or cross, we've checked everything!

    mv a0, s0                       
    mv a1, s2                       # Move cursor to where the left pointer is
    li a2, 0                        # Measure from the start of the file
    li a7, 62                       
    ecall                           
    
    mv a0, s0                       
    addi a1, sp, 0                  # Give read() a spot on the stack to put the byte
    li a2, 1                        # We only need one character
    li a7, 63                       
    ecall                           
    lbu s4, 0(sp)                   # Load that byte from the stack into s4

    mv a0, s0                       
    mv a1, s3                       # Move cursor to where the right pointer is
    li a2, 0                        # Again, measure from the start
    li a7, 62                       
    ecall                           

    mv a0, s0                       
    addi a1, sp, 1                  # Put this byte in a different stack slot
    li a2, 1                        
    li a7, 63                       
    ecall                           
    lbu s5, 1(sp)                   # Load the right-side byte into s5

    li t0, 10                       # 10 is the ASCII code for a newline
    beq s5, t0, skip_newline        # If we hit a newline at the end, just ignore it and move in
    
    bne s4, s5, not_palindrome      # If the two characters don't match, it's not a palindrome

    addi s2, s2, 1                  # Move left pointer forward
    addi s3, s3, -1                 # Move right pointer backward
    j palindrome_loop               # Go again

skip_newline:
    addi s3, s3, -1                 # Move the right pointer in by 1 to skip the '\n'
    j palindrome_loop               

is_palindrome:
    la a0, yes_msg                  
    call printf                     # Print success message
    j exit_program                  

not_palindrome:
    la a0, no_msg                   
    call printf                     # Print failure message
    j exit_program                  

exit_program:
    mv a0, s0                       # Clean up: close the file we opened
    li a7, 57                       
    ecall                           

    li a0, 0                        # Set exit code to 0
    ld ra, 24(sp)                   # load the return address
    addi sp, sp, 32                 # restore back the stack space
    ret                             # return
