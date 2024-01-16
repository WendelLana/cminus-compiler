#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

#include "y.tab.h"
#include "ast.h"
#include "mips.h"

typedef struct id_list_node_struct {
  char* id;
  int offset;
  struct id_list_node_struct* next;
} id_list_node;

static void traverse_ast_and_compile(ast_node_t* node);
static void compile_node(ast_node_t* node);
static void compile_assign_node(ast_node_t* node, int temp_reg);
static void compile_calc_node(ast_node_t* node, int temp_reg);
static void compile_relop_calc_node(ast_node_t* node);
static void compile_if_node(ast_node_t* node);
static void compile_while_node(ast_node_t* node);
static void compile_return_node(ast_node_t* node);
static void compile_call_node(ast_node_t* node, int temp_reg);
static void compile_array_expr(ast_node_t* node, int temp_reg);
static void add_id_to_list(char* id, int offset);
static int get_id_offset(char* id);
static void free_id_list();
static void write_empty_line();
static void panic_exit(char* error_msg);

static FILE* PRG_FILE;
static bool IS_TYPE_FOR_FUNC_RET = false;
static bool IS_FUNC_MAIN = false;
static ast_var_type_t CURR_FUNC_RET_TYPE = VOID_TYPE;
static char* CURR_FUNC_NAME = NULL;
static int CURR_FUNC_ARG_COUNT = 0;
static int CURR_FUNC_STACK_OFFSET = 0;
static int CURR_FUNC_IF_BRANCH_ID = 0;
static int CURR_FUNC_WHILE_BRANCH_ID = 0;
static id_list_node* ID_LIST_HEAD = NULL;

// FIXME
void temp_print_id_list() {
  id_list_node* node = ID_LIST_HEAD;
  while(node != NULL) {
    printf("%s %d\n", node->id, node->offset);
    node = node->next;
  }
}

int main()
{
    yyparse();

    PRG_FILE = fopen("prg.mips", "w");
    if(PRG_FILE == NULL) {
      panic_exit("Couldn't open output file");
    }

    mips_set_output_file(PRG_FILE);
    mips_unconditional_jmp("main");
    write_empty_line();
    traverse_ast_and_compile(ast_head);
    temp_print_id_list();
    fclose(PRG_FILE);

    return 0;
}

static void traverse_ast_and_compile(ast_node_t* node)
{
  while(node != NULL) {
      compile_node(node);
      for(int i=0; i<5 && node->type != ASSIGN_NODE && node->type != RETURN_NODE; i++) {
          if (node->child[i] != NULL)
              traverse_ast_and_compile(node->child[i]);
      }
      node = node->sibling;
  }
}

