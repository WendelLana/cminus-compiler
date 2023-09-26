%option noyywrap
%{
#define ID 1
#define NUM 2
#define ELSE  3
#define	IF 4
#define INT 5
#define	RETURN 6
#define VOID 7
#define	WHILE 8
#define RELOP 9
#define SEMI 10
#define COMMA 11
#define LPAREN 12
#define RPAREN 13
#define LBRACKET 14
#define RBRACKET 15
#define LBRACE 16
#define RBRACE 17
#define error 18

typedef struct SymbolTable {
    char* lexeme,
    int type,
    char* attr
} Symbol;

whitespace [\t\n\v\f\r\s ]+
digit [0-9]
letter [A-Z_a-z]

number {digit}+
identifier {letter}+

mlcomment "/*" [^*] ~"*/" | "/*" "*"+ "/"
slcomment "//"[^\n\r]*

%}


%%
/* Keywords */
"else"             { return symbol("else", ELSE); }
"if"               { return symbol("if", IF); }
"int"              { return symbol("int", INT); }
"return"           { return symbol("return", RETURN); }
"void"             { return symbol("void", VOID); }
"while"            { return symbol("while", WHILE); }
/* Special symbols */
"+"                { return symbol("+", RELOP, "PLUS"); }
"-"                { return symbol("-", RELOP, "MINUS"); }
"*"                { return symbol("*", RELOP, "TIMES"); }
"/"                { return symbol("/", RELOP, "OVER"); }
"<"                { return symbol("<", RELOP, "LT"); }
"<="               { return symbol("<=", RELOP, "LE"); }
">"                { return symbol(">", RELOP, "GT"); }
">="               { return symbol(">=", RELOP, "GE"); }
"=="               { return symbol("==", RELOP, "EQ"); }
"!="               { return symbol("!=", RELOP, "NE"); }
"="                { return symbol("=", RELOP, "ASSIGN"); }
";"                { return symbol(";", SEMI); }
","                { return symbol(",", COMMA); }
"("                { return symbol("(", LPAREN); }
")"                { return symbol(")", RPAREN); }
"["                { return symbol("[", LBRACKET); }
"]"                { return symbol("]", RBRACKET); }
"{"                { return symbol("{", LBRACE); }
"}"                { return symbol("}", RBRACE); }
{identifier}       { return symbol("ID", ID, yytext()); }
{number}           { return symbol("NUMBER", NUM, yytext()); }
{whitespace}*      { /* skip whitespace */ }   
{mlcomment}          { /* skip multi-line comment */ }
{slcomment}          { /* skip single-line comment */ }
.                  { return symbol("ERROR", error); }
%%
int main() {
    yylex();
}

Symbol symbol(char* lexeme, int type, char* value) {
    return new Symbol(lexeme, type, value);
}

Symbol symbol(char* lexeme, int type) {
    return new Symbol(lexeme, type);
}