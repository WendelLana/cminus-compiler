#include "mips.h"

static FILE* OUTPUT = NULL;

void mips_set_output_file(FILE* file)
{
    OUTPUT = file;
}

void mips_write_label(char* label_name)
{
    fprintf(OUTPUT, "%s:\n", label_name);
}

void mips_setup_stack_frame()
{
    fprintf(OUTPUT,
        "sub $sp, $sp, 4\n"
        "sw $ra, ($sp)\n"
        "sub $sp, $sp, 4\n"
        "sw $fp, ($sp)\n"
        "sub $sp, $sp, 4\n"
        "sw $s0, ($sp)\n"
        "sub $sp, $sp, 4\n"
        "sw $s1, ($sp)\n"
        "move $fp, $sp\n"
    );
}

void mips_push_func_arg(int arg_num) {
    fprintf(OUTPUT,
        "sub $sp, $sp, 4\n"
        "sw $a%d, ($sp)\n",
        arg_num
    );
}

void mips_allocate_sub_stack(int offset) {
    fprintf(OUTPUT, "sub $sp, $sp, %d\n", offset);
}

void mips_li_to_temp_reg(int temp_reg, int immediate) {
    fprintf(OUTPUT, "li $t%d, %d\n", temp_reg, immediate);
}

void mips_load_stack_to_temp_reg(int temp_reg, int offset)
{
    fprintf(OUTPUT, "lw $t%d, -%d($fp)\n", temp_reg, offset);
}

void mips_store_stack_from_temp_reg(int offset, int temp_reg)
{
    fprintf(OUTPUT, "sw $t%d, -%d($fp)\n", temp_reg, offset);
}

void mips_add_temp_regs(int temp_reg1, int temp_reg2)
{
    fprintf(OUTPUT, "add $t%d, $t%d, $t%d\n", temp_reg1, temp_reg1, temp_reg2);
}

void mips_sub_temp_regs(int temp_reg1, int temp_reg2)
{
    fprintf(OUTPUT, "sub $t%d, $t%d, $t%d\n", temp_reg1, temp_reg1, temp_reg2);
}

void mips_mul_temp_regs(int temp_reg1, int temp_reg2)
{
    fprintf(OUTPUT, "mul $t%d, $t%d, $t%d\n", temp_reg1, temp_reg1, temp_reg2);
}

void mips_div_temp_regs(int temp_reg1, int temp_reg2)
{
    fprintf(OUTPUT, "div $t%d, $t%d\n", temp_reg1, temp_reg2);
    fprintf(OUTPUT, "mflo $t%d\n", temp_reg1);
}

void mips_le_temp_regs(int temp_reg1, int temp_reg2, char* branch_label)
{
    fprintf(OUTPUT, "ble $t%d, $t%d, %s\n", temp_reg1, temp_reg2, branch_label);
}

void mips_lt_temp_regs(int temp_reg1, int temp_reg2, char* branch_label)
{
    fprintf(OUTPUT, "blt $t%d, $t%d, %s\n", temp_reg1, temp_reg2, branch_label);
}

void mips_ge_temp_regs(int temp_reg1, int temp_reg2, char* branch_label)
{
    fprintf(OUTPUT, "bge $t%d, $t%d, %s\n", temp_reg1, temp_reg2, branch_label);
}

void mips_gt_temp_regs(int temp_reg1, int temp_reg2, char* branch_label)
{
    fprintf(OUTPUT, "bgt $t%d, $t%d, %s\n", temp_reg1, temp_reg2, branch_label);
}

void mips_eq_temp_regs(int temp_reg1, int temp_reg2, char* branch_label)
{
    fprintf(OUTPUT, "beq $t%d, $t%d, %s\n", temp_reg1, temp_reg2, branch_label);
}

void mips_ne_temp_regs(int temp_reg1, int temp_reg2, char* branch_label)
{
    fprintf(OUTPUT, "bne $t%d, $t%d, %s\n", temp_reg1, temp_reg2, branch_label);
}

void mips_unconditional_jmp(char* label_name)
{
    fprintf(OUTPUT, "j %s\n", label_name);
}

void mips_load_temp_reg_arg(int arg, int temp_reg) {
    fprintf(OUTPUT, "move $a%d, $t%d\n", arg, temp_reg);
}

void mips_call_func(char* label) {
    fprintf(OUTPUT, "jal %s\n", label);
}

void mips_store_return_saved_reg(int saved_reg) {
    fprintf(OUTPUT, "move $s%d, $v0\n", saved_reg);
}

void mips_move_saved_to_temp(int temp_reg, int saved_reg) {
    fprintf(OUTPUT, "move $t%d, $s%d\n", temp_reg, saved_reg);
}

void mips_return(int ret_value_temp_reg, int stack_offset)
{
    fprintf(OUTPUT,
        "move $v0, $t%d\n"
        "add $sp, $sp, %d\n"
        "lw $s1, ($sp)\n"
        "add $sp, $sp, 4\n"
        "lw $s0, ($sp)\n"
        "add $sp, $sp, 4\n"
        "lw $fp, ($sp)\n"
        "add $sp, $sp, 4\n"
        "lw $ra, ($sp)\n"
        "add $sp, $sp, 4\n"
        "jr $ra\n",
        ret_value_temp_reg,
        stack_offset
    );
}

