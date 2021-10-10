#include <cstdio>
#include <unistd.h>
#include "shell.hh"

int yyparse(void);

void Shell::prompt() {
  if(isatty(0)) {
    //This prevents the prompt from being printed to a file
    printf("myshell>");
    fflush(stdout);
  }
}

int main() {
  struct sigaction sa;
  sa.sa_handler = disp;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = 0;
  if(sigaction(SIGINT, &sa, NULL)) {
    perror("sigaction");
    exit(2);
  }
  Shell::prompt();
  yyparse();
}

Command Shell::_currentCommand;
