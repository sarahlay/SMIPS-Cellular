########################################################################
# COMP1521 20T2 --- assignment 1: a cellular automaton renderer
#
# Written by Sarah Lay, July 2020.

# Maximum and minimum values for the 3 parameters.

MIN_WORLD_SIZE	=    1
MAX_WORLD_SIZE	=  128
MIN_GENERATIONS	= -256
MAX_GENERATIONS	=  256
MIN_RULE	    =    0
MAX_RULE	    =  255
BYTES           = 4

# Characters used to print alive/dead cells.

ALIVE_CHAR	    = '#'
DEAD_CHAR	    = '.'

# Maximum number of bytes needed to store all generations of cells.

MAX_CELLS_BYTES	= (MAX_GENERATIONS + 1) * MAX_WORLD_SIZE

    .data

# `cells' is used to store successive generations.  Each byte will be 1
# if the cell is alive in that generation, and 0 otherwise.

cells:	.space MAX_CELLS_BYTES

# Strings:

prompt_world_size:	    .asciiz "Enter world size: "
error_world_size:	    .asciiz "Invalid world size\n"
prompt_rule:		    .asciiz "Enter rule: "
error_rule:		        .asciiz "Invalid rule\n"
prompt_n_generations:	.asciiz "Enter how many generations: "
error_n_generations:	.asciiz "Invalid number of generations\n"

    .text

############################### MAIN ###################################
########################################################################

main:

    # Registers:
    #       - $s0       world_size
    #       - $s1       rule
    #       - $s2       n_generations
    #       - $s3       reverse
    #       - $s4       which_generation (iterative)
    #       - $t0..$t3  intermediate variables

    la      $a0, prompt_world_size                      # printf("Enter world size: ");
    li      $v0, 4
    syscall

    li      $v0, 5                                      # scanf("%d", &rule);
    syscall
    move    $s0, $v0

    blt     $s0, MIN_WORLD_SIZE, invalid_world_size     # if (  world_size < MIN_WORLD_SIZE ||
    bgt     $s0, MAX_WORLD_SIZE, invalid_world_size     #       world_size > MAX_WORLD_SIZE)
                                                        #       goto invalid_World_size;

    la      $a0, prompt_rule                            # printf("Enter rule: ");
    li      $v0, 4
    syscall

    li      $v0, 5                                      # scanf("%d", &rule);
    syscall
    move    $s1, $v0

    blt     $s1, MIN_RULE, invalid_rule                 # if (  rule < MIN_RULE ||
    bgt     $s1, MAX_RULE, invalid_rule                 #       rule > MAX_RULE)
                                                        #       goto invalid_rule;

    la      $a0, prompt_n_generations                   # printf("Enter how many generations: ");
    li      $v0, 4
    syscall

    li      $v0, 5                                      # scanf("%d", &n_generations);
    syscall
    move    $s2, $v0

    blt     $s2, MIN_GENERATIONS, invalid_generation    # if (  n_generations < MIN_GENERATIONS ||
    bgt     $s2, MAX_GENERATIONS, invalid_generation    #       n_generations > MAX_GENERATIONS)
                                                        #       goto invalid_generation

    li      $s3, 0                                      # int reverse = 0;
    bltz    $s2, negative_generation                    # if (n_generations < 0) goto negative_generation

    b continue                                          # goto continue;

invalid_world_size:
    la      $a0, error_world_size                       # printf("Invalid world size\n");
    li      $v0, 4
    syscall
    b     end                                           # return 1;

invalid_rule:
    la      $a0, error_rule                             # printf("Invalid rule\n");
    li      $v0, 4
    syscall
    b       end                                         # return 1;

invalid_generation:
    la      $a0, error_n_generations                    # printf("Invalid number of generations\n");
    li      $v0, 4
    syscall
    b       end                                         # return 1;

negative_generation:
    li      $s3, 1                                      # reverse = 1;
    mul     $s2, $s2, -1                                # n_generations = -n_generations;
    b       continue

continue:
    li      $a0, '\n'                                   # putchar('\n');
    li      $v0, 11
    syscall

    la      $t0, cells                                  # cells[0][world_size / 2] = 1;
    div     $t1, $s0, 2                                 # x = x / 2 (row)
    mul     $t1, $t1, BYTES                             # x = x * 4 (row)
    add     $t2, $t1, $t0
    li      $t3, 1
    sw		$t3, ($t2)

    li      $s4, 1                                      # int which_generation = 1;

render_cells:
    bgt     $s4, $s2, print_cells                       # if (which_generation > n_generations) goto print_cells;

    sub     $sp, $sp, 4                                 # run_generation(world_size, which_generation, rule);
    sw      $ra, 0($sp)                                 # save $ra on stack
                                                        # set $ra to following address

    move    $a0, $s0                                    # $a0 = world_size
    move    $a1, $s4                                    # $a1 = which_generation
    move    $a2, $s1                                    # $a2 = rule
    jal     run_generation                              # run_generation(world_size, which_generation, rule)

    lw      $ra, 0($sp)                                 # recover $ra from stack
    add     $sp, $sp, 4                                 # move stack pointer back up to what it was

    add     $s4, $s4, 1                                 # which_generation++;
    b       render_cells                                # goto render_cells;

