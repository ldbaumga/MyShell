/*
 * CS-252
 * shell.y: parser for shell
 *
 * This parser compiles the following grammar:
 *
 *	cmd [arg]* [> filename]
 *
 * you must extend it to understand the complete shell grammar
 *
 */

%code requires 
{
#include <string>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <regex.h>
#include <dirent.h>
#include <vector>
#include <algorithm>
#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif
}

%union
{
  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;
}

%token <cpp_string> WORD
%token NEWLINE NOTOKEN PIPE GREAT LESS TWOGREAT GREATAMP GREATGREAT
%token GREATGREATAMP AMPERSAND
%token EXIT PRINTENV CD SETENV UNSETENV SOURCE

%{
//#define yylex yylex
#include <cstdio>
#include "shell.hh"

void yyerror(const char * s);
void expandWildcardsIfNecessary(std::string * arg);
void p ();
int yylex();

%}

%%

goal:
  command_list
  ;

command_list:
  command_list command_line
  | command_line
  ;

command_line:
  pipe_list io_modifier_list background_opt NEWLINE {
    if (isatty(0)) {
        printf("   Yacc: Execute command\n");
    }
    Shell::_currentCommand.execute();
  }
  | cd
  | setenv
  | unsetenv
  | NEWLINE /*accepts empty cmd line*/ {
    Shell::_currentCommand.execute();
  }
  | error NEWLINE{yyerrok;
    Shell::_currentCommand.clear();
    Shell::prompt();} /*error recovery*/
  ;

cd:
  CD WORD {
    if (strcmp($2->c_str(), "${HOME}") == 0) {
        chdir(getenv("HOME"));
    } else if (chdir(realpath($2->c_str(), NULL)) != 0) {
        fprintf(stderr, "cd: can't cd to %s\n", $2->c_str());
    }
  }
  | CD {
    chdir(getenv("HOME"));
  }
  ;

setenv:
  SETENV WORD WORD {
    setenv($2->c_str(), $3->c_str(), 1);
  }
  ;

unsetenv:
  UNSETENV WORD {
    unsetenv($2->c_str());
  }
  ;

pipe_list:
  pipe_list PIPE cmd_and_args
  | cmd_and_args
  ;

background_opt:
  AMPERSAND {
    if (isatty(0)) {
        printf("   Yacc: backgorund true \n");
    }
    Shell::_currentCommand._background = true;
  }
  | /* can be empty */
  ;

io_modifier_list:
  io_modifier_list io_modifier
  | /* empty */
  ;

