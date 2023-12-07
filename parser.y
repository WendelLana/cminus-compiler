%{
    #define YYPARSER

    #include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include<ctype.h>

    typedef enum {
      IF_NODE, WHILE_NODE, ASSIGN_NODE, RETURN_NODE, COMPOUND_NODE,
      OP_NODE, NUM_NODE, ID_NODE, TYPE_NODE, ARRAY_ID_NODE, CALL_NODE,
      CALC_NODE, VAR_NODE, FUNC_NODE, ARRAY_VAR_NODE, ARRAY_PARAM_NODE,
      PARAM_NODE
    } node_type_t;
    typedef enum {
      VOID_TYPE, INT_TYPE
    } var_type_t;

    typedef struct {
        int type;
        char* name;
        int size;
    } array_t;

    typedef union {
      int op;
      var_type_t type;
      int val;
      char* name;
      array_t arr;
    } node_attr_t;

    typedef struct node_struct {
        struct node_struct* sibling;
	      struct node_struct* child[5];
        int line_num;
        node_type_t type;
        node_attr_t attr;
    } node_t;
    #define YYSTYPE node_t*

    void yyerror(const char *s);
    int yywrap();

    void print_table();
    void free_table();
    void printTree();
    void printTreeToken();
    void free_tree();
    node_t* new_node(node_type_t node_type, node_attr_t* node_attr);;
    char* copyString();

    #include"lex.yy.c"

    extern int countn;
    extern table_t table;
    static table_entry_t* curr_entry = NULL;
    static int savedNumber;
    static char* savedName;
    static int savedLineNo;
    node_t* head;
%}

%token IF ELSE INT RETURN VOID WHILE
%token ID NUM
%token LT LE GT GE EQ NE
%token SEMI LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET
%left ADD SUBTRACT
%left MULTIPLY DIVIDE COMMA
%right ASSIGN
%token ERROR

%nonassoc ELSE



%%
program : declarationlist { head = $1; }
        | error {  }
        ;

declarationlist : declarationlist declaration
                { YYSTYPE t = $1;
                    if (t != NULL) {
                       while (t->sibling != NULL) { t = t->sibling; }
                       t->sibling = $2;
                       $$ = $1;
                     } else {
                       $$ = $2;
                     }
                }
                | declaration { $$ = $1; }
                ;

declaration : var_declaration { $$ = $1; }
            | fun_declaration { $$ = $1; }
            ;

id : ID
     { savedName = copyString(yytext);
       savedLineNo = countn;
     }
   ;

num : NUM
      { savedNumber = atoi(yytext);
        savedLineNo = countn;
      }
    ;

var_declaration : type_specifier id SEMI
                {   node_attr_t attr;
                    attr.name = savedName;
                    $$ = new_node(VAR_NODE, &attr);
                    $$->child[0] = $1;
                }
                | type_specifier id [ NUM ]
                {   node_attr_t attr;
                    attr.arr.name = savedName;
                    attr.arr.size = savedNumber;
                    $$ = new_node(ARRAY_VAR_NODE, &attr);
                    $$->child[0] = $1;
                }
                ;

type_specifier : INT
                 { node_attr_t attr;
                   attr.type = INT_TYPE;
                   $$ = new_node(TYPE_NODE, &attr);
                 }
               | VOID
                 { node_attr_t attr;
                   attr.type = VOID_TYPE;
                   $$ = new_node(TYPE_NODE, &attr);
                 }
               ;

fun_declaration : type_specifier id
                {
                   node_attr_t attr;
                   attr.name = savedName;
                   $$ = new_node(FUNC_NODE, &attr);
                 }
                 LPAREN params RPAREN compound_stmt
                 { $$ = $3;
                   $$->child[0] = $1;
                   $$->child[1] = $5;
                   $$->child[2] = $7;
                 }
                ;

params : param_list { $$ = $1; }
       | VOID
         { node_attr_t attr;
           attr.type = VOID_TYPE;
           $$ = new_node(PARAM_NODE, &attr);
         }
       |
         { node_attr_t attr;
           attr.type = VOID_TYPE;
           $$ = new_node(PARAM_NODE, &attr);
         }
       ;

