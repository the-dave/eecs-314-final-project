################################################################################
# Strings								       #
################################################################################
		.data
str_welcome:	.asciiz "Welcome to Connect Four!\n"
str_prompt:	.asciiz "Enter your move (column number): "
str_invalid:	.asciiz "Input a valid choice (0 - 6).\n"
str_full:	.asciiz "That column is full.\n"
str_one_win:	.asciiz "Player 1 wins!\n"
str_two_win:	.asciiz "Player 2 wins!\n"
str_picked	.asciiz	"Picked"
str_withconf	.asciiz	"with confidence"
str_percent	.asciiz	"%"

str_board_top:	.asciiz "=============================\n"
str_board_rowl:	.asciiz "[ "
str_board_rowr: .asciiz " ]\n"
str_board_div:	.asciiz " | "
str_board_sp:	.asciiz " "
str_board_bott:	.asciiz "=============================\n"
		.text
		
		

################################################################################
# This is the main loop of the connect four game.  It first prints a welcome   #
# message, allocates the board, and then begins the game loop		       #
#									       #
# int main();								       #
################################################################################
# {
main:

#   puts("Welcome to Connect Four\n");
		li	$v0, 4
		la	$a0, str_welcome
		syscall

#   int* board = new_board();
		li	$v0, 9
		li	$a0, 42			# we need 7 * 6 = 42 bytes
		syscall
		move	$s0, $v0		# $s0 = the start of the board

#   while(1)
#   {
loop_game:

#     print_board(board);
		jal	print_board

#     int column = -1;
		# column input will be stored in $a0	
		
#     // Get human input until they enter a valid choice...
#     while (1)
#     {
loop_input:

#       printf("Enter your move (column number): ");
		li	$v0, 4
		la	$a0, str_prompt
		syscall

#       scanf("%d%, &column);
		li	$v0, 5
		syscall				# $v0 = column

#       if (column < 0 || column >= WIDTH)
		blt	$v0, $zero, invalid
		li	$t0, 7			# $t0 = WIDTH = 7
		bge	$v0, $t0, invalid
		j	if_place

#       {		
#         printf("Input a valid choice (0 - 6).\n");
invalid:	li	$v0, 4
		la	$a0, str_invalid
		syscall
		j	loop_input

#       }

if_place:
#       else if (place(board, column, 1) == 0)
		move	$a0, $v0
		li	$a1, 1
		jal	place
		bne	$v0, $zero, end_loop_input

#       {
#         printf("that column is full.\n");
		li	$v0, 4
		la	$a0, str_full
		syscall
		j	loop_input
#       }
#     }		
end_loop_input:

#     // Did the human input make him or her win?
#     if (check_win(board, 1) != 0)
		li	$a0, 1
		jal	check_win
		beq	$v0, $zero, skip_one_wins
#     {
#       print_board(board);
		jal	print_board

#       printf("Player 1 wins!\n");
		li	$v0, 4
		la	$a0, str_one_win
		syscall
	
#       break;
		li	$v0, 10
		syscall

#     }
skip_one_wins:

#     // Do the AI's move...
#     int ai_column = get_next_move(board);
		jal	get_next_move

#     // Did the AI's move cause it to win?
#     if (check_win(board, 1) != 0)
		li	$a0, 2
		jal	check_win
		beq	$v0, $zero, skip_two_wins
#     {
#       print_board(board);
		jal	print_board

#       printf("Player 2 wins!\n");
		li	$v0, 4
		la	$a0, str_two_win
		syscall
	
#       break;
		li	$v0, 10
		syscall

#     }
skip_two_wins:
		j	loop_game
		
#   }



################################################################################
# This simply prints the board with the column indicies at the bottom	       #
#									       #
# void print_board(int* board);						       #
################################################################################
print_board:	
		addi	$sp, $sp, -4
		sw	$ra, 0($sp)
		
		li	$v0, 4
		la	$a0, str_board_top
		syscall
		
		li	$s1, 5			# $s1 = row
start_row:
		li	$s2, 0			# $s2 = column
		li	$v0, 4
		la	$a0, str_board_rowl
		syscall
print_row:	
		move	$a0, $s1
		move	$a1, $s2
		jal	get
		move	$a0, $v0
		
		beqz	$v0, print_space
		li	$v0, 1
		syscall
		b	print_div
print_space:		
		li	$v0, 4
		la	$a0, str_board_sp
		syscall
