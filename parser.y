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

void print_table()
{
    printf("\n\n");
    printf(" PHASE 1: LEXICAL ANALYSIS\n\n");
    printf(" LEXEME  TOKEN  ATTR  LINE\n");
    printf(" _______________________________________\n\n");

    table_entry_t* entry = table.entry;
    while(entry != NULL)
    {
        printf(" %s\t%d\t", entry->lexeme, entry->token_type);
        if(entry->token_type == RELOP) {
            printf("%u\t", entry->attribute.relop);
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