print_cells:
    move    $s4, $s2                                    # int which_generation = n_generations;
    bnez    $s3, reversed_printing                      # if (reverse) goto reversed_printing
    li      $s4, 0                                      # which_generation = 0;
    b       normal_printing                             # goto normal_printing;

reversed_printing:
    bltz    $s4, end                                    # if (which_generation < 0) goto end;

    sub     $sp, $sp, 4                                 # save on $ra from stack
    sw      $ra, 0($sp)

    move    $a0, $s0                                    # $a0 = world_size
    move    $a1, $s4                                    # $a1 = which_generation
    jal     print_generation                            # print_generation(world_size, which_generation);

    lw      $ra, 0($sp)
    add     $sp, $sp, 4

    sub     $s4, $s4, 1                                 # which_generation--;
    b       reversed_printing                           # goto reversed_printing;

normal_printing:
    bgt     $s4, $s2, end                               # if (which_generation > n_generations) goto end;

    sub     $sp, $sp, 4                                 # save on $ra from stack
    sw      $ra, 0($sp)

    move    $a0, $s0                                    # $a0 = world_size
    move    $a1, $s4                                    # $a1 = which_generation
    jal     print_generation                            # print_generation(world_size, which_generation);

    lw      $ra, 0($sp)
    add     $sp, $sp, 4

    add     $s4, $s4, 1                                 # which_generation++;
    b       normal_printing                             # goto normal_printing;

end:
    li      $v0, 0
    jr      $ra


########################## RUN_GENERATION ##############################
########################################################################

    #
    # Given `world_size', `which_generation', and `rule', calculate
    # a new generation according to `rule' and store it in `cells'.
    #

    # Arguments:
    #       - $a0       world_size
    #       - $a1       which_generation
    #       - $a2       rule
    #
    # Registers:
    #       - $t0..$t8  intermediate variables
    #
    # Intermediate Variables Used:
    #       - $t0       x
    #       - $t1       cells,      temporary variable
    #       - $t2       column,     temporary variable
    #       - $t3       row,        temporary variable
    #       - $t5       centre
    #       - $t6       left
    #       - $t7       right
    #       - $t8       set

run_generation:
    sub     $sp, $sp, 16                                # move stack pointer down to make room
    sw      $ra, 12($sp)                                # save $ra on $stack
    sw      $a2, 8($sp)                                 # save $a2 (rule) on $stack
    sw      $a1, 4($sp)                                 # save $a1 (which_generation) on $stack
    sw      $a0, 0($sp)                                 # save $a0 (world_size) on $stack

    li      $t0, 0                                      # int x = 0;

f_loop:
    bge     $t0, $a0, complete                          # if (x >= world_size) goto complete;

    la		$t1, cells                                  # $t1 = &cells
    sub     $t2, $a1, 1                                 # $t2 = [which_generation - 1] (column)
    mul     $t2, $t2, MAX_GENERATIONS
    mul     $t2, $t2, BYTES                             # column = column * 4 (bytes)
    mul     $t3, $t0, BYTES                             # row = row * 4
    add     $t4, $t1, $t2
    add     $t4, $t3, $t4

    lw		$t5, ($t4)                                  # int centre = cells[which_generation - 1][x];

f_set_left:
    li      $t6, 0                                      # int left = 0;
    beqz    $t0, f_set_right                            # if (x = 0) goto f_set_right;

    la		$t1, cells                                  # $t1 = &cells
    sub     $t2, $a1, 1                                 # $t2 = [which_generation - 1] (column)
    sub     $t3, $t0, 1                                 # $t3 = x - 1 (row)
    mul     $t2, $t2, MAX_GENERATIONS
    mul     $t2, $t2, BYTES                             # column = column * 4 (bytes)
    mul     $t3, $t3, BYTES                             # row = row * 4
    add     $t4, $t1, $t2
    add     $t4, $t3, $t4

    lw		$t6, ($t4)                                  # left = cells[which_generation - 1][x - 1];

f_set_right:
    li      $t7, 0                                      # int right = 0;
    sub     $t1, $a0, 1                                 # $t1 = world_size - 1
    bge     $t0, $t1, f_set_state                       # if (x >= world_size - 1) goto f_set_state;

    la		$t1, cells                                  # $t1 = &cells
    sub     $t2, $a1, 1                                 # $t2 = [which_generation - 1] (column)
    add     $t3, $t0, 1                                 # $t3 = x + 1 (row)
    mul     $t2, $t2, MAX_GENERATIONS
    mul     $t2, $t2, BYTES                             # column = column * 4 (bytes)
    mul     $t3, $t3, BYTES                             # row = row * 4
    add     $t4, $t1, $t2
    add     $t4, $t3, $t4

    lw		$t7, ($t4)                                  # right = cells[which_generation - 1][x + 1];

