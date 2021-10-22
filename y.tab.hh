/* A Bison parser, made by GNU Bison 3.5.1.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2020 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* Undocumented macros, especially those whose name start with YY_,
   are private implementation details.  Do not rely on them.  */

#ifndef YY_YY_Y_TAB_HH_INCLUDED
# define YY_YY_Y_TAB_HH_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 1
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 14 "shell.y"

#include <string>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <regex.h>
#include <dirent.h>
#include <vector>
#if __cplusplus > 199711L
#define register      // Deprecated in C++11 so remove the keyword
#endif

#line 61 "y.tab.hh"

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    WORD = 258,
    NEWLINE = 259,
    NOTOKEN = 260,
    PIPE = 261,
    GREAT = 262,
    LESS = 263,
    TWOGREAT = 264,
    GREATAMP = 265,
    GREATGREAT = 266,
    GREATGREATAMP = 267,
    AMPERSAND = 268,
    EXIT = 269,
    PRINTENV = 270,
    CD = 271,
    SETENV = 272,
    UNSETENV = 273,
    SOURCE = 274
  };
#endif
/* Tokens.  */
#define WORD 258
#define NEWLINE 259
#define NOTOKEN 260
#define PIPE 261
#define GREAT 262
#define LESS 263
#define TWOGREAT 264
#define GREATAMP 265
#define GREATGREAT 266
#define GREATGREATAMP 267
#define AMPERSAND 268
#define EXIT 269
#define PRINTENV 270
#define CD 271
#define SETENV 272
#define UNSETENV 273
#define SOURCE 274

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
union YYSTYPE
{
#line 28 "shell.y"

  char        *string_val;
  // Example of using a c++ type in yacc
  std::string *cpp_string;

#line 116 "y.tab.hh"

};
typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_Y_TAB_HH_INCLUDED  */
