%{
    #include<stdio.h>
    #include<string.h>
    #include<stdlib.h>
    #include<ctype.h>
    #include"lex.yy.c"
    
    void yyerror(const char *s);
    int yylex();
    int yywrap();
    void add(char);
    void insert_type();
    int search(char *);
    void insert_type();

    struct dataType {
        char * id_name;
        char * data_type;
        char * type;
        int line_no;
    } symbol_table[40];

    int count=0;
    int q;
    char type[10];
    extern int countn;
%}

%token void int if else while return NUM ID LE GE EQ NE GT LT ASSIGN ADD MULTIPLY DIVIDE SUBTRACT SEMI COMMA LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE

%%

declaration: int ID ASSIGN NUM
| int ID
;

program: main LPAREN RPAREN LBRACE body ret RBRACE
;

main: datatype ID
;

datatype: int
| void
;

body: while LPAREN statement SEMI condition SEMI statement RPAREN LBRACE body RBRACE
| if LPAREN condition RPAREN LBRACE body RBRACE else_statement
| statement SEMI 
| body body
;

else_statement: else LBRACE body RBRACE
|
;

condition: value relop value
;

statement: datatype ID init 
| ID ASSIGN expression 
| ID relop expression
;

value: NUM
| ID
;

relop: LT
| GT
| LE
| GE
| EQ
| NE
;

init: ASSIGN value 
|
;

expression: expression arithmetic expression
| value
;

arithmetic: ADD
| SUBTRACT
| MULTIPLY
| DIVIDE
;

ret: return value SEMI
|
;

%%

int main() {
  yyparse();
  printf("\n\n");
	printf("\t\t\t\t\t\t\t\t PHASE 1: LEXICAL ANALYSIS \n\n");
	printf("\nSYMBOL   DATATYPE   TYPE   LINE NUMBER \n");
	printf("_______________________________________\n\n");
	int i=0;
	for(i=0; i<count; i++) {
		printf("%s\t%s\t%s\t%d\t\n", symbol_table[i].id_name, symbol_table[i].data_type, symbol_table[i].type, symbol_table[i].line_no);
	}
	for(i=0;i<count;i++) {
		free(symbol_table[i].id_name);
		free(symbol_table[i].type);
	}
	printf("\n\n");
}

int search(char *type) {
	int i;
	for(i=count-1; i>=0; i--) {
		if(strcmp(symbol_table[i].id_name, type)==0) {
			return -1;
			break;
		}
	}
	return 0;
}

void add(char c) {
  q=search(yytext);
  if(!q) {
    if(c == 'K') {
			symbol_table[count].id_name=strdup(yytext);
			symbol_table[count].data_type=strdup("N/A");
			symbol_table[count].line_no=countn;
			symbol_table[count].type=strdup("Keyword\t");
			count++;
		}
		else if(c == 'V') {
			symbol_table[count].id_name=strdup(yytext);
			symbol_table[count].data_type=strdup(type);
			symbol_table[count].line_no=countn;
			symbol_table[count].type=strdup("Variable");
			count++;
		}
		else if(c == 'C') {
			symbol_table[count].id_name=strdup(yytext);
			symbol_table[count].data_type=strdup("CONST");
			symbol_table[count].line_no=countn;
			symbol_table[count].type=strdup("Constant");
			count++;
		}
		else if(c == 'F') {
			symbol_table[count].id_name=strdup(yytext);
			symbol_table[count].data_type=strdup(type);
			symbol_table[count].line_no=countn;
			symbol_table[count].type=strdup("Function");
			count++;
		}
	}
}

void insert_type() {
	strcpy(type, yytext);
}

void yyerror(const char* msg) {
  fprintf(stderr, "%s\n", msg);
}