/* A Bison parser, made by GNU Bison 3.0.4.  */

/* Bison interface for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015 Free Software Foundation, Inc.

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

#ifndef YY_YY_NUTSHPARSER_TAB_H_INCLUDED
# define YY_YY_NUTSHPARSER_TAB_H_INCLUDED
/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif
/* "%code requires" blocks.  */
#line 39 "nutshparser.y" /* yacc.c:1909  */

#include "nutshell.h"

#line 48 "nutshparser.tab.h" /* yacc.c:1909  */

/* Token type.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    BYE = 258,
    CD = 259,
    STRING = 260,
    ALIAS = 261,
    END = 262,
    UNALIAS = 263,
    SETENV = 264,
    PRINTENV = 265,
    UNSETENV = 266,
    PATH = 267,
    NON_BUILD_IN_COMMAND = 268
  };
#endif

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED

union YYSTYPE
{

  /* COMMAND  */
  int COMMAND;
  /* NON_BUILD_IN  */
  int NON_BUILD_IN;
  /* BUILD_IN  */
  int BUILD_IN;
  /* BYE  */
  std::string* BYE;
  /* CD  */
  std::string* CD;
  /* STRING  */
  std::string* STRING;
  /* ALIAS  */
  std::string* ALIAS;
  /* END  */
  std::string* END;
  /* UNALIAS  */
  std::string* UNALIAS;
  /* SETENV  */
  std::string* SETENV;
  /* PRINTENV  */
  std::string* PRINTENV;
  /* UNSETENV  */
  std::string* UNSETENV;
  /* PATH  */
  std::string* PATH;
  /* NON_BUILD_IN_COMMAND  */
  std::string* NON_BUILD_IN_COMMAND;
  /* COMBINE_INPUT  */
  std::string* COMBINE_INPUT;
  /* PATH_INPUT  */
  std::string* PATH_INPUT;
#line 107 "nutshparser.tab.h" /* yacc.c:1909  */
};

typedef union YYSTYPE YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif


extern YYSTYPE yylval;

int yyparse (void);

#endif /* !YY_YY_NUTSHPARSER_TAB_H_INCLUDED  */
