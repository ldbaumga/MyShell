#include <cstdio>
#include <unistd.h>
#include "shell.hh"
#include <signal.h>

extern "C" void disp(int sig) {
    fprintf(stderr, "\nOuch!\n", sig);
}

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
  sa.sa_flags = SA_RESTART;
  if(sigaction(SIGINT, &sa, NULL)) {
    perror("sigaction");
    exit(2);
  }
  Shell::prompt();
  yyparse();
}

Command Shell::_currentCommand;
