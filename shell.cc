#include <cstdio>
#include <unistd.h>
#include "shell.hh"

int yyparse(void);

void Shell::prompt() {
  printf("myshell>");
  fflush(stdout);
}

int main() {


  //Part 1B.4 Prevents the shell prompt from being printed in a file
  if(isatty(0)) {
    Shell::prompt();
  }
  yyparse();
}

Command Shell::_currentCommand;
