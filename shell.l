
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
    str += "\nexit\n";
    int pin[2];
    int pout[2];

    pipe(pin);
    pipe(pout);

    int defaultin = dup(0);
    int defaultout = dup(1);


    int pid = fork();

    if(pid == -1) {
      perror("fork\n");
      exit(1);
    }
    //CHILD
    if (pid == 0) {
    char * arg[2];
    arg[1] = NULL;
    arg[0] = (char *) "/proc/self/exe";

    fprintf(stderr, "I made it\n");

    dup2(pin[0], 0);
    dup2(pout[1], 1);

    execvp(arg[1], arg);
    perror("execvp(subshell)");
    _exit(1);
    } else { //END CHILD
    write(pin[1], str.c_str(), str.size());
    dup2(defaultin, 0);
    dup2(defaultout, 1);
fprintf(stderr, "I made it tt\n");

    dup2(defaultin, 0);
    dup2(defaultout, 1);
    close(defaultin);
    close(defaultout);

    int buffersize = 1024;
    char * buff = new char[buffersize];
    int r = read(pout[0], buff, buffersize);

    printf("buff: %s\n",buff);
    for (int i = r; i > 0; i--) {
    myunputc(buff[i]);
    }
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
