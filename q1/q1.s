.section .text
.globl make_node
.globl insert
.globl get
.globl getAtMost

.extern malloc

make_node:                      # argument: a0: val
    addi sp, sp, -16            # make space in stack
    sd ra, 8(sp)                # store the return address on stack
    sd a0, 0(sp)                # store the argument (val) on stack

    li a0, 24 
    call malloc                 # call malloc(24)

    mv t2, a0                   # copy return pointer to t2 (t2 = address of our node)
    ld t1, 0(sp)                # restore val into t1

    sw t1, 0(t2)                # node->val = value
    sd zero, 8(t2)              # node->left = NULL
    sd zero, 16(t2)             # node->right = NULL

    mv a0, t2                   # move the node pointer back to t2

    ld ra, 8(sp)                # load the return address
    addi sp, sp, 16             # restore space in stack
    ret                         # return


insert:                         # argument: a0: root, a1: value
    addi sp, sp, -24            # make space in stack
    sd ra, 16(sp)               # store the return address on stack
    sd s0, 8(sp)                # save s0
    sd a0, 0(sp)                # store the argument (root) on stack

    beqz a0, insert_node        # if a0 == NULL, insert node

    mv s0, a0                   # copy node pointer to s0 (s0 = address of the current root)

    lw t1, 0(s0)                # t1 = root->val

    blt a1, t1, root_left       # if t1 < a1 (root->val < value), then go left
    bgt a1, t1, root_right      # if t1 > a1 (root->val > value), then go right

    mv a0, s0                   # copy root pointer to a0 from s0
    j end_insert                # return function

insert_node:
    mv a0, a1                   # move argument value to a0
    call make_node              # create a new node with the same value
    j end_insert                # jump to return function

root_left:                          
    ld a0, 8(s0)                # load a0 with (node->left), as s0 == node
    call insert                 # insert in node->left
    sd a0, 8(s0)                # store the new a0 as (node->left)
    mv a0, s0                   # copy node pointer to a0 from s0
    j end_insert                # jump to return function

root_right:
    ld a0, 16(s0)               # load a0 with (node->right), as s0 == node
    call insert                 # insert in node->right
    sd a0, 16(s0)               # store the new a0 as (node->right)
    mv a0, s0                   # copy node pointer to a0 from s0
    j end_insert                # jump to return function

end_insert:
    ld s0, 8(sp)                # restore s0
    ld ra, 16(sp)               # load the return address
    addi sp, sp, 24             # restore space in stack
    ret                         # return    


get:                            # argument: a0: root, a1: value
    addi sp, sp, -24            # make space in stack
    sd ra, 16(sp)               # store the return address on stack
    sd s0, 8(sp)                # save s0

    beqz a0, null               # if a0 == 0, jump to null function

    mv s0, a0                   # copy node pointer to s0 (s0 = address of the current root)
    lw t1, 0(s0)                # t1 = root->val

    beq t1, a1, found           # if node->val == value, jump to found function
    blt a1, t1, search_left     # if node->val < value, search left

    ld a0, 16(s0)               # load node->right in a0
    call get                    # search right
    j end_get                   # end function

search_left:
    ld a0, 8(s0)                # load node->left in a0
    call get                    # search left
    j end_get                   # end function

found:
    mv a0, s0                   # copy node pointer to a0 from s0
    j end_get                   # end function

null:
    li a0, 0                    # a0 = 0

end_get:
    ld s0, 8(sp)                # restore s0
    ld ra, 16(sp)               # load the return address
    addi sp, sp, 24             # restore space in stack
    ret                         # return


getAtMost:                      # argument: a0: root, a1: value
    mv t0, a1                   # copy root to t0 from a1
    mv t1, a0                   # copy val to t1 from a0

    li a0, -1                   # result = -1

loop:
    beqz t0, done               # if t0 == NULL, exit loop
    lw t2, 0(t0)                # current value
    bgt t2, t1, go_latmost      # if current value > val, go left

    mv a0, t2                   # update result with current value
    ld t0, 16(t0)               # move to right subtree
    j loop                      # repeat loop

go_latmost:
    ld t0, 8(t0)                # move to left subtree
    j loop                      # repeat loop

done:
    ret                         # return result
    