param_list : param_list COMMA param
             { YYSTYPE t = $1;
               if (t != NULL) {
                 while (t->sibling != NULL) { t = t->sibling; }
                 t->sibling = $3;
                 $$ = $1;
               } else {
                 $$ = $2;
               }
             }
           | param { $$ = $1; }
           ;

param : type_specifier id
        { node_attr_t attr;
          attr.name = savedName;
          $$ = new_node(PARAM_NODE, &attr);
          $$->child[0] = $1;
        }
      | type_specifier id LBRACKET RBRACKET
        { node_attr_t attr;
          attr.name = copyString(savedName);
          $$ = new_node(ARRAY_PARAM_NODE, &attr);
          $$->child[0] = $1;
        }
      ;

compound_stmt : LBRACE local_declarations statement_list RBRACE
                { $$ = new_node(COMPOUND_NODE, NULL);
                  $$->child[0] = $2;
                  $$->child[1] = $3;
                }
              ;

local_declarations : local_declarations var_declaration
                     { YYSTYPE t = $1;
                       if (t != NULL) {
                         while (t->sibling != NULL) { t = t->sibling; }
                         t->sibling = $2;
                         $$ = $1;
                       } else {
                         $$ = $2;
                       }
                     }
                   | { $$ = NULL; }
                   ;

statement_list : statement_list statement
                 { YYSTYPE t = $1;
                   if (t != NULL) {
                     while (t->sibling != NULL) { t = t->sibling; }
                    t->sibling = $2;
                    $$ = $1;
                   } else {
                     $$ = $2;
                   }
                 }
               | { $$ = NULL; }
               ;

statement : expression_stmt { $$ = $1; }
          | compound_stmt { $$ = $1; }
          | selection_stmt { $$ = $1; }
          | iteration_stmt { $$ = $1; }
          | return_stmt { $$ = $1; }
          ;

expression_stmt : expression SEMI { $$ = $1; }
                | SEMI { $$ = NULL; }
                ;

selection_stmt : IF LPAREN expression RPAREN statement
                 { $$ = new_node(IF_NODE, NULL);
                   $$->child[0] = $3;
                   $$->child[1] = $5;
                 }
               | IF LPAREN expression RPAREN statement ELSE statement
                 { $$ = new_node(IF_NODE, NULL);
                   $$->child[0] = $3;
                   $$->child[1] = $5;
                   $$->child[2] = $7;
                 }
               ;

iteration_stmt : WHILE LPAREN expression RPAREN statement
                 { $$ = new_node(WHILE_NODE, NULL);
                   $$->child[0] = $3;
                   $$->child[1] = $5;
                 }
               ;

return_stmt : RETURN SEMI
              { $$ = new_node(RETURN_NODE, NULL);
              }
            | RETURN expression SEMI
              { $$ = new_node(RETURN_NODE, NULL);
                $$->child[0] = $2;
              }
            ;

expression : var ASSIGN expression
             { $$ = new_node(ASSIGN_NODE, NULL);
               $$->child[0] = $1;
               $$->child[1] = $3;
             }
           | simple_expression { $$ = $1; }
           ;

var : id
      { node_attr_t attr;
        attr.name = savedName;
        $$ = new_node(ID_NODE, &attr);
      }
    | id {
        node_attr_t attr;
        attr.name = savedName;
        $$ = new_node(ARRAY_ID_NODE, &attr);
      } LBRACKET expression RBRACKET
      {
        $$ = $2;
        $$->child[0] = $4;
      }
    ;

simple_expression : sum_expression relop sum_expression
                    { $$ = new_node(CALC_NODE, NULL);
                      $$->child[0] = $1;
                      $$->child[1] = $2;
                      $$->child[2] = $3;
                    }
                  | sum_expression { $$ = $1; }
                  ;

relop : LT
        { node_attr_t attr;
          attr.op = LT;
          $$ = new_node(OP_NODE, &attr);
        }
      | LE
        { node_attr_t attr;
          attr.op = LE;
          $$ = new_node(OP_NODE, &attr);
        }
      | GT
        { node_attr_t attr;
          attr.op = GT;
          $$ = new_node(OP_NODE, &attr);
        }
      | GE
        { node_attr_t attr;
          attr.op = GE;
          $$ = new_node(OP_NODE, &attr);
        }
      | EQ
        { node_attr_t attr;
          attr.op = EQ;
          $$ = new_node(OP_NODE, &attr);
        }
      | NE
        { node_attr_t attr;
          attr.op = NE;
          $$ = new_node(OP_NODE, &attr);
        }
      ;

