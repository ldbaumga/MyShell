
/*
 *
 * CS-252 
 * shell.l: lexical analyzer for shell
 * You have to extend it.
 *
 */

%{
#include <pwd.h>
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

~((\/[^ \t\n]*)|([^ \t\n]*)) {
    std::string str = std::string(yytext);

    std::string user = str.substr(1, str.find("/") - 1);
    const char *homedir;
    if (user.empty()) {
        homedir = getpwuid(getuid())->pw_dir;
    } else {
        passwd *us = getpwnam(user.c_str());
        if (us == NULL) {
            perror("user does not exist");
            exit(1);
        }
        homedir = us->pw_dir;
    }

    str = str.replace(0, str.find("/"), homedir);
    yylval.cpp_string = new std::string(str);
    return WORD;
}

[^\t\n]*\$\{[^ \{\n]*\}[^\t\n]* {
    std::string str = std::string(yytext);

    std::string start("${");
    std::string end("}");

    int findStart = str.find(start);
    int findEnd = str.find(end);

    while (findStart != std::string::npos && findEnd != std::string::npos) {
        std::string inside = str.substr(str.find(start) + 2, str.find(end) - 1);

        fprintf(stderr, "%s\n", inside.c_str());
        std::string evn = std::string(getenv(inside.c_str()));

        str = str.replace(str.find(start), str.find(end)+1, evn);

        findStart = str.find(start);
        findEnd = str.find(end);
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
