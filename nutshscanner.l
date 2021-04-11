%{
#include "nutshparser.tab.h"
#include <stdio.h>
#include <string.h>
#include <ctype.h>
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
int quoteCount;

bool checkWC(char *str){
   for ( int i = strlen(str) - 1; i >= 0; --i ){
       if(str[i] == '*' || str[i] == '?'){
         return true;
       }
   }
   return false;
}

char* WCcondition(char *pattern){
   // source: https://www.geeksforgeeks.org/wildcard-pattern-matching/
   char* result = "";
   for(char* str : cwdFiles){
      int n = strlen(str);
      int m = strlen(pattern);
      bool lookup[n + 1][m + 1];
      memset(lookup, false, sizeof(lookup));
      lookup[0][0] = true;
      for (int j = 1; j <= m; j++)
        if (pattern[j - 1] == '*')
            lookup[0][j] = lookup[0][j - 1];
      for (int i = 1; i <= n; i++) {
         for (int j = 1; j <= m; j++) {
            if (pattern[j - 1] == '*')
                lookup[i][j] = lookup[i][j - 1] || lookup[i - 1][j];
            else if (pattern[j - 1] == '?' || str[i - 1] == pattern[j - 1])
                lookup[i][j] = lookup[i - 1][j - 1];
            else
                lookup[i][j] = false;
         }
      }
      if(lookup[n][m] == true)
         result = combineCharArr(combineCharArr(result, str), toCharArr(" "));
   }
   return result == ""? pattern : result;
}
char* tildeExpansion(char* str){
   removeChar(str, '~');
   return combineCharArr(toCharArr(varTable["HOME"]), str);
}
char* tildeNameExpansion(char* str){
   removeChar(str, '~');
   char *pointer = &str[0];
   char name[100];
   int i = 0;
   while(*pointer != ' ' && *pointer != '/' && *pointer != '\0'){
      name[i] = *pointer;
      pointer++;
      i++;
   }
   name[i] = '\0';
   //printf("name after search: %s \n", name);
   //printf("path after search: %s \n", pointer);
   char* dir = getUserHomeDir(name);
   return combineCharArr(dir, pointer);
}

/*
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
*/
%}
%array
%option noyywrap

CHAR               [.A-Za-z0-9!\\><|?*&/_-][.A-Za-z0-9!\\><|?*&/_-]*
STR_ANYCHAR        [)(*&%$#@!`;,\\.a-zA-Z0-9'*/_><|=~ -][}{)(*&%$#@!`;,\\.a-zA-Z0-9'*/_><|=~ -]*
ENV_ANYCHAR        [)(*%#@!`;,.a-zA-Z0-9'/*_=~ -][)(*%#@!`;,.a-zA-Z0-9'/*_=~ -]*
META               [><|\\&"]*

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
<string_condition>[\"]           { if(++quoteCount %2 == 0) {printf("if: count %d \n", quoteCount); BEGIN(INITIAL);}
                                    else printf("else: count %d \n", quoteCount);
                                     }
<env_condition>[\}]              { BEGIN(INITIAL); }

[ ]		           { tokenCount++;}
bye                 { return BYE; }
cd		              { return CD;}
alias		           { return ALIAS; }
unalias             { return UNALIAS; }
setenv              { return SETENV; }
printenv            { return PRINTENV; }
unsetenv            { return UNSETENV; }
[.][:]                { yylval.string = strdup(yytext); return PATH;}
[:]           	     { return yytext[0]; }
[~]{CHAR}*          { if(strlen(yytext) > 1 && isalpha(yytext[1]) != 0){
                        yylval.string = tildeNameExpansion(yytext);
                      }
                      else{
                        yylval.string = tildeExpansion(yytext); 
                      };
                      return STRING; 
                    }
[.]                 { yylval.string = strdup(dot); return STRING; }
[.][.]              { yylval.string = strdup(dotdot); return STRING; }
"\n"		           { return END; }
[\"]                { quoteCount = 1; BEGIN(string_condition); }
[\$][\{]            { BEGIN(env_condition); }


{CHAR}*[\\]{META}{CHAR}*   {
                              removeChar(yytext, '\\');
                              yylval.string = strdup(yytext);
                              return STRING;
                           }
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
                     if(tokenCount == 0 && ifAlias(yytext)) {
                        printf("yytext before alias_sub: %s\n", yytext);
                        // source: https://www.cs.princeton.edu/~appel/modern/c/software/flex/flex.html
                           char *yycopy = strdup( subAliases(yytext) );
                           for ( int i = strlen(subAliases(yytext)) - 1; i >= 0; --i )
                               unput( yycopy[i] );
                           free( yycopy );
                      } else {
                        printf("yytext char_cond: %s\n", yytext);
                        if(checkWC(yytext)){
                           yylval.string = strdup(WCcondition(yytext));
                        }
                        else{
                           yylval.string = strdup((yytext));
                        }
                        //printf("after WC natching: %s \n", yylval.string);
                        return STRING;
                      };
                     }
%%