static void compile_node(ast_node_t* node)
{
  printf("type:%d line:%d\n", node->type, node->line_num);

  if(node->if_label != NULL && node->type != CALC_NODE) {
    if(node->if_end_label != NULL) {
      mips_unconditional_jmp(node->if_end_label);
    }
    mips_write_label(node->if_label);
  }

  if(node->while_label != NULL && node->type != CALC_NODE) {
    mips_unconditional_jmp(node->while_label);
    mips_write_label(node->while_end_label);
  }

  switch (node->type)
  {
    case IF_NODE:
      compile_if_node(node);
      break;
    case WHILE_NODE:
      compile_while_node(node);
      break;
    case ASSIGN_NODE:
      compile_assign_node(node, 0);
      write_empty_line();
      break;
    case RETURN_NODE:
      compile_return_node(node);
      write_empty_line();
      break;
    case COMPOUND_NODE:
      break;
    case OP_NODE:
      break;
    case NUM_NODE:
      break;
    case ID_NODE:
      break;
    case TYPE_NODE:
      if(IS_TYPE_FOR_FUNC_RET) {
        CURR_FUNC_RET_TYPE = node->attr.type;
        IS_TYPE_FOR_FUNC_RET = false;
      }
      break;
    case ARRAY_ID_NODE:
      break;
    case CALL_NODE:
      compile_call_node(node, 0);
      write_empty_line();
      break;
    case CALC_NODE:
      if(node->if_label == NULL && node->while_end_label == NULL) {
        panic_exit("\"compile_node\" reached unreachable node"); // should never happen
      }
      compile_relop_calc_node(node);
      write_empty_line();
      break;
    case VAR_NODE:
      mips_allocate_sub_stack(4);
      write_empty_line();
      CURR_FUNC_STACK_OFFSET += 4;
      add_id_to_list(node->attr.name, CURR_FUNC_STACK_OFFSET);
      break;
    case FUNC_NODE:
      mips_write_label(node->attr.name);
      IS_FUNC_MAIN = false;
      if(strncmp(node->attr.name, "main", 4) == 0) {
        IS_FUNC_MAIN = true;
        mips_move_sp_to_fp();
      }
      else {
        mips_setup_stack_frame();
        write_empty_line();
      }
      CURR_FUNC_NAME = node->attr.name;
      CURR_FUNC_ARG_COUNT = 0;
      CURR_FUNC_STACK_OFFSET = 0;
      CURR_FUNC_IF_BRANCH_ID = 0;
      CURR_FUNC_WHILE_BRANCH_ID = 0;
      free_id_list();
      IS_TYPE_FOR_FUNC_RET = true;
      break;
    case ARRAY_VAR_NODE:
      mips_allocate_sub_stack((node->attr.arr.size*4)+4);
      write_empty_line();
      CURR_FUNC_STACK_OFFSET += (node->attr.arr.size*4)+4;
      mips_move_stack_addr_to_temp(0, CURR_FUNC_STACK_OFFSET-4);
      mips_store_stack_from_temp_reg(CURR_FUNC_STACK_OFFSET, 0);
      add_id_to_list(node->attr.arr.name, CURR_FUNC_STACK_OFFSET);
      break;
    case ARRAY_PARAM_NODE:
      mips_push_func_arg(CURR_FUNC_ARG_COUNT);
      CURR_FUNC_STACK_OFFSET += 4;
      add_id_to_list(node->attr.name, CURR_FUNC_STACK_OFFSET);
      CURR_FUNC_ARG_COUNT++;
      break;
    case PARAM_NODE:
      if(node->attr.type != VOID_TYPE) {
        mips_push_func_arg(CURR_FUNC_ARG_COUNT);
        CURR_FUNC_STACK_OFFSET += 4;
        add_id_to_list(node->attr.name, CURR_FUNC_STACK_OFFSET);
        CURR_FUNC_ARG_COUNT++;
      }
      break;
    default: panic_exit("\"compile_node\" reached unreachable node"); // should never happen
  }

  if(node->if_label_after != NULL) {
    mips_write_label(node->if_label_after);
  }
}

static void compile_assign_node(ast_node_t* node, int temp_reg)
{
  if(node->child[1]->type == CALC_NODE)
    compile_calc_node(node->child[1], 0);
  else if(node->child[1]->type == NUM_NODE)
    mips_li_to_temp_reg(temp_reg, node->child[1]->attr.val);
  else if(node->child[1]->type == ID_NODE) {
    int offset = get_id_offset(node->child[1]->attr.name);
    mips_load_stack_to_temp_reg(temp_reg, offset);
  }
  else if(node->child[1]->type == ARRAY_ID_NODE) {
    compile_array_expr(node->child[1]->child[0], temp_reg+1);
    int offset = get_id_offset(node->child[1]->attr.name);
    mips_load_stack_to_temp_reg(temp_reg, offset);
    mips_add_temp_regs(temp_reg, temp_reg+1);
    mips_lw_temp_regs(temp_reg, temp_reg);
  }
  else if(node->child[1]->type == ASSIGN_NODE) {
    compile_assign_node(node->child[1], temp_reg);
  }
  else {
    compile_call_node(node->child[1], temp_reg);
  }

  if(node->child[0]->type == ID_NODE) {
    int offset = get_id_offset(node->child[0]->attr.name);
    mips_store_stack_from_temp_reg(offset, temp_reg);
  }
  else { // ARRAY_ID_NODE
    compile_array_expr(node->child[0]->child[0], temp_reg+2);
    int offset = get_id_offset(node->child[0]->attr.name);
    mips_load_stack_to_temp_reg(temp_reg+1, offset);
    mips_add_temp_regs(temp_reg+1, temp_reg+2);
    mips_sw_temp_regs(temp_reg, temp_reg+1);
  }
}

