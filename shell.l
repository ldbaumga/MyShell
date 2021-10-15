
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{
#include <sys/wait.h>
#include <unistd.h>
#include <cstring>
#include "y.tab.hh"
#include <string.h>
#include <algorithm>
static  void yyunput (int c,char *buf_ptr  );

void myunputc(int c) {
  unput(c);
}

%}

%option noyywrap

%%

\n {
  return NEWLINE;
}

[ \t] {
  /* Discard spaces and tabs */
}

"exit" {
    return EXIT;
}

"printenv" {
    return PRINTENV;
}

$\(([^\n]*)\)|\'[^\n*]\' {\
    std::string str = std::string(yytext);
    if (str.at(0) == '$') {
        str = str.substr(2, str.size() - 3);
    } else {
        str = str.substr(1, str.size() - 2);
    }
    int pin[2];
    int pout[2];

    pipe(pin);
    pipe(pout);

    int defaultin = dup(0);
    int defaultout = dup(1);


    dup2(pin[0], 0);
    dup2(pout[1], 1);
    close(pin[0]);
    close(pout[1]);


    int pid = fork();

    write(pin[1], str.c_str(), str.size());
    write(pin[1], "\n", 1);
    write(pin[1], "exit\n", 5);
    close(pin[1]);

    if(pid == -1) {
      perror("fork\n");
      exit(1);
    }
    //CHILD
    if (pid == 0) {
    char * arg[2];
    arg[1] = NULL;
    arg[0] =(char *) "shell";


    execvp("/proc/self/exe", arg);
    perror("execvp(subshell)");
    _exit(1);
    } else { //END CHILD

    waitpid(pid, NULL, 0);

    dup2(defaultin, 0);
    dup2(defaultout, 1);
    close(defaultin);
    close(defaultout);


    char c;
    str:string a;
    while(read(pout[0], &c, 1)) {
        if (c == '\n') {
            c =' ';
        }
        a.push_back(c);
        fprintf(stderr, "%c", c);
    }
    close(pout[0]);

    //myunputc(c);
}
}

\"([^\n]*)\" {
  std::string str = std::string(yytext);
  str = str.substr(1, str.size() - 2);
  //str.erase(std::remove(str.begin(), str.end(), '\\'), str.end());
  yylval.cpp_string = new std::string(str);
  return WORD;
}

">>&" {
    return GREATGREATAMP;
}

">>" {
    return GREATGREAT;
}

">&" {
    return GREATAMP;
}

"2>" {
    return TWOGREAT;
}


">" {
  return GREAT;
}

"|" {
    return PIPE;
}

"<" {
    return LESS;
}

"&" {
    return AMPERSAND;
}
[^ \t\n][^ \t\n]*  {
  /* Assume that file names have only alpha chars */
  std::string str = std::string(yytext);
  //str.erase(std::remove(str.begin(), str.end(), '\\'), str.end());
  yylval.cpp_string = new std::string(str);
  return WORD;
}
