# cminus-compiler
C- compiler for educational purpose 

To run:
yacc -v -d parser.y
flex lexer.l
gcc y.tab.c -o parser
./parser
