#include <cstdio>
#include <unistd.h>
#include "shell.hh"
#include <signal.h>
#include <sys/wait.h>

extern "C" void disp(int sig) {
    fprintf(stderr, "\nsig:%d        Ouch!\n", sig);
    Shell::prompt();
}

extern "C" void zomb_disp(int sig) {
    waitpid(sig, WNOHANG, NULL);
    fprintf(stderr, "\n[%d] exited.\n", sig);
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
  //Ctrl-C signal handler
  struct sigaction sa;
  sa.sa_handler = disp;
  sigemptyset(&sa.sa_mask);
  sa.sa_flags = SA_RESTART;
  if(sigaction(SIGINT, &sa, NULL)) {
    perror("sigaction");
    exit(2);
  }

  //Zombie signal handler
  struct sigaction zomb;
  zomb.sa_handler = zomb_disp;
  sigemptyset(&zomb.sa_mask);
  zomb.sa_flags = SA_NOCLDWAIT;
  if(sigaction(SIGCHLD, &zomb, NULL)) {
    perror("sigaction");
    exit(2);
  }

  Shell::prompt();
  yyparse();
}

Command Shell::_currentCommand;
