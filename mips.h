#ifndef MIPS_H
#define MIPS_H

#include <stdio.h>

void mips_set_output_file(FILE* file);
void mips_write_label(char* label_name);
void mips_setup_stack_frame();
void mips_push_func_arg(int arg_num);
void mips_allocate_sub_stack(int offset);
void mips_li_to_temp_reg(int temp_reg, int immediate);
void mips_load_stack_to_temp_reg(int temp_reg, int offset);
void mips_store_stack_from_temp_reg(int offset, int temp_reg);
void mips_add_temp_regs(int temp_reg1, int temp_reg2);
void mips_sub_temp_regs(int temp_reg1, int temp_reg2);
void mips_mul_temp_regs(int temp_reg1, int temp_reg2);
void mips_div_temp_regs(int temp_reg1, int temp_reg2);
void mips_le_temp_regs(int temp_reg1, int temp_reg2, char* branch_label);
void mips_lt_temp_regs(int temp_reg1, int temp_reg2, char* branch_label);
void mips_ge_temp_regs(int temp_reg1, int temp_reg2, char* branch_label);
void mips_gt_temp_regs(int temp_reg1, int temp_reg2, char* branch_label);
void mips_eq_temp_regs(int temp_reg1, int temp_reg2, char* branch_label);
void mips_ne_temp_regs(int temp_reg1, int temp_reg2, char* branch_label);
void mips_unconditional_jmp(char* label_name);
void mips_return(int ret_value_temp_reg, int stack_offset);
void mips_load_temp_reg_arg(int arg, int temp_reg);
void mips_call_func(char* label);
void mips_store_return_saved_reg(int saved_reg);
void mips_move_saved_to_temp(int temp_reg, int saved_reg);
void mips_move_stack_addr_to_temp(int temp_reg, int offset);
void mips_lw_temp_regs(int temp_reg, int temp_reg2);
void mips_sw_temp_regs(int temp_reg, int temp_reg2);
void mips_mul_temp_reg_imm(int temp_reg, int imm);
void mips_exit_syscall();

#endif // MIPS_H
