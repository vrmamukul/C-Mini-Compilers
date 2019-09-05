	.data


	.text

	.globl main

foo:
	addi	$sp,$sp,-0
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li.s $f1, -1
	lwc1 $f5, 8($sp)
	mul.s $f3, $f1, $f5
	move $v0, $f3
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	addi	$sp,$sp,0
	jr $ra


main:
	addi	$sp,$sp,-4
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	li.s $f1, 2.7
	mov.s $f3, $f1
	swc1 $f3, 4($sp)
	li $t0, 1
	move $v0, $t0
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	addi	$sp,$sp,4
	jr $ra