sum_expression : sum_expression addop term
                      { $$ = new_node(CALC_NODE, NULL);
                        $$->child[0] = $1;
                        $$->child[1] = $2;
                        $$->child[2] = $3;
                      }
                    | term { $$ = $1; }
                    ;

addop : ADD
        { node_attr_t attr;
          attr.op = ADD;
          $$ = new_node(OP_NODE, &attr);
        }
      | SUBTRACT
        { node_attr_t attr;
          attr.op = SUBTRACT;
          $$ = new_node(OP_NODE, &attr);
        }
      ;

term : term mulop factor
       { $$ = new_node(CALC_NODE, NULL);
         $$->child[0] = $1;
         $$->child[1] = $2;
         $$->child[2] = $3;
       }
     | factor { $$ = $1; }
     ;

mulop : MULTIPLY
        { node_attr_t attr;
          attr.op = MULTIPLY;
          $$ = new_node(OP_NODE, &attr);
        }
      | DIVIDE
        { node_attr_t attr;
          attr.op = DIVIDE;
          $$ = new_node(OP_NODE, &attr);
        }
      ;

factor : LPAREN expression RPAREN { $$ = $2; }
       | var { $$ = $1; }
       | call { $$ = $1; }
       | num
         { node_attr_t attr;
           attr.type = INT_TYPE;
           attr.val = atoi(yytext);
           $$ = new_node(NUM_NODE, &attr);
         };
       ;

call : id {
         node_attr_t attr;
         attr.name = savedName;
         $$ = new_node(CALL_NODE, &attr);
         } LPAREN args RPAREN {
           $$ = $2;
           $$->child[0] = $4;
       }
     ;

args : arg_list { $$ = $1; }
     | { $$ = NULL; }
     ;

arg_list : arg_list COMMA expression
           { YYSTYPE t = $1;
             if (t != NULL) {
               while (t->sibling != NULL) { t = t->sibling; }
               t->sibling = $3;
               $$ = $1;
             } else {
               $$ = $3;
             }
           }
         | expression { $$ = $1; }
         ;

%%

int main()
{
    yyparse();
    printTree();
    free_tree(head);
}

const char* tokenTypeToString(int token)
{
   switch (token)
   {
      case IF: return "IF";
      case ELSE: return "ELSE";
      case INT: return "INT";
      case RETURN: return "RETURN";
      case VOID: return "VOID";
      case WHILE: return "WHILE";
      case ID: return "ID";
      case NUM: return "NUM";
      case SEMI: return "SEMI";
      case COMMA: return "COMMA";
      case LPAREN: return "LPAREN";
      case RPAREN: return "RPAREN";
      case LBRACKET: return "LBRACKET";
      case RBRACKET: return "RBRACKET";
      case LBRACE: return "LBRACE";
      case RBRACE: return "RBRACE";
      case LT: return "LT";
      case LE: return "LE";
      case EQ: return "EQ";
      case NE: return "NE";
      case GT: return "GT";
      case GE: return "GE";
      case ASSIGN: return "ASSIGN";
      case ADD: return "ADD";
      case SUBTRACT: return "SUBTRACT";
      case MULTIPLY: return "MULTIPLY";
      case DIVIDE: return "DIVIDE";
      case ERROR: return "ERROR";
   }
}

void print_table()
{
    printf("\n\n");
    printf("              PART 1: LEXICAL ANALYSIS\n\n");
    printf("    LEXEME      TOKEN          ATTR           LINE\n");
    printf(" ______________________________________________________\n\n");

    table_entry_t* entry = table.entry;
    while(entry != NULL)
    {
        printf(" %-10s\t%-8s\t", entry->lexeme, tokenTypeToString(entry->token_type));
        printf("%d\t\n", entry->line_num);
        entry = entry->next;
    }

    printf("\n\n");
}

