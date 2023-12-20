#ifndef AST_H
#define AST_H

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
} ast_node_t;

#endif // AST_H
