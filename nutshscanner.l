%{
#include "nutshparser.tab.h"
#include <stdio.h>
#include <string.h>
#include "nutshell.h"

char* subAliases(char* name){
   if(aliasTable.count(name))
      return toCharArr(aliasTable[name]);
   return name;
}
bool ifAlias(char* name){
    return aliasTable.count(name);
}
char* subEnv(char* name){
   if(varTable.count(name))
      return toCharArr(varTable[name]);
   return name;
}
bool isEnv(char* name){
   return varTable.count(name);
}
%}
%array
%option noyywrap

CHAR               [.A-Za-z0-9!/~_-][.A-Za-z0-9!/~_-]*
STR_ANYCHAR        [)(*&%$#@!`;,\.a-zA-Z0-9'/*_><|=~ -][}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_><|=~ -]*
ENV_ANYCHAR        [)(*%$#@!`;,.a-zA-Z0-9'/*_=~ -][)(*%$#@!`;,.a-zA-Z0-9'/*_=~ -]*
META               [><|\&]*

%x string_condition env_condition tilde_condition
%%

<string_condition>{STR_ANYCHAR}+     { printf("yytext str_cond: %s\n", yytext);
                                       yylval.string = strdup(yytext);
                                       return STRING;
                                    }
<env_condition>{ENV_ANYCHAR}+        { if(isEnv(yytext)){
                                       printf("yytext before env sub: %s\n", yytext);
                                       char *yycopy = strdup(subEnv(yytext) );
                                       for ( int i = strlen(subEnv(yytext)) - 1; i >= 0; --i )
                                          unput( yycopy[i] );
                                       free( yycopy );
                                    } else {
                                       printf("yytext env_cond: %s\n", yytext);
                                       yylval.string = strdup(yytext);
                                       return STRING;
                                    };
                                 }
<string_condition>[\"]           { BEGIN(INITIAL); }
<env_condition>[\}]              { BEGIN(INITIAL); }

[ ]		           { }
bye                 { return BYE; }
cd		              { return CD;}
alias		           { return ALIAS; }
unalias             { return UNALIAS; }
setenv              { return SETENV; }
printenv            { return PRINTENV; }
unsetenv            { return UNSETENV; }
ls                  { return LS; }
echo                { return ECHOO; }
[:]           	     { return yytext[0]; }
"\n"		           { return END; }
[\"]                { BEGIN(string_condition); }
[\$][\{]            { BEGIN(env_condition); }
{META}              { printf("Invalid Metacharacter input.\n"); return META;}
[\\]{META}          { yylval.string = strdup(yytext);
                        return STRING;
                    }

{CHAR}+             {  if(ifAlias(yytext)) {
                        printf("yytext before alias_sub: %s\n", yytext);
                        // source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                           char *yycopy = strdup( subAliases(yytext) );
                           for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                               unput( yycopy[i] );
                           free( yycopy );
                      } else {
                        printf("yytext char_cond: %s\n", yytext);
                        yylval.string = strdup(yytext);
                        return STRING;
                      };
                     }
%%