io_modifier:
  GREAT WORD {
    if (isatty(0)) {
      printf("   Yacc: insert output \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._outFile != NULL) {
        Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._outFile = $2;
  }
  | LESS WORD {
    if (isatty(0)) {
      printf("   Yacc: insert input \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._inFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._inFile = $2;
  }
  | TWOGREAT WORD {
    if (isatty(0)) {
      printf("   Yacc: insert error \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._errFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._errFile = $2;
  }
  | GREATAMP WORD {
    if (isatty(0)) {
      printf("   Yacc: insert output and error \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._outFile != NULL
        || Shell::_currentCommand._errFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;
  }
  | GREATGREAT WORD {
    if (isatty(0)) {
      printf("   Yacc: insert output and append \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._outFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

    Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._append = true;
  }
  | GREATGREATAMP WORD {
    if (isatty(0)) {
      printf("   Yacc: insert output and error and append \"%s\"\n", $2->c_str());
    }

    if (Shell::_currentCommand._outFile != NULL
        || Shell::_currentCommand._errFile != NULL) {
         Shell::_currentCommand._ambig = true;
    }

     Shell::_currentCommand._outFile = $2;
    Shell::_currentCommand._errFile = $2;
    Shell::_currentCommand._append = true;
  }
  ;

cmd_and_args:
  command_word arg_list {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  | command_word {
    Shell::_currentCommand.
    insertSimpleCommand( Command::_currentSimpleCommand );
  }
  ;

arg_list:
  arg_list argument
  | argument
  ;

exit:
  EXIT {
  if (isatty(0)) {
    fprintf(stderr, "\n Goodbye!!\n\n");
  }
  exit(0);
  }
  ;

printenv:
  PRINTENV {
  Command::_currentSimpleCommand = new SimpleCommand();
  std::string * str = new std::string("/usr/bin/printenv");
  Command::_currentSimpleCommand->insertArgument(str);
  }
  ;

command_word:
  exit
  | printenv
  | WORD {
    if (isatty(0)) {
      printf("   Yacc: insert command \"%s\"\n", $1->c_str());
    }
    Command::_currentSimpleCommand = new SimpleCommand();
    Command::_currentSimpleCommand->insertArgument( $1 );
  }
  ;

argument:
   WORD {
    if (isatty(0)) {
      printf("   Yacc: insert argument \"%s\"\n", $1->c_str());
    }
   //Command::_currentSimpleCommand->insertArgument( $1 );
   //p();
   expandWildcardsIfNecessary($1);
 }
  ;

%%

void
yyerror(const char * s)
{
  fprintf(stderr,"%s\n", s);
}

void expandWildcardsIfNecessary(std::string * arg) {
    if (arg->find("?") == std::string::npos
        && arg->find("*") == std::string::npos) {
        Command::_currentSimpleCommand->insertArgument(arg);
        return;
    }

    DIR * dir;
    std::string path;

    if (arg->find("/") != std::string::npos) {
        int found = arg->find("/");
        while (arg->find("/", found + 1) != std::string::npos) {
            found = arg->find("/", found + 1);
        }
        path = arg->substr(0, found);
        char * fullpath = realpath(path.c_str(), NULL);
        //printf("%s\n", path.c_str());
        //printf("%s\n", fullpath);
        dir = opendir(path.c_str());
        arg->erase(0, found +1);
    } else {
        dir = opendir(strdup("."));
    }
    if (dir == NULL) {
        perror("opendir");
        return;
    }


    //std::string str = *arg;
    //const char * reg = str.c_str();
    const char dot = '.';
    const char quest = '?';
    const char star = '*';

    arg->insert(0, "^");
    for (int r = 0; r < arg->length(); r++) {
        if (arg->at(r) == dot) {
            arg->insert(r, "\\");
            r ++;
            continue;
        }

        if (arg->at(r) == quest) {
            arg->replace(r, 1, ".");
            continue;
        }

        if (arg->at(r) == star) {
            arg->replace(r, 2, ".*");
            r ++;
            continue;
        }
    }
    arg->insert(arg->length(), "$");

    std::vector<std::string> strs;

    regex_t re;
    int expbuf = regcomp(&re, arg->c_str(), REG_EXTENDED|REG_NOSUB);
    if (expbuf != 0) {
        fprintf(stderr, "Bad regex, BAD!\n");
        return;
    }

    struct dirent * ent;
    regmatch_t match;
    while ((ent = readdir(dir)) != NULL) {
        int result = regexec(&re, ent->d_name, 1, &match, 0);
        if (result == 0) {
            //std::string * str = new std::string(strdup(ent->d_name));
            //Command::_currentSimpleCommand->insertArgument(str);
            if (path != NULL) {
                strs.push_back(path + "/" + strdup(ent->d_name));
            } else {
                strs.push_back(strdup(ent->d_name));
        }
    }
    closedir(dir);
    regfree(&re);

    std::sort (strs.begin(), strs.end());
    for (int i = 2; i < strs.size(); i++) {
        std::string * str = new std::string(strs[i]);
        Command::_currentSimpleCommand->insertArgument(str);
    }
}

void p () {
    fprintf(stderr, "look at me");
}

#if 0
main()
{
  yyparse();
}
#endif
