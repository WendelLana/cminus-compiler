%{
    #include "y.tab.h"

    typedef struct table_entry_struct {
        char* lexeme;
        int token_type;
        int line_num;
        struct table_entry_struct* next;
    } table_entry_t;

    typedef struct {
        table_entry_t* entry;
    } table_t;

    void add_to_table(const char* lexeme, int token_type);
    table_entry_t* create_entry(const char* lexeme, int token_type);

    int countn = 0; // or keeping track of the line number
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

"int"               { add_to_table(yytext, INT); return INT; }
"void"              { add_to_table(yytext, VOID); return VOID; }
"return"            { add_to_table(yytext, RETURN); return RETURN; }
"if"	            { add_to_table(yytext, IF); return IF; }
"else"	            { add_to_table(yytext, ELSE); return ELSE; }
"while"             { add_to_table(yytext, WHILE); return WHILE; }
{digit}+            { add_to_table(yytext, NUM); return NUM; }
{letter}+           { add_to_table(yytext, ID); return ID; }
"<="                { add_to_table(yytext, LE); return LE; }
">="                { add_to_table(yytext, GE); return GE; }
"=="                { add_to_table(yytext, EQ); return EQ; }
"!="                { add_to_table(yytext, NE); return NE; }
">"	                { add_to_table(yytext, GT); return GT; }
"<"	                { add_to_table(yytext, LT); return LT; }
"="                 { add_to_table(yytext, ASSIGN); return ASSIGN; }
"+"                 { add_to_table(yytext, ADD); return ADD; }
"-"                 { add_to_table(yytext, SUBTRACT); return SUBTRACT; }
"/"                 { add_to_table(yytext, DIVIDE); return DIVIDE; }
"*"                 { add_to_table(yytext, MULTIPLY); return MULTIPLY; }
";"                 { add_to_table(yytext, SEMI); return SEMI; }
","                 { add_to_table(yytext, COMMA); return COMMA; }
"("                 { add_to_table(yytext, LPAREN); return LPAREN; }
")"                 { add_to_table(yytext, RPAREN); return RPAREN; }
"["                 { add_to_table(yytext, LBRACKET); return LBRACKET; }
"]"                 { add_to_table(yytext, RBRACKET); return RBRACKET; }
"{"                 { add_to_table(yytext, LBRACE); return LBRACE; }
"}"                 { add_to_table(yytext, RBRACE); return RBRACE; }
{whitespace}        {}
{mlcomment}         {}
{incmpltcomment}    { add_to_table("/*", ERROR); }
{slcomment}         { add_to_table("//", ERROR); }
[\n]                { countn++; }
.	                { add_to_table(yytext, ERROR); }

%%

void add_to_table(const char* lexeme, int token_type) 
{
    if(table.entry == NULL) {
        table.entry = create_entry(lexeme, token_type);
    }
    else {
        table_entry_t* entry = table.entry;
        while(entry->next != NULL) {
            entry = entry->next;
        }
        entry->next = create_entry(lexeme, token_type);
    }
}

table_entry_t* create_entry(const char* lexeme, int token_type)
{
    table_entry_t* entry = (table_entry_t*) malloc(sizeof(table_entry_t));
    entry->lexeme = strdup(lexeme);
    entry->token_type = token_type;
    entry->line_num = countn;
    entry->next = NULL;
    return entry;
}

int yywrap() 
{
    return 1;
}

