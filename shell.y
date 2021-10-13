/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{
#include <string>
#include <unistd.h>
#include <string.h>
#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <cpp_string> WORD
%token NEWLINE NOTOKEN PIPE GREAT LESS TWOGREAT GREATAMP GREATGREAT
%token GREATGREATAMP AMPERSAND
%token EXIT PRINTENV SETENV UNSETENV SOURCE CD

%{
//#define yylex yylex
#include <cstdio>
#include "shell.hh"

void yyerror(const char * s);
int yylex();

%}

%%

goal:
  command_list
  ;

command_list:
  command_list command_line
  | command_line
  ;

command_line:
  pipe_list io_modifier_list background_opt NEWLINE {
    if (isatty(0)) {
        printf("   Yacc: Execute command\n");
    }
    Shell::_currentCommand.execute();
  }
  | NEWLINE /*accepts empty cmd line*/ {
    Shell::_currentCommand.execute();
  }
  | error NEWLINE{yyerrok;
    Shell::_currentCommand.clear();
    Shell::prompt();} /*error recovery*/
  ;

pipe_list:
  pipe_list PIPE cmd_and_args
  | cmd_and_args
  ;

background_opt:
  AMPERSAND {
    if (isatty(0)) {
        printf("   Yacc: backgorund true \n");
    }
    Shell::_currentCommand._background = true;
  }
  | /* can be empty */
  ;

io_modifier_list:
  io_modifier_list io_modifier
  | /* empty */
  ;

io_modifier:
  GREAT WORD {
    if (isatty(0)) {
      printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._outFile != NULL) {
        Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._outFile = $2;
  }
  | LESS WORD {
    if (isatty(0)) {
      printf("   Yacc: insert input \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._inFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._inFile = $2;
  }
  | TWOGREAT WORD {
    if (isatty(0)) {
      printf("   Yacc: insert error \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._errFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._errFile = $2;
  }
  | GREATAMP WORD {
    if (isatty(0)) {
      printf("   Yacc: insert output and error \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._outFile != NULL
        || Shell::_currentCommand._errFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;
  }
  | GREATGREAT WORD {
    if (isatty(0)) {
      printf("   Yacc: insert output and append \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._outFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._append = true;
  }
  | GREATGREATAMP WORD {
    if (isatty(0)) {
      printf("   Yacc: insert output and error and append \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._outFile != NULL
        || Shell::_currentCommand._errFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

     Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;
    Shell::_currentCommand._append = true;
  }
  ;

cmd_and_args:
  command_word arg_list {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  | command_word {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

arg_list:
  arg_list argument
  | argument
  ;

exit:
  EXIT {
  fprintf(stderr, "\n Goodbye!!\n\n");
  exit(0);
}
  ;


command_word:
  EXIT
  | WORD {
    if (isatty(0)) {
      printf("   Yacc: insert command \"%s\"\n", $1->c_str());
    }
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

argument:
   WORD {
    if (isatty(0)) {
      printf("   Yacc: insert argument \"%s\"\n", $1->c_str());
    }
   Command::_currentSimpleCommand->insertArgument( $1 );\
  }
  ;

%%

void
yyerror(const char * s)
{
  fprintf(stderr,"%s\n", s);
}

#if 0
main()
{
  yyparse();
}
#endif
