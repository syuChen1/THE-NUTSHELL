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
char checkMeta(char* str){
    for ( int i = strlen(str) - 1; i >= 0; --i ){
       if(str[i] == '|' || str[i] == '&' || str[i] == '<' || str[i] == '>' ){
          printf("found meta1 \n");
          if(i-1 > 0 && str[i-1] != '\\'){
            printf("found meta \n");
            return str[i];
          }
       }
    }
    return '1';
}

char* reverseCharArr(char *str){
   char* r = (char*)malloc((strlen(str) + 1) * sizeof(char));
   r[strlen(str)] = '\0';
   int i;
   for(i = 0; i < strlen(str); i++) {
      r[i] = str[strlen(str) - 1 - i];
  }
  return r;
}
%}
%array
%option noyywrap

CHAR               [.A-Za-z0-9!\\><|&/~_-][.A-Za-z0-9!\\><|&/~_-]*
STR_ANYCHAR        [)(*&%$#@!`;,\.a-zA-Z0-9'/*_><|=~ -][}{)(*&%$#@!`;,\.a-zA-Z0-9'/*_><|=~ -]*
ENV_ANYCHAR        [)(*%#@!`;,.a-zA-Z0-9'/*_=~ -][)(*%#@!`;,.a-zA-Z0-9'/*_=~ -]*
META               [><|\&]*

%x string_condition env_condition 
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

[ ]		           { tokenCount++;}
bye                 { return BYE; }
cd		              { return CD;}
alias		           { return ALIAS; }
unalias             { return UNALIAS; }
setenv              { return SETENV; }
printenv            { return PRINTENV; }
unsetenv            { return UNSETENV; }
[:]           	     { return yytext[0]; }
[~]                 { yylval.string = strdup(tilde); return STRING; }
"\n"		           { return END; }
[\"]                { BEGIN(string_condition); }
[\$][\{]            { BEGIN(env_condition); }
{META}              { yylval.string = strdup(yytext);
                        return STRING;
                    }

{CHAR}+             {/*char meta = checkMeta(yytext);
                     printf("yytext to be checked %s \n", yytext);
                     printf("checkmeta %c \n", meta);
                     if(meta != '1'){
                        char *ret = strchr(yytext, meta);
                        printf("printing %s \n", ret);
                        for ( int i = strlen(ret); i > 0; --i ){
                           unput(ret[i] );
                        }
                         int length = strlen(yytext) - strlen(ret);
                         for ( int i = length -1; i >= 0; --i ){
                            unput( yytext[i] );
                         }
                        return META;
                     }*/
                     printf("token count: %d \n", tokenCount);
                     if(tokenCount == 0 && ifAlias(yytext)) {
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