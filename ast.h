#ifndef AST_H
#define AST_H

#include <stdbool.h>

typedef enum {
    IF_NODE, WHILE_NODE, ASSIGN_NODE, RETURN_NODE, COMPOUND_NODE,
    OP_NODE, NUM_NODE, ID_NODE, TYPE_NODE, ARRAY_ID_NODE, CALL_NODE,
    CALC_NODE, VAR_NODE, FUNC_NODE, ARRAY_VAR_NODE, ARRAY_PARAM_NODE,
    PARAM_NODE
} ast_node_type_t;
typedef enum {
    VOID_TYPE, INT_TYPE
} ast_var_type_t;

typedef struct {
    int type;
    char* name;
    int size;
} ast_array_t;

typedef union {
    int op;
    ast_var_type_t type;
    int val;
    char* name;
    ast_array_t arr;
} ast_node_attr_t;

typedef struct node_struct {
    struct node_struct* sibling;
    struct node_struct* child[5];
    int line_num;
    ast_node_type_t type;
    ast_node_attr_t attr;
    char* if_label;
    char* if_label_after;
    char* if_end_label;
    char* while_label;
    char* while_end_label;
} ast_node_t;

extern ast_node_t* ast_head;

#endif // AST_H
