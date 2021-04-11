%{
// This is ONLY a demo micro-shell whose purpose is to illustrate the need for and how to handle nested alias substitutions and Flex start conditions.
// This is to help students learn these specific capabilities, the code is by far not a complete nutshell by any means.
// Only "alias name word", "cd word", and "bye" run. 
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include "nutshell.h"
#include <pwd.h>
#include <sys/types.h>
#include <iostream>

int yylex();
int yyerror(char *s);

int runCD(char* arg);

int runSetAlias(char *name, char *word);
bool aliasLoopCheck(char* token1, char *token2);
int printAlias();
int unsetAlias(char *name);
void removeSubstrs(std::string &str, const std::string &substr, int dot);

int updateEnv(char *variable, char *word);
bool envLoopCheck(char* token1, char *token2);
int printEnv();
int unsetEnv(char *variable);
char *pathInput(char *first, char *second);

char* getUserHomeDir(char *user);
%}

%union {char *string;}

%start cmd_line
%token <string> BYE CD STRING ALIAS END UNALIAS SETENV PRINTENV UNSETENV  META PATH
%type <string> COMBINE_INPUT PATH_INPUT

%%
cmd_line    :
	  BYE END 		              {exit(1); return 1; }
	| CD STRING END        			{runCD($2); return 1; }
  | CD END                    {runCD(toCharArr("~")); return 1;}
	| ALIAS STRING STRING END		{if(!aliasLoopCheck($2, $3)){ 
                                runSetAlias($2, $3);}
                                return 1;}
  | ALIAS END                 {printAlias(); return 1;}
  | UNALIAS STRING END        {unsetAlias($2); return 1;}
  | SETENV STRING PATH_INPUT END  {if(!envLoopCheck($2, $3)){updateEnv($2,$3);}
                                       return 1;}
  | PRINTENV END              {printEnv(); return 1;}
  | UNSETENV STRING END       {unsetEnv($2); return 1;}
  | STRING COMBINE_INPUT END  {system(combineCharArr($1, $2)); return 1;}
  | META

COMBINE_INPUT   :
                            {$$ = toCharArr("");}
  | STRING COMBINE_INPUT    {$$ = combineCharArr(toCharArr(" "), combineCharArr($1,$2));}

PATH_INPUT  :
    PATH STRING ':' PATH_INPUT   {$$ = combineCharArr($1, pathInput($2,$4));}
  | STRING ':' PATH_INPUT   {$$ = pathInput($1,$3);}
  | STRING                  {$$ = $1;}

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

// CD
int runCD(char* arg) {
  //if the first argument is ~
  if (arg[0] == '~'){
    std::string temp = tilde;
    std::string a = arg;
    temp += a.substr(1);
    removeSubstrs(temp, "/..", 2);
    removeSubstrs(temp, "/.", 1);
    printf("path: %s \n", toCharArr(temp));
    char *c = strdup(toCharArr(temp));
		if(chdir(toCharArr(c)) == 0) {
			dot = toCharArr(temp);
      dotdot = toCharArr(getPrevPath(temp));
      varTable["PWD"] = temp;
		}
		else {
			//strcpy(varTable.word[0], varTable.word[0]); // fix
			printf("Directory not found\n");
			return 1;
		}
  }
  // arg is relative path
	else if (arg[0] != '/') {
    std::string temp = varTable["PWD"];
    std::string a = arg;
		temp += "/";
    temp += a;
    removeSubstrs(temp, "/..", 2);
    removeSubstrs(temp, "/.", 1);
    char *c = strdup(toCharArr(temp));
    if(c[strlen(c)-2] == ' '){
      c[strlen(c)-2] = '\0';
    }
    if(c[strlen(c)-1] == ' '){
      c[strlen(c)-1] = '\0';
    }
    printf("path relative: %s\n", toCharArr(c));
		if(chdir(c) == 0) {
			dot = toCharArr(c);
      dotdot = toCharArr(getPrevPath(c));
      varTable["PWD"] = c;
		}
		else {
			//strcpy(varTable.word[0], varTable.word[0]); // fix
			printf("Directory not found\n");
			return 1;
		}
	}

	else { // arg is absolute path
		if(chdir(arg) == 0){
      std::string temp = arg;
      removeSubstrs(temp, "/..", 2);
      removeSubstrs(temp, "/.", 1);
			dot = toCharArr(temp);
      dotdot = toCharArr(temp);
			varTable["PWD"] = temp;
			dotdot = toCharArr(getPrevPath(varTable["PWD"]));
		}
		else {
			printf("Directory not found\n");
      return 1;
		}
	}
	return 1;
}

// Alias
int runSetAlias(char *name, char *word) {
  if(strcmp(name, word) == 0){
		printf("Error, expansion of \"%s\" would create a loop.\n", name);
		return 1;
	}
  else if((aliasTable.count(name)) && (strcmp(toCharArr(aliasTable[name]), word) == 0)){
		printf("Error, expansion of \"%s\" would create a loop.\n", name);
		return 1;
	}
	aliasTable[name] = word;
	return 1;
}