static void compile_calc_node(ast_node_t* node, int temp_reg)
{
  bool saved_reg1, saved_reg2;
  saved_reg1 = false; saved_reg2 = false;

  if(node->child[0]->type == CALC_NODE)
    compile_calc_node(node->child[0], temp_reg);
  else if(node->child[0]->type == NUM_NODE)
    mips_li_to_temp_reg(temp_reg, node->child[0]->attr.val);
  else if(node->child[0]->type == ID_NODE) {
    int offset = get_id_offset(node->child[0]->attr.name);
    mips_load_stack_to_temp_reg(temp_reg, offset);
  }
  else if(node->child[0]->type == ARRAY_ID_NODE) {
    compile_array_expr(node->child[0]->child[0], temp_reg+2);
    int offset = get_id_offset(node->child[0]->attr.name);
    mips_load_stack_to_temp_reg(temp_reg, offset);
    mips_add_temp_regs(temp_reg, temp_reg+2);
    mips_lw_temp_regs(temp_reg, temp_reg);
  }
  else { // CALL_NODE
    compile_call_node(node->child[0], temp_reg);
    saved_reg1 = true;
  }

  if(node->child[2]->type == CALC_NODE)
    compile_calc_node(node->child[2], temp_reg+1);
  else if(node->child[2]->type == NUM_NODE)
    mips_li_to_temp_reg(temp_reg+1, node->child[2]->attr.val);
  else if(node->child[2]->type == ID_NODE) {
    int offset = get_id_offset(node->child[2]->attr.name);
    mips_load_stack_to_temp_reg(temp_reg+1, offset);
  }
  else if(node->child[2]->type == ARRAY_ID_NODE) {
    compile_array_expr(node->child[2]->child[0], temp_reg+2);
    int offset = get_id_offset(node->child[2]->attr.name);
    mips_load_stack_to_temp_reg(temp_reg+1, offset);
    mips_add_temp_regs(temp_reg+1, temp_reg+2);
    mips_lw_temp_regs(temp_reg+1, temp_reg+1);
  }
  else { // CALL_NODE
    compile_call_node(node->child[2], temp_reg+1);
    saved_reg2 = true;
  }

  if(node->child[1]->type != OP_NODE) {
    panic_exit("\"compile_calc_node\" reached unreachable node");
  }

  if(saved_reg1)
    mips_move_saved_to_temp(temp_reg, temp_reg);
  if(saved_reg2)
    mips_move_saved_to_temp(temp_reg+1, temp_reg+1);

  switch(node->child[1]->attr.op) {
    case ADD:
      mips_add_temp_regs(temp_reg, temp_reg+1);
      break;
    case SUBTRACT:
      mips_sub_temp_regs(temp_reg, temp_reg+1);
      break;
    case MULTIPLY:
      mips_mul_temp_regs(temp_reg, temp_reg+1);
      break;
    case DIVIDE:
      mips_div_temp_regs(temp_reg, temp_reg+1);
      break;
    default: // should never happen
      panic_exit("\"compile_calc_node\" reached unreachable node");
      break;
  }
}

static void compile_relop_calc_node(ast_node_t* node)
{
  if(node->child[0]->type == CALC_NODE) {
    compile_calc_node(node->child[0], 0);
  }
  else if(node->child[0]->type == NUM_NODE) {
    mips_li_to_temp_reg(0, node->child[0]->attr.val);
  }
  else if(node->child[0]->type == ARRAY_ID_NODE) {
    compile_array_expr(node->child[0]->child[0], 2);
    int offset = get_id_offset(node->child[0]->attr.name);
    mips_load_stack_to_temp_reg(0, offset);
    mips_add_temp_regs(0, 2);
    mips_lw_temp_regs(0, 0);
  }
  else { // ID_NODE
    int offset = get_id_offset(node->child[0]->attr.name);
    mips_load_stack_to_temp_reg(0, offset);
  }

  if(node->child[2]->type == CALC_NODE) {
    compile_calc_node(node->child[2], 1);
  }
  else if(node->child[2]->type == NUM_NODE) {
    mips_li_to_temp_reg(1, node->child[2]->attr.val);
  }
  else if(node->child[2]->type == ARRAY_ID_NODE) {
    compile_array_expr(node->child[2]->child[0], 2);
    int offset = get_id_offset(node->child[2]->attr.name);
    mips_load_stack_to_temp_reg(1, offset);
    mips_add_temp_regs(1, 2);
    mips_lw_temp_regs(1, 1);
  }
  else { // ID_NODE
    int offset = get_id_offset(node->child[2]->attr.name);
    mips_load_stack_to_temp_reg(1, offset);
  }

  if(node->child[1]->type != OP_NODE) {
    panic_exit("\"compile_relop_calc_node\" reached unreachable node");
  }

  char* label;
  if(node->if_label != NULL) {
    label = node->if_label;
  }
  else {
    label = node->while_end_label;
  }
  switch(node->child[1]->attr.op) { // OPPOSITE CONDITION
    case LT:
      mips_ge_temp_regs(0, 1, label);
      break;
    case LE:
      mips_gt_temp_regs(0, 1, label);
      break;
    case GT:
      mips_le_temp_regs(0, 1, label);
      break;
    case GE:
      mips_lt_temp_regs(0, 1, label);
      break;
    case EQ:
      mips_ne_temp_regs(0, 1, label);
      break;
    case NE:
      mips_eq_temp_regs(0, 1, label);
      break;
    default: // should never happen
      panic_exit("\"compile_relop_calc_node\" reached unreachable node");
      break;
  }
}