f_set_state:
                                                        # Convert the left, centre, and right states into one value.
    sll     $t5, $t5, 1                                 # $t5 = $t5 (centre) << 1
    sll     $t6, $t6, 2                                 # $t6 = $t6 (left) << 2

    or      $t1, $t6, $t5                               # int state = left << 2 | centre << 1 | right << 0;
    or      $t1, $t1, $t7                               # $t1 = state

                                                        # And check whether that bit is set or not in the rule.
                                                        # by testing the corresponding bit of the rule number.

    li      $t2, 1                                      # int bit = 1 << state;
    sllv    $t2, $t2, $t1                               # $t2 = bit

    and     $t5, $a2, $t2                               # int set = rule & bit;

# set_cells:
    la		$t1, cells                                  # $t1 = &cells
    move    $t2, $a1                                    # $t2 = which_generation (column)
    move    $t3, $t0                                    # $t3 = x (row)
    mul     $t2, $t2, MAX_GENERATIONS                   # $t2 = $t2 * MAX_GENERATIONS (column)
    mul     $t2, $t2, BYTES                             # column = column * 4 (bytes)
    mul     $t3, $t3, BYTES                             # row = row * 4
    add     $t4, $t1, $t2
    add     $t4, $t3, $t4

    bnez    $t5, set_alive_cell                         # if (set) goto set_alive;

    li      $t1, 0
    sw		$t1, ($t4)                                  # cells[which_generation][x] = 0;

    add     $t0, $t0, 1                                 # x++;
    b       f_loop

set_alive_cell:
    li      $t1, 1
    sw		$t1, ($t4)                                  # cells[which_generation][x] = 1;

    add     $t0, $t0, 1                                 # x++;
    b       f_loop                                      # goto f_loop;

complete:
    lw		$ra, 12($sp)                                # restore $ra from $stack
    add     $sp, $sp, 16                                # move stack pointer back up to what it was when main called

    jr      $ra                                         # return;


########################## PRINT_GENERATION ############################
########################################################################
    #
    # Given `world_size', and `which_generation', print out the
    # specified generation.
    #
    # Arguments:
    #       - $a0       world_size
    #       - $a1       which_generation
    #
    # Registers:
    #       - $t0..$t4  intermediate variables
    #
    # Intermediate Variable Uses:
    #       - $t0       x
    #       - $t1       cells
    #       - $t2       column
    #       - $t3       row
    #       - $t4       current cell
    #

print_generation:
    sub     $sp, $sp, 12                                # move stack pointer down to make room
    sw      $ra, 8($sp)                                 # save $ra on $stack
    sw      $a1, 4($sp)                                 # save $a1 (which_generation) on $stack
    sw      $a0, 0($sp)                                 # save $a0 (world_size) on $stack

    move    $a0, $a1                                    # print("%d", which_generation);
    li      $v0, 1
    syscall

    li      $a0, '\t'                                   # putchar('\t');
    li      $v0, 11
    syscall

    li      $t0, 0                                      # int x = 0;

print_loop:
    lw      $a0, 0($sp)                                 # restore $a0 from $stack
    bge     $t0, $a0, finished_printing                 # if (x >= world_size) goto finished_printing;

    la      $t1, cells
    move    $t2, $a1                                    # $t2 = column
    move    $t3, $t0                                    # $t3 = row
    mul     $t2, $t2, MAX_GENERATIONS                   # $t2 = $t2 * MAX_GENERATIONS (column)
    mul     $t2, $t2, BYTES                             # $t2 = $t2 * BYTES (column)
    mul     $t3, $t3, BYTES
    add     $t4, $t1, $t2
    add     $t4, $t3, $t4                               # $t4 = cells[which_generation][x]

    lw      $t4, ($t4)

    bnez    $t4, print_alive                            # if (cells[which_generation][x]) goto print_alive;
    b       print_dead                                  # goto print_dead;

print_alive:
    li      $a0, ALIVE_CHAR                             # putchar(ALIVE_CHAR);
    li      $v0, 11
    syscall

    add     $t0, $t0, 1                                 # x++;
    b       print_loop                                  # goto print_loop;

print_dead:
    li      $a0, DEAD_CHAR                              # putchar(DEAD_CHAR);
    li      $v0, 11
    syscall

    add     $t0, $t0, 1                                 # x++;
    b       print_loop                                  # goto print_loop;

finished_printing:
    li      $a0, '\n'                                   # putchar('\n');
    li      $v0, 11
    syscall

    lw		$ra, 8($sp)                                # restore $ra from $stack
    add     $sp, $sp, 12                                # move stack pointer back up to what it was when main called

    jr      $ra                                         # return;