print_div:		
		addi	$s2, $s2, 1
		bgt	$s2, 6, end_row
		
		li	$v0, 4
		la	$a0, str_board_div
		syscall
		
		b	print_row
end_row:
		li	$v0, 4
		la	$a0, str_board_rowr
		syscall
		
		addi	$s1, $s1, -1
		bltz	$s1, end_print_board
		b	start_row
end_print_board:
		li	$v0, 4
		la	$a0, str_board_bott
		syscall
		
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra



################################################################################
# Place puts a given player number at the lowest available row in the 	       #
# specified column.  It returns 1 on success and 0 on failure (row full)       #
#									       #
# $a0 = column								       #
# $a1 = player 								       #
#									       #
# $v0 = 0 or 1								       #
#									       #
# int place(int* board, int column, int player);			       #
################################################################################
place:		
		addi	$sp, $sp, -4
		sw	$ra, 0($sp)
		
		move	$a2, $a1		# $a2 = player
		move	$a1, $a0		# $a1 = column
#   for (int row = 0; row < HEIGHT; row++)
		li	$a0, -1			# $a0 = row
place_for:

#   {
		addi	$a0, $a0, 1
		li	$a3, 6			# $a3 = HEIGHT = 6
		bge	$a0, $a3, place_end_for

#     if (get(board, row, column) == 0)
		jal	get
		bne	$v0, $zero, place_for
		
#     {
#       put(board, row, column, player);
		jal	put

#       return 1;
		li	$v0, 1
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra

#     }
#   }
place_end_for:

#   return 0;
		li	$v0, 0
		lw	$ra, 0($sp)
		addi	$sp, $sp, 4
		jr	$ra	
		



################################################################################
# Put places the given player number at a specified row and column.  This      #
# function always writes (even if there is already a non-zero value there) so  #
# be careful!  								       #
# 									       #
# $a0 = row								       #
# $a1 = column								       #
# $a2 = player								       #
# 									       #
# $a3 used internally							       #
# 									       #
# void put(int* board, int row, int column, int value);			       #
################################################################################
put:		
#   board[row * WIDTH + column] = value;
		li	$a3, 7			# $a3 = WIDTH = 7
		mult	$a0, $a3		
		mflo	$a3 			# $a3 = row * WIDTH
		add	$a3, $a3, $a1		# $a3 = row * WIDTH + column
		
		add	$a3, $a3, $s0
		sb	$a2, 0($a3)		# store
		jr	$ra



################################################################################
# Get returns the player number at a specified row and column.  Returns a -1   #
# if the row and column are out of bounds, a 0 if the space is empty, and the  #
# player value if the space is occupied					       #
# 									       #
# $a0 = row								       #
# $a1 = column								       #
# 									       #
# $a3 used internally							       #
# 									       #
# $v0 = -1, 0, or player						       #
################################################################################
get:
#   if (row >= 0 && row < HEIGHT &&
#       column >= 0 && column < WIDTH)
		blt	$a0, $zero, get_oob
		blt	$a1, $zero, get_oob
		li	$a3, 6			# $a2 = HEIGHT = 6
		bge	$a0, $a3, get_oob
		li	$a3, 7			# $a2 = WIDTH = 7
		bge	$a1, $a3, get_oob
		
#   {
#     return board[row * WIDTH + column];
		li	$a3, 7			# $a3 = WIDTH = 7
		mult	$a0, $a3		
		mflo	$a3 			# $a3 = row * WIDTH
		add	$a3, $a3, $a1		# $a3 = row * WIDTH + column
		
		add	$a3, $a3, $s0
		lb	$v0, 0($a3)		# load
		jr	$ra
#   }
get_oob:

#   else
#   {
#     return -1;
		li	$v0, -1
		jr	$ra
#   }


################################################################################
# This function checks the entire board and returns whether or not the given   #
# player has won the game.  It returns 1 if the player won.		       #
# 									       #
# $a0 = player								       #
#									       #
# $V0 = 0 or 1								       #
#									       #
# int check_win(int* board, int player);				       #
################################################################################
check_win:
		subi 	$sp, $sp, 4		# push return addr to stack
		sw	$ra, 0($sp)
		
		move	$a2, $a0		# remember the player id
		move	$t0, $zero			# set return temp to 0
		
		j	check_win_horz
chk_h_done:	or	$t0, $t0, $v0
		
		j	check_win_vert