static void compile_if_node(ast_node_t* node)
{
  char if_label[100];
  sprintf(if_label, "%sAfterIf%d", CURR_FUNC_NAME, CURR_FUNC_IF_BRANCH_ID);
  if(node->sibling != NULL) {
    node->sibling->if_label = strdup(if_label);
  }

  if(node->child[2] != NULL && node->child[2]->type != COMPOUND_NODE) {
    if(node->if_end_label != NULL) {
      node->child[2]->if_end_label = strdup(node->if_end_label);
      if(node->if_label_after != NULL) {
        node->child[2]->if_label_after = node->if_label_after;
        node->if_label_after = NULL;
      }
    }
    else {
      if(node->sibling == NULL) {
        if(node->if_label_after != NULL) {
          node->child[2]->if_label_after = node->if_label_after;
          node->if_label_after = NULL;
        }
        else {
          node->child[2]->if_label_after = strdup(if_label);
          CURR_FUNC_IF_BRANCH_ID++;
        }
        node->child[2]->if_end_label = strdup(node->child[2]->if_label_after);
      }
      else {
        node->child[2]->if_end_label = strdup(if_label);
        CURR_FUNC_IF_BRANCH_ID++;
      }
    }
    sprintf(if_label, "%sAfterIf%d", CURR_FUNC_NAME, CURR_FUNC_IF_BRANCH_ID);
    node->child[2]->if_label = strdup(if_label);
  }

  // if with no else and no siblings (search last node and put label after)
  if(node->sibling == NULL && node->child[2] == NULL) {
    ast_node_t* aux = node->child[1];
    if(aux->type == COMPOUND_NODE) {
      aux = aux->child[1];
      while(aux->sibling != NULL) { aux = aux->sibling; }
    }
    else {
      while(aux->sibling != NULL) { aux = aux->sibling; }
    }
    if(node->if_label_after != NULL) {
      aux->if_label_after = node->if_label_after;
      strcpy(if_label, node->if_label_after);
      node->if_label_after = NULL;
    }
    else {
      aux->if_label_after = strdup(if_label);
    }
  }

  if(node->sibling == NULL && node->child[2] != NULL && node->child[2]->type == COMPOUND_NODE) {
    ast_node_t* aux = node->child[2]->child[1];
    while(aux->sibling != NULL) { aux = aux->sibling; }

    if(node->if_label_after != NULL) {
      aux->if_label_after = node->if_label_after;
      strcpy(if_label, node->if_label_after);
      node->if_label_after = NULL;
    }
    else {
      aux->if_label_after = strdup(if_label);
      CURR_FUNC_IF_BRANCH_ID++;
    }

    node->child[2]->if_end_label = strdup(aux->if_label_after);

    sprintf(if_label, "%sAfterIf%d", CURR_FUNC_NAME, CURR_FUNC_IF_BRANCH_ID);
    node->child[2]->if_label = strdup(if_label);
  }

  node->child[0]->if_label = strdup(if_label);

  CURR_FUNC_IF_BRANCH_ID++;
}

static void compile_while_node(ast_node_t* node)
{
  char while_label[100], while_end_label[100];

  sprintf(while_label, "%sStartWhile%d", CURR_FUNC_NAME, CURR_FUNC_WHILE_BRANCH_ID);
  sprintf(while_end_label, "%sEndWhile%d", CURR_FUNC_NAME, CURR_FUNC_WHILE_BRANCH_ID);
  CURR_FUNC_WHILE_BRANCH_ID++;

  mips_write_label(while_label);

  if(node->sibling != NULL) {
    node->sibling->while_label = strdup(while_label);
    node->sibling->while_end_label = strdup(while_end_label);
  }

  node->child[0]->while_end_label = strdup(while_end_label);
}

