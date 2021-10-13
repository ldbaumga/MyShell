
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{

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

\$\(([^\n]*)\) {
    fprintf(stderr, "subshell");

}

\"([^\n]*)\" {
  std::string str = std::string(yytext);
  str = str.substr(1, str.size() - 2);
  //str.erase(std::remove(str.begin(), str.end(), '\\'), str.end());
  yylval.cpp_string = new std::string(str);
  return WORD;
}

\'([^\n]*)\' {
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