chk_v_done:	or	$t0, $t0, $v0
		
		j	check_win_diag
chk_d_done:	or	$t0, $t0, $v0
		
		lw	$ra, 0($sp)		# pop the return addr
		addi	$sp, $sp, 4
		
		move	$v0, $t0		# return if win occurred
		jr 	$ra


check_win_horz:
		li	$t1, 6			# load height
		li	$t4, 4			# number of consec hits needed
		
ch_loop_height:	beqz	$t1, ch_loop_end
		subi	$t1, $t1, 1		# i--;
		li	$t2, 7			# load width
ch_lw_else:	li	$t3, 0			# consec = 0;

ch_loop_width:	beqz	$t2, ch_loop_height
		subi	$t2, $t2, 1		# j--;
		
		move	$a0, $t1
		move	$a1, $t2
		jal	get			# get(i, j)
		
		bne	$v0, $a2, ch_lw_else	# if ($v0 != player) consec = 0;
		addi	$t3, $t3, 1		# consec++;
		
		bne	$t3, $t4, ch_loop_width	# if (consec != 4) continue looping
		li	$v0, 1
		j	chk_h_done		# return 1;
		
		
ch_loop_end:	li	$v0, 0
		j	chk_h_done		# return 0;


check_win_vert:
		li	$t1, 7			# load width
		li	$t4, 4			# number of consec hits needed
		
cv_loop_width:	beqz	$t1, cv_loop_end
		subi	$t1, $t1, 1		# i--;
		li	$t2, 6			# load height
cv_lh_else:	li	$t3, 0			# consec = 0;

cv_loop_height:	beqz	$t2, cv_loop_width
		subi	$t2, $t2, 1		# j--;
		
		move	$a0, $t2
		move	$a1, $t1
		jal	get			# get(i, j)
		
		bne	$v0, $a2, cv_lh_else	# if ($v0 != player) consec = 0;
		addi	$t3, $t3, 1		# consec++;
		
		bne	$t3, $t4, cv_loop_height# if (consec != 4) continue looping
		li	$v0, 1
		j	chk_v_done		# return 1;

cv_loop_end:	li	$v0, 0
		j	chk_v_done

check_win_diag:
		li	$t7, 7			# width
		li	$t8, 6			# height
		li	$t3, 3			# start_row = 3
		li	$t4, 0			# start_column = 0
		li	$t5, 3			# stop after column 3
		li	$t9, 4			# number of hits to win
		
cd_loop_lr:	bgt	$t4, $t5, cd_loop_rl	# increment start_col as long as
		addi	$t4, $t4, 1		# it's less than or equal to 3
		
		li	$t3, 3			# start_row = 3
		
cd_loop_lr_a:	bge	$t3, $t8, cd_loop_lr	# increment start_row as long as
		addi	$t3, $t3, 1		# it's less than height
		
		li	$t6, 0			# consec = 0
		move	$t1, $t3		# row = start_row
		move	$t2, $t4		# column = start_col
		
cd_loop_lr_in:	blt	$t1, $zero, cd_loop_lr_a
		#bge	$t2, $t8, cd_loop_lr_a
		
		move	$a0, $t1
		move	$a1, $t2
		jal	get			# get(col, row)
		
		subi	$t1, $t1, 1		# move down
		addi	$t2, $t2, 1		# move right
		
		bne	$v0, $a2, cd_loop_lr_in	# if ($v0 != player) loop again
		addi	$t6, $t6, 1		# consec++;
		
		bne	$t6, $t9, cd_loop_lr_in	# if (consec != 4) continue looping
		li	$v0, 1
		j	chk_d_done		# return 1;


cd_loop_rl:

cd_loop_end:	li	$v0, 0
		j	chk_d_done



################################################################################
# int get_next_move(int* colvalues);                                           #
#                                                                              #
# $a0 = starting address of colvalues array (length 7)                         #
#                                                                              #
# $v0 = column to move                                                         #
#                                                                              #
################################################################################
get_next_move:
            subi    $sp, $sp, 4             # push return addr to stack
            sw      $ra, 0($sp)
           
            li      $t0, 0                  # max = 0;
            li      $t1, -1                 # maxcol = -1;
            li      $t2, 0                  # sum = 0
            li      $t3, 28                 # WIDTH * 4 (each value is a word)
            li      $t4, 0                  # "i" = 0; (counts up by 4)
            li      $t9, 0                  # i = 0; (counts up by 1)
           
