%{    
     #include "y.tab.h"    
     int countn=0;       /* for keeping track of the line number */
%}

%option yylineno
letter          [a-zA-Z]
digit          [0-9]

%%

"int"               { return int; }
"void"              { return void; }
"return"            { return return; }
"if"	            { return if; }
"else"	            { return else; }
"while"             { return while; }
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