static void compile_return_node(ast_node_t* node)
{
  if(IS_FUNC_MAIN) {
    mips_exit_syscall();
    return;
  }

  if(node->child[0] != NULL) {
    if(node->child[0]->type == ID_NODE) {
      int offset = get_id_offset(node->child[0]->attr.name);
      mips_load_stack_to_temp_reg(0, offset);
    }
    else if(node->child[0]->type == ARRAY_ID_NODE) {
      compile_array_expr(node->child[0]->child[0], 1);
      int offset = get_id_offset(node->child[0]->attr.name);
      mips_load_stack_to_temp_reg(0, offset);
      mips_add_temp_regs(0, 1);
      mips_lw_temp_regs(0, 0);
    }
    else if(node->child[0]->type == NUM_NODE) {
      mips_li_to_temp_reg(0, node->child[0]->attr.val);
    }
    else if(node->child[0]->type == CALC_NODE) {
      compile_calc_node(node->child[0], 0);
    }
    else { // CALL_NODE
      compile_call_node(node->child[0], 0);
      write_empty_line();
    }
  }
  mips_return(0, CURR_FUNC_STACK_OFFSET);
}

static void compile_call_node(ast_node_t* node, int temp_reg)
{
  ast_node_t* aux = node->child[0];

  for(int i = 0; aux != NULL; i++) {
    if(aux->type == CALC_NODE)
      compile_calc_node(aux, temp_reg);
    else if(aux->type == NUM_NODE)
      mips_li_to_temp_reg(temp_reg, aux->attr.val);
    else if(aux->type == ARRAY_ID_NODE) {
      compile_array_expr(aux->child[0], temp_reg+1);
      int offset = get_id_offset(aux->attr.name);
      mips_load_stack_to_temp_reg(temp_reg, offset);
      mips_add_temp_regs(temp_reg, temp_reg+1);
      mips_lw_temp_regs(temp_reg, temp_reg);
    }
    else { // ID_NODE
      int offset = get_id_offset(aux->attr.name);
      mips_load_stack_to_temp_reg(temp_reg, offset);
    }

    mips_load_temp_reg_arg(i, temp_reg);
    aux = aux->sibling;
  }

  mips_call_func(node->attr.name);
  mips_store_return_saved_reg(temp_reg);
  mips_move_saved_to_temp(temp_reg, temp_reg);
}

static void compile_array_expr(ast_node_t* node, int temp_reg) {
    if(node->type == CALC_NODE)
      compile_calc_node(node, temp_reg);
    else if(node->type == NUM_NODE)
      mips_li_to_temp_reg(temp_reg, node->attr.val);
    else if(node->type == ARRAY_ID_NODE) {
      compile_array_expr(node->child[0], temp_reg+1);
      int offset = get_id_offset(node->attr.name);
      mips_load_stack_to_temp_reg(temp_reg, offset);
      mips_add_temp_regs(temp_reg, temp_reg+1);
      mips_lw_temp_regs(temp_reg, temp_reg);
    }
    else { // ID_NODE
      int offset = get_id_offset(node->attr.name);
      mips_load_stack_to_temp_reg(temp_reg, offset);
    }

    mips_mul_temp_reg_imm(temp_reg, 4);
}

static void add_id_to_list(char* id, int offset)
{
  id_list_node* node = (id_list_node*) malloc(sizeof(id_list_node));
  node->id = id;
  node->offset = offset;
  id_list_node* temp = ID_LIST_HEAD;
  ID_LIST_HEAD = node;
  ID_LIST_HEAD->next = temp;
}

static int get_id_offset(char* id)
{
  id_list_node* node = ID_LIST_HEAD;
  while(node != NULL) {
    if(strcmp(node->id, id) == 0) {
      return node->offset;
    }
    node = node->next;
  }
  panic_exit("Unexpected ID found");
  return 0;
}

static void free_id_list()
{
  id_list_node* node = ID_LIST_HEAD;
  while(node != NULL) {
    id_list_node* temp = node;
    node = node->next;
    free(temp);
  }
  ID_LIST_HEAD = NULL;
}

static void write_empty_line()
{
  fprintf(PRG_FILE, "\n");
}

static void panic_exit(char* error_msg)
{
  fprintf(stderr, "%s\n", error_msg);
  exit(1);
}