gnm_loop:   bge     $t4, $t3, gnm_end
                           
            add     $t6, $a0, $t4
            lw      $t6, 0($t6)             # colvalues[i]

            addi    $t4, $t4, 4             # "i++" (increment by a word)
            addi    $t9, $t9, 1             # i++
           
            move    $t5, $t6                # $t5 = abs($t6)
            slt     $t7, $t6, $zero
            beq     $t7, $zero, abs_end
            sub     $t5, $zero, $t6
           
abs_end:    ble     $t0, $t5, gnm_loop      # if (abs(colvalues[i] <= max) loop
            move    $t1, $t9                # maxcol = i;
            move    $t0, $t5                # max = abs(colvalues[i]);
            j       gnm_loop
           
gnm_end:    li      $v0, 4
            la      $a0, str_picked         # "Picked"
            syscall
           
            li      $v0, 1
            move    $a0, $t9                # print i
            syscall
           
            li      $v0, 4
            la      $a0, str_withconf       # "with confidence"
            syscall
           
            mtc1.d  $t0, $f0                # "cast" max to double
            mtc1.d  $t2, $f2                # "cast" sum to double
           
            li      $t8, 100                # load in 100
            mtc1.d  $t8, $f4                # make it a double
           
            div.d   $f2, $f0, $f2           # $f2 = max / sum
            mul.d   $f12, $f2, $f4          # $f12 = 100 * (max / sum)
           
            li      $v0, 3                  # print contents of $f12
            syscall
           
            li      $v0, 4
            la      $a0, str_percent        # "%."
            syscall
           
            lw      $ra, 0($sp)             # pop the return addr
            addi    $sp, $sp, 4
           
            move    $v0, $t1
            jr      $ra

################################################################################
# int* evaluate_board(int* board);					       #
# 									       #
# $s3 = starting address of colvalues array (pass into get_next_move)          #
# 									       #
################################################################################
evaluate_board: li 	$a0, 28 	# 4 bytes * 7 columns
# int* colvalues = malloc(sizeof(int) * WIDTH);
		li 	$v0, 9
		syscall
		add 	$s3, $zero, $v0   #the position of colvalues
# for (int col=0; col < WIDTH; col++) {
# // For each column, calculate that column's value.
		li 	$s1, 0  				#col
eval_board_col: 
# int vertical_consec = 0;
		li 	$t1, 0  				#vertical_consec
# int player = 0;			
		li 	$t2, 0 					# player
# int row;
		li 	$s2, 0  				#row
# for (row=0; row < HEIGHT; row++) {
# 	int at = get(board,row,col);
ev_b_row: 	
		add 	$a0, $zero, $s2
		add 	$a1, $zero, $s1
		jal 	get
# 	if (at==0) { break; }
		beq 	$v0, 0, ev_b_row_end
#	if (at==player) { vertical_consec += 1 }
#	else { player = at; vertical_consec = 1; }
		beq 	$v0, $t2, ev_b_row_e1
		add	$t2, $zero, $v0
		addi	$t1, $zero, 1
ev_b_row_e1:	addi	$t1, $t1, 1
# }
		addi	$s2, $s2, 1
		bne	$s2, 6, ev_b_row  # loop for all 6 rows
ev_b_row_end:
# // So now at this point, row ($s2) is the topmost empty position in the
# // column $s1.
#
# // Check to ensure that the row is not the top of the board 
# //  (if it is, may as well go to the next column...)
# if (row >= HEIGHT) {
		slti	$t4, $s2, 6
		beq	$t4, 1, ev_b_col_e1
# colvalues[col] = 0; continue;
		addi 	$s1, $s1, 1
		bne 	$s1, 7, eval_board_col
# } else {					
ev_b_col_e1:
# colvalues[col] = (player == 2) ? (int)pow........
		add	$a0, $t2, $zero
		add	$a1, $s1, $zero
		add	$a2, $t1, $zero
		jal 	set_colval
# }	
#########################################################################
## Horizontal Availabilities
#########################################################################
		li 	$t0, 0		# int horiz_before_player = 0
		li	$t1, 0		# int horiz_after_player = 0
		li 	$t2, 1		# int horiz_before_consec = 1
		li 	$t3, 1		# int horiz_after_consec = 1
	######### Before the gap...
# for (int col_horiz = 0; col_horiz < col; col_horiz++) {
		li 	$t4, 0		# int col_horiz = 0
