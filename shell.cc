#include <cstdio>
#include <unistd.h>
#include "shell.hh"

int yyparse(void);

void Shell::prompt() {
  printf("myshell>");
  fflush(stdout);
}

int main() {
  if(isatty(3) == 1) {
    Shell::prompt();
  }
  yyparse();
}

Command Shell::_currentCommand;
