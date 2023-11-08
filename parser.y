%{
    #include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include<ctype.h>
    #include"lex.yy.c"
    
    void yyerror(const char *s);
    int yylex();
    int yywrap();
    
    void print_table();
    void free_table();

    extern int countn;
    extern table_t table; 
%}

%%

program:

%%

int main() 
{
    yyparse();
    print_table();
    free_table();
}

const char* tokenTypeToString(token_t token) 
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
      case RELOP: return "RELOP";
      case SEMI: return "SEMI";
      case COMMA: return "COMMA";
      case LPAREN: return "LPAREN";
      case RPAREN: return "RPAREN";
      case LBRACKET: return "LBRACKET";
      case RBRACKET: return "RBRACKET";
      case LBRACE: return "LBRACE";
      case RBRACE: return "RBRACE";
      case ERROR: return "ERROR";
   }
}

const char* relopAttrToString(relop_attribute_t relop)
{
    switch (relop) 
    {
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
    }
}

void print_table()
{
    printf("\n\n");
    printf(" PART 1: LEXICAL ANALYSIS\n\n");
    printf(" LEXEME  TOKEN  ATTR  LINE\n");
    printf(" _______________________________________\n\n");

    table_entry_t* entry = table.entry;
    while(entry != NULL)
    {
        printf(" %s\t%s\t", entry->lexeme, tokenTypeToString(entry->token_type));
        if(entry->token_type == RELOP) {
            printf("%s\t", relopAttrToString(entry->attribute.relop));
        }
        else if(entry->token_type == ID || entry->token_type == NUM) {
            printf("%llu\t", (long long unsigned int) entry->attribute.table_offset);
        }
        else {
            printf("\t");
        }
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

void yyerror(const char* msg) 
{
    fprintf(stderr, "%s\n", msg);
}