ev_b2_before0:	slt 	$t5, $t4, $s1	# col_horiz < col
		bne	$t5, 1, ev_b2_before1
		# int at = get(board, row, col_horiz)
		add	$a0, $s2, $zero
		add	$a1, $t4, $zero
		jal 	get
		# if (horiz_before_player == at) {
		#	horiz_before_consec += 1
		# } else {
		#	horiz_before_consec = 1;
		#	horiz_before_player = at;
		# }
		li	$t5, 1
		bne	$t0, $v0, ev_b2_before00
		add	$t5, $t5, $t2
ev_b2_before00:
		addi 	$t4, $t4, 1
		add	$t0, $v0, $zero
		j 	ev_b2_before0
ev_b2_before1:	
# }
# if (horiz_before_player == 0) {
# 	horiz_before_consec = 0;
# }
		bne 	$t0, $zero, ev_b2_after2
		li	$t2, 0
ev_b2_before2:	# So we're good here, let's now do...
	######### After the gap...
# for (int col_horiz = WIDTH; col_horiz > col; col_horiz--) {
		li 	$t4, 7		# int col_horiz = WIDTH = 7
ev_b2_after0:	sgt 	$t5, $t4, $s1	# col_horiz > col
		bne	$t5, 1, ev_b2_after1
		# int at = get(board, row, col_horiz)
		add	$a0, $s2, $zero
		add	$a1, $t4, $zero
		jal 	get
		# if (horiz_before_player == at) {
		#	horiz_before_consec += 1
		# } else {
		#	horiz_before_consec = 1;
		#	horiz_before_player = at;
		# }
		li	$t5, 1
		bne	$t1, $v0, ev_b2_after00
		add	$t5, $t5, $t3
ev_b2_after00:
		subi 	$t4, $t4, 1
		add	$t1, $v0, $zero
		j 	ev_b2_after0
ev_b2_after1:
# }
# if (horiz_before_player == 0) {
# 	horiz_before_consec = 0;
# }
		bne 	$t0, $zero, ev_b2_after2
		li	$t2, 0
ev_b2_after2:
		# Okay, now we've calculated everything, let's sum it up
		# and add to colvalues...
		
# if (horiz_before_player == horiz_after_player) {
		bne 	$t0, $t1, ev_b2_sum1
		# int total_consec = horiz_before_consec + horiz_after_consec
		add	$a2, $t2, $t3
		add	$a0, $t0, $zero
		add	$a1, $s1, $zero
		jal set_colval
		j ev_b2_sum11
ev_b2_sum1:	add 	$a2, $t2, $zero
		add 	$a0, $t0, $zero
		add	$a1, $s1, $zero
		jal set_colval
		add 	$a2, $t3, $zero
		add 	$a0, $t1, $zero
		add	$a1, $s1, $zero
		jal set_colval
ev_b2_sum11:
#########################################################################
## Diagonal Availabilities
#
#        IMPLEMENT MEEEEEEEEE!
#
#########################################################################
		addi 	$s1, $s1, 1
		bne 	$s1, 7, eval_board_col
# } (ends the main AI loop for each column.)
################################################################################
# Sets the column value based on the formula				       #
#									       #
#      colvalues[col] += (player == 2) ? (int)pow(10.0, [number consec]) :     #
#				-(int)pow(10.0), [number consec])	       #
# 									       #
# $a0 = player								       #
# $a1 = column								       #
# $a2 = number consecutive						       #
# 									       #
# $t1, $t0, $t3, and $a3 used internally, if you care to know		       #
################################################################################
set_colval:	li	$a3, 4
		mult	$a1, $a3
		mflo 	$a3		# the offset from $s3
		add	$t3, $a3, $s3	# adds offset...
		lw	$a1, 0($t3)	# $a1 = current colvalue
		# shuffle around some registers so we can call pow
		add	$t1, $zero, $a0
		add	$a0, $a2, $zero
pow:		li 	$t0, 10  #The base
		li	$v0, 1
pow_loop:	
		beq	$a0, 0, pow_done
		mult	$v0, $t0
		mflo	$v0
		addi	$a0, $a0, -1
		j 	pow_loop
pow_done:
		beq 	$t1, 2, set_colval_com
		# If the player is human, then the colval should be negative
		addi	$t1, $zero, -1
		mult	$v0, $t1
		mflo	$v0
set_colval_com: add	$a1, $a1, $v0
		sw	$a1, 0($t3)
		jr	$ra
