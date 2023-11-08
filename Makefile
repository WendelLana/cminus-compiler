# Build path
BUILD_PATH = build

# Lexer
LEXER = flex
# Lexer flags
LEXER_FLAGS =
# Lexer files
LEXER_SRCS = lexer.l

# Parser
PARSER = yacc
# Parser flags
PARSER_FLAGS = -v -d
# Parser files
PARSER_SRCS = parser.y

# C Compiler
CC = gcc
# C Compiler flags
CFLAGS =
# C Source files
CSRCS = y.tab.c

# Executable name
TARGET = parser

# Build rule
$(TARGET): $(PARSER) $(LEXER)
	mkdir -p build
	$(CC) $(CFLAGS) $(CSRCS) -o $(BUILD_PATH)/$(TARGET)

$(PARSER): $(LEXER)
	$(PARSER) $(PARSER_FLAGS) $(PARSER_SRCS)

# Lexer rule
$(LEXER):
	$(LEXER) $(LEXER_FLAGS) $(LEXER_SRCS)

# Clean rule
clean:
	rm y.* lex.yy.c $(BUILD_PATH)/* 

# Phony targets
.PHONY: all clean

all: $(TARGET)
