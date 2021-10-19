
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

"setenv" {
    return SETENV;
}

"unsetenv" {
    return UNSETENV;
}

"cd" {
    return CD;
}

"source "([^ \t\n][^ \t\n]*) {
     std::string str = std::string(yytext);
     str = str.substr(7, str.size());
     FILE * sourceFile = fopen(str.c_str(), "r+");

    if (!sourceFile) {
        perror("fopen");
        BEGIN(INITIAL);
    } else {
        fputc('\n', sourceFile);
        yypush_buffer_state(yy_create_buffer(sourceFile, YY_BUF_SIZE));
        BEGIN(INITIAL);
        yyparse();
        yypop_buffer_state();
        fclose(sourceFile);
    }
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

$\{[^ \}\n]*\}([^\n]|$\{[^\{\n]\})* {
    std::string str = std::string(yytext);
    //str = str.substr(2, str.size() - 3);
    //int size = str.size();
    //use setenv in command.cc to set all the symbols
    /*
        if(str.at(0) == '$' && size == 1) {
            str = std::to_string(getpid());
        } else if (str.at(0) == '?' && size == 1) {
            
        } else if (str.at(0) == '!' && size == 1) {

        } else if (str.at(0) == '_' && size == 1) {

        } else if (strcmp(str.c_str(), "SHELL") == 0) {

        } else {
            str = getenv(str.c_str());
       }
    */
    std::string dollarsign ("${$}");
    std::string dollsign = std::to_string(getpid());


    int found = str.find(dollarsign);
    while(found != std::string::npos) {
        str.replace(str.find(dollarsign), dollarsign.length(), dollsign);
        found = str.find(dollarsign);
    }

    std::string question ("${?}");
    std::string quest = std::string(getenv("?"));

    found = str.find(question);
    while(found != std::string::npos) {
        str.replace(str.find(question), question.length(), quest);
        found = str.find(question);
    }


    std::string exclamation ("${!}");
    std::string excl = std::string(getenv("!"));

    found = str.find(exclamation);
    while(found != std::string::npos) {
        str.replace(str.find(exclamation), exclamation.length(), excl);
        found = str.find(exclamation);
    }

    std::string underscore ("${_}");
    std::string under = std::string(getenv("_"));

    found = str.find(underscore);
    while(found != std::string::npos) {
        str.replace(str.find(underscore), underscore.length(), under);
        found = str.find(underscore);
    }

    std::string shell ("${SHELL}");
    std::string sh = std::string(getenv("SHELL"));

    found = str.find(shell);
    while(found != std::string::npos) {
        str.replace(str.find(shell), shell.length(), sh);
        found = str.find(shell);
    }

    std::string start ("${");
    std::string end ("}");

    found = str.find(start);
    int endfound = str.find(end);
    while (found != std::string::npos && endfound != std::string::npos) {
        std::string replace = str.substr(found, endfound);
        str.replace(found, replace.length()+3, replace);
        found = str.find(start);
        endfound = str.find(end);
    }

    yylval.cpp_string = new std::string(str);
    return WORD;
}


$\(([^\n]*)\)|\'([^\n]*)\' {
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
    std::string a;
    while(read(pout[0], &c, 1)) {
        if (c == '\n') {
            c =' ';
        }
        a.push_back(c);
    }
    close(pout[0]);
    for ( int i = a.size() - 1; i >= 0; i--) {
        myunputc(a.at(i));
    }
}
}

\"[^\n\"]*\" {
  std::string str = std::string(yytext);
  str = str.substr(1, str.size() - 2);
  yylval.cpp_string = new std::string(str);
  return WORD;
}

[^ \|>\t\n][^ \|>\t\n]*  {
  /* Assume that file names have only alpha chars */
  std::string str = std::string(yytext);
  yylval.cpp_string = new std::string(str);
  return WORD;
}
