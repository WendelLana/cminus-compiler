%{
    #include "y.tab.h"

    typedef enum {
        IF,
        ELSE,
        INT,
        RETURN,
        VOID,
        WHILE,
        ID,
        NUM,
        RELOP,
        SEMI,
        COMMA,
        LPAREN,
        RPAREN,
        LBRACKET,
        RBRACKET,
        LBRACE,
        RBRACE,
        ERROR,
    } token_t;

    typedef enum {
        LT,
        LE,
        EQ,
        NE,
        GT,
        GE,
        ASSIGN,
        ADD,
        SUBTRACT,
        MULTIPLY,
        DIVIDE,
    } relop_attribute_t;

    typedef union {
        relop_attribute_t relop;
        size_t table_offset;
    } attribute_t;

    typedef struct table_entry_struct {
        char* lexeme;
        token_t token_type;
        attribute_t attribute;
        int line_num;
        struct table_entry_struct* next;
    } table_entry_t;

    typedef struct {
        table_entry_t* entry;
    } table_t;

    void add_to_table(const char* lexeme, token_t token_type, attribute_t attribute);
    table_entry_t* create_entry(const char* lexeme, token_t token_type, attribute_t attribute);

    int countn = 0; // or keeping track of the line number
    size_t table_offset = 0;
    table_t table = { .entry = NULL }; // symbol table
%}

%option yylineno
letter         [a-zA-Z]
digit          [0-9]
mlcomment      "/*"[^*]*"*/"
incmpltcomment "/*"[^*]*
slcomment      "//"[^\n\r]*
whitespace     [\t\v\f\r\s ]+

%%

"int"               { attribute_t attr; add_to_table(yytext, INT, attr); }
"void"              { attribute_t attr; add_to_table(yytext, VOID, attr); }
"return"            { attribute_t attr; add_to_table(yytext, RETURN, attr); }
"if"	            { attribute_t attr; add_to_table(yytext, IF, attr); }
"else"	            { attribute_t attr; add_to_table(yytext, ELSE, attr); }
"while"             { attribute_t attr; add_to_table(yytext, WHILE, attr); }
[-]?{digit}+        { attribute_t attr; attr.table_offset = table_offset; add_to_table(yytext, NUM, attr); }
{letter}+           { attribute_t attr; attr.table_offset = table_offset; add_to_table(yytext, ID, attr); }
"<="                { attribute_t attr; attr.relop = LE; add_to_table(yytext, RELOP, attr); }
">="                { attribute_t attr; attr.relop = GE; add_to_table(yytext, RELOP, attr); }
"=="                { attribute_t attr; attr.relop = EQ; add_to_table(yytext, RELOP, attr); }
"!="                { attribute_t attr; attr.relop = NE; add_to_table(yytext, RELOP, attr); }
">"	                { attribute_t attr; attr.relop = GT; add_to_table(yytext, RELOP, attr); }
"<"	                { attribute_t attr; attr.relop = LT; add_to_table(yytext, RELOP, attr); }
"="                 { attribute_t attr; attr.relop = ASSIGN; add_to_table(yytext, RELOP, attr); }
"+"                 { attribute_t attr; attr.relop = ADD; add_to_table(yytext, RELOP, attr); }
"-"                 { attribute_t attr; attr.relop = SUBTRACT; add_to_table(yytext, RELOP, attr); }
"/"                 { attribute_t attr; attr.relop = DIVIDE; add_to_table(yytext, RELOP, attr); }
"*"                 { attribute_t attr; attr.relop = MULTIPLY; add_to_table(yytext, RELOP, attr); }
";"                 { attribute_t attr; add_to_table(yytext, SEMI, attr); }
","                 { attribute_t attr; add_to_table(yytext, COMMA, attr); }
"("                 { attribute_t attr; add_to_table(yytext, LPAREN, attr); }
")"                 { attribute_t attr; add_to_table(yytext, RPAREN, attr); }
"["                 { attribute_t attr; add_to_table(yytext, LBRACKET, attr); }
"]"                 { attribute_t attr; add_to_table(yytext, RBRACKET, attr); }
"{"                 { attribute_t attr; add_to_table(yytext, LBRACE, attr); }
"}"                 { attribute_t attr; add_to_table(yytext, RBRACE, attr); }
{whitespace}        {}
{mlcomment}         {}
{incmpltcomment}    { attribute_t attr; add_to_table("/*", ERROR, attr); }
{slcomment}         { attribute_t attr; add_to_table("//", ERROR, attr); }
[\n]                { countn++; }
.	                { attribute_t attr; add_to_table(yytext, ERROR, attr); }

%%

void add_to_table(const char* lexeme, token_t token_type, attribute_t attribute) 
{
    if(table.entry == NULL) {
        table.entry = create_entry(lexeme, token_type, attribute);
    }
    else {
        table_entry_t* entry = table.entry;
        while(entry->next != NULL) {
            entry = entry->next;
        }
        entry->next = create_entry(lexeme, token_type, attribute);
    }

    table_offset++;
}

table_entry_t* create_entry(const char* lexeme, token_t token_type, attribute_t attribute)
{
    table_entry_t* entry = (table_entry_t*) malloc(sizeof(table_entry_t));
    entry->lexeme = strdup(lexeme);
    entry->token_type = token_type;
    entry->attribute = attribute;
    entry->line_num = countn;
    entry->next = NULL;
    return entry;
}

int yywrap() 
{
    return 1;
}
