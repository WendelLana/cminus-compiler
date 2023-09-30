%{
#define ID 1
#define NUM 2
#define ELSE  3
#define	IF 4
#define INT 5
#define	RETURN 6
#define VOID 7
#define	WHILE 8
#define LE 9
#define GE 9
#define EQ 9
#define NE 9
#define GT 9
#define LT 9
#define ASSIGN 9
#define ADD 10
#define SUBTRACT 10
#define DIVIDE 10
#define MULTIPLY 10
#define SEMI 10
#define COMMA 11
#define LPAREN 12
#define RPAREN 13
#define LBRACKET 14
#define RBRACKET 15
#define LBRACE 16
#define RBRACE 17
#define ERROR 18
int countn=0;       /* for keeping track of the line number */
%}

%option yylineno
letter         [a-zA-Z]
digit          [0-9]
mlcomment      "/*" [^*] ~"*/" | "/*" "*"+ "/"
slcomment      "//"[^\n\r]*

%%

"int"               { return INT; }
"void"              { return VOID; }
"return"            { return RETURN; }
"if"	            { return IF; }
"else"	            { return ELSE; }
"while"             { return WHILE; }
[-]?{digit}+        { return NUM; }
{letter}+           { return ID; }
"<="                { return LE; }
">="                { return GE; }
"=="                { return EQ; }
"!="                { return NE; }
">"	                { return GT; }
"<"	                { return LT; }
"="                 { return ASSIGN; }
"+"                 { return ADD; }
"-"                 { return SUBTRACT; }
"/"                 { return DIVIDE; }
"*"                 { return MULTIPLY; }
";"                 { return SEMI; }
","                 { return COMMA; }
"("                 { return LPAREN; }
")"                 { return RPAREN; }
"["                 { return LBRACKET; }
"]"                 { return RBRACKET; }
"{"                 { return LBRACE; }
"}"                 { return RBRACE; }
[\n]                { countn++; }
.	                { return *yytext; }

%%

int yywrap() {
    return 1;
}