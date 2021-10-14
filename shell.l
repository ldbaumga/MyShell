
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{
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
        str = str.substr(2, str.size() - 2);
    } else {
        str = str.substr(1, str.size() - 2);
    }
    str += "\nexit\n";

    char ** args = new char*[2];
    args[0] =(char *) "/proc/self/exe";
    args[1] = NULL;

    int pin[2];
    int pout[2];

    pipe(pin);
    pipe(pout);

    write(pin[1], str, str.size());

    /*
    int pid = fork();

    if(pid == -1) {
      perror("fork\n");
      _exit(0);
    }
    //CHILD
    if (pid == 0) {
    } //END CHILD
    */
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