void free_table()
{
    table_entry_t* entry = table.entry;
    while(entry != NULL)
    {
        table_entry_t* temp = entry;
        entry = entry->next;
        free(temp->lexeme);
        free(temp);
    }
}

node_t* new_node(node_type_t node_type, node_attr_t* node_attr)
{
  node_t* node = (node_t*) malloc(sizeof(node_t));
  node->sibling = NULL;
  for(int i = 0; i < 5; i++) node->child[i] = NULL;
  node->line_num = countn;
  node->type = node_type;
  if(node_attr != NULL) node->attr = *node_attr;
  return node;
}

static int indentno = 0;
/* macros to increase/decrease indentation */
#define INDENT indentno+=2
#define UNINDENT indentno-=2

static void printSpaces(void) {
  int i;
  for (i=0;i<indentno;i++)
    fprintf(stderr," ");
}

void printTree()
{
    printf("\n\n");
    printf("              PART 2: SYNTAX TREE\n");
    printf(" ______________________________________________________\n\n");
    printf("Program\n");
    printTreeToken(head);
}

const char* var_type_to_str(var_type_t var_type)
{
  switch(var_type)
  {
    case VOID_TYPE: return "Void";
    case INT_TYPE: return "Int";
  }
}

void printTreeToken(YYSTYPE tree)
{
  INDENT;
  while (tree != NULL) {
    if (tree->type != TYPE_NODE) printSpaces();
    switch (tree->type)
    {
      case IF_NODE:
        printf("If\n");
        break;
      case WHILE_NODE:
        printf("While\n");
        break;
      case ASSIGN_NODE:
        printf("Assign\n");
        break;
      case RETURN_NODE:
        printf("Return\n");
        break;
      case COMPOUND_NODE:
        printf("Compound statement\n");
        break;
      case OP_NODE:
        printf("Op: %s\n", tokenTypeToString(tree->attr.op));
        break;
      case NUM_NODE:
        printf("Const: %d\n",tree->attr.val);
        break;
      case ID_NODE:
        printf("Id: %s\n",tree->attr.name);
        break;
      case TYPE_NODE:
        printf("Type: %s\n", var_type_to_str(tree->attr.type));
        break;
      case ARRAY_ID_NODE:
        printf("ArrId \n");
        break;
      case CALL_NODE:
        printf("Call Function: %s\n", tree->attr.name);
        break;
      case CALC_NODE:
        printf("Calc: \n");
        break;
      case VAR_NODE:
        printf("Variable Declaration:");
        printf(" %s;\n", tree->attr.name);
        break;
      case FUNC_NODE:
        printf("Function Declaration: %s()\n", tree->attr.name);
        break;
      case ARRAY_VAR_NODE:
        printf("Array Variable Declaration: %s[%d];\n", tree->attr.arr.name, tree->attr.arr.size);
        break;
      case ARRAY_PARAM_NODE:
        printf("Array Parameter: %s\n", tree->attr.name);
        break;
      case PARAM_NODE:
        printf("Parameter: ");
        if(tree->attr.type == VOID_TYPE) {
          printf("Void\n");
        }
        else if(tree->attr.type == INT_TYPE) {
          printf("Int\n");
        }
        else if(tree->attr.name != NULL) {
          printf("%s\n", tree->attr.name);
        }
        break;
    }
    for (int i=0; i<5; i++) if (tree->child[i] != NULL) printTreeToken(tree->child[i]);
    tree = tree->sibling;
  }
  UNINDENT;
}

void free_tree(YYSTYPE entry)
{
    while(entry != NULL)
    {
        node_t* temp = entry;
        for (int i=0;i<5;i++) if (entry->child[i] != NULL) free_tree(entry->child[i]);
        entry = entry->sibling;
        free(temp);
    }
}

/* Function copyString allocates and makes a new
 * copy of an existing string
 */
char* copyString(char* s)
{
  int n;
  char * t;
  if (s==NULL) return NULL;
  n = strlen(s)+1;
  t = malloc(n);
  if (t==NULL)
    fprintf(stderr,"Out of memory error at line %d\n",countn);
  else strcpy(t,s);
  return t;
}

void yyerror(const char* msg)
{
    fprintf(stderr, "Error \"%s\" at line %d, token:\"%s\"\n", msg, countn, yytext);
}