//check for infinite loop in alias table
bool aliasLoopCheck(char* token1, char *token2)
{
  bool flag = false;
  //std::cout << aliasTable.size();
  if(aliasTable.size() == 0)
    return flag;
  
  if(aliasTable.size() == 1)
  {
    if(aliasTable.count(token2))
    {
      std::cout << "inifinite alias loop detected!\n";
      return true;
    }
      
    else 
      return false;
  }

  std::string value;

  value = aliasTable[toCharArr(token2)];
   
  
  while(1)
  {
    if(strcmp(toCharArr(token1), toCharArr(value)) == 0)
    {
      flag = true;
      std::cout << "inifinite alias loop detected!\n";
      //unsetAlias(toCharArr(value));
      break;
    }
    else if(!aliasTable.count(value))
    {
      unsetAlias(toCharArr(token2));
      break;
    }
    else
    {
      value = aliasTable[value];
    }
  }
  return flag;
}

int printAlias(){
  if(aliasTable.size() == 0){
    std::cout << "No alias avaliable" << std::endl;
    return 1;
  }
  std::cout << "Alias Table: " << std::endl;
  for(auto it = aliasTable.begin(); it != aliasTable.end(); it++){
    std::cout << it->first << " -> " << it->second << std::endl;
  }
  return 1;
}

int unsetAlias(char *name){
  if(aliasTable.count(name)){
    aliasTable.erase(name);
    std::cout << "earsed " << name << std::endl;
    return 1;
  }
  else 
    std::cout << name << " not exist." << std::endl;
  return 1;
}

// Env Variable
int updateEnv(char *variable, char *word){
  varTable[variable] = word;
  std::cout << "set " << variable << " to " << word << std::endl;
  return 1;
}

//check for infinite loop in environment variable table
bool envLoopCheck(char* token1, char *token2)
{
  bool flag = false;
  //std::cout << aliasTable.size();
  if(varTable.size() == 0)
    return flag;
  
  if(varTable.size() == 1)
  {
    if(varTable.count(token2))
    {
      std::cout << "inifinite alias loop detected!\n";
      return true;
    }
      
    else 
      return false;
  }

  std::string value;
  value = varTable[toCharArr(token2)];
  
  while(1)
  {
    if(strcmp(toCharArr(token1), toCharArr(value)) == 0)
    {
      flag = true;
      std::cout << "inifinite env variable loop detected!\n";
      //unsetAlias(toCharArr(value));
      break;
    }
    else if(!varTable.count(value))
    {
      unsetEnv(toCharArr(token2));
      break;
    }
    else
    {
      value = varTable[value];
    }
  }
  return flag;
}

int printEnv(){
  if(varTable.size() == 0){
    std::cout << "No Environment Variable avaliable" << std::endl;
    return 1;
  }
  std::cout << "Environment Variable Table: " << std::endl;
  for(auto it = varTable.begin(); it != varTable.end(); it++){
    std::cout << it->first << " -> " << it->second << std::endl;
  }
  return 1;
}

int unsetEnv(char *variable){
  if(varTable.count(variable)){
    if((strcmp(variable, toCharArr("HOME")) == 0) || (strcmp(variable, toCharArr("PATH")) == 0))
    {
      std::cout << "unable to erased HOME or PATH directory\n";
      return 1;
    }
    varTable.erase(variable);
    std::cout << "erased " << variable << std::endl;
    return 1;
  }
  std::cout << variable << " not exist." << std::endl;
  return 1;
}

char *pathInput(char *first, char *second){
  char *str; 
  str = combineCharArr(first, toCharArr(":"));
  str = combineCharArr(str, second);
  return str;
}


// if there is something like "cd ../.." or "cd ././." in the cmd, this function will fix it. 
void removeSubstrs(std::string &str, const std::string &substr, int dot){
   int n = substr.length();
   int dot_count = 0;
   //if there is two dots
   if(dot == 2){
     //delete every instance of "/.."
      for (auto i = str.find(substr); i != std::string::npos; i = str.find(substr)){
        dot_count++;
        str.erase(i, n);
      }
      for (auto i = str.find(toCharArr("/.")); i != std::string::npos; i = str.find(toCharArr("/.")))
        str.erase(i, 1);
      //delete the corresponding path follow by ".." . 
      while(dot_count > 0){
        auto i = str.find_last_of("/");
        str = str.substr(0, i);
        dot_count--;
      }
   }
   else{ // if there is one dot
     for (auto i = str.find(substr); i != std::string::npos; i = str.find(substr))
      str.erase(i, n);
   }
}


//TODO: EC Tilde expansion
char* getUserHomeDir(char *user){
    struct passwd* pw;
    if( ( pw = getpwnam(user)) == NULL ) {
      fprintf( stderr, "Unknown user\n");
    }
    return pw->pw_dir;
}