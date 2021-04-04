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
int printAlias();
int unsetAlias(char *name);
void removeSubstrs(std::string &str, const std::string &substr, int dot);

int updateEnv(char *variable, char *word);
int printEnv();
int unsetEnv(char *variable);
char *pathInput(char *first, char *second);

char* getUserHomeDir(char *user);
%}

%union {char *string;}

%start cmd_line
%token <string> BYE CD STRING ALIAS END UNALIAS SETENV PRINTENV UNSETENV  META
%type <string> COMBINE_INPUT PATH_INPUT

%%
cmd_line    :
	  BYE END 		              {exit(1); return 1; }
	| CD STRING END        			{runCD($2); return 1;}
  | CD END                    {runCD(toCharArr("~")); return 1;}
	| ALIAS STRING STRING END		{runSetAlias($2, $3); return 1;}
  | ALIAS END                 {printAlias(); return 1;}
  | UNALIAS STRING END        {unsetAlias($2); return 1;}
  | SETENV STRING PATH_INPUT END  {updateEnv($2,$3); return 1;}
  | PRINTENV END              {printEnv(); return 1;}
  | UNSETENV STRING END       {unsetEnv($2); return 1;}
  | STRING COMBINE_INPUT END  {system(combineCharArr($1, $2)); return 1;}
  | META

COMBINE_INPUT   :
                            {$$ = toCharArr("");}
  | STRING COMBINE_INPUT    {$$ = combineCharArr(toCharArr(" "), combineCharArr($1,$2));}

PATH_INPUT  :
    STRING                  {$$ = $1;}
  | STRING ':' PATH_INPUT   {$$ = pathInput($1,$3);}

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

// CD
int runCD(char* arg) {
  //if the first argument is ~
  if (arg[0] == '~'){
    std::string temp = varTable["HOME"];
    std::string a = arg;
    temp += a.substr(1);
    removeSubstrs(temp, "/..", 2);
    removeSubstrs(temp, "/.", 1);
		if(chdir(toCharArr(temp)) == 0) {
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
		temp += "/";
    temp += arg;
    removeSubstrs(temp, "/..", 2);
    removeSubstrs(temp, "/.", 1);
    std::cout<< temp << std::endl;
		if(chdir(toCharArr(temp)) == 0) {
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
  std::cout << name << " not exist." << std::endl;
  return 1;
}

// Env Variable
int updateEnv(char *variable, char *word){
  varTable[variable] = word;
  std::cout << "set " << variable << " to " << word << std::endl;
  return 1;
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
    varTable.erase(variable);
    std::cout << "earsed " << variable << std::endl;
    return 1;
  }
  std::cout << variable << " not exist." << std::endl;
  return 1;
}

char *pathInput(char *first, char *second){
  char *str; 
  if( second[0] == '~'){
    str = combineCharArr(first, toCharArr(":"));
    str = combineCharArr(str, second);
  }
  else{
    str = combineCharArr(first, toCharArr(":~"));
    str = combineCharArr(str, second);
  }
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
    printf( "login name  %s\n", pw->pw_name );
    printf( "home dir    %s\n", pw->pw_dir );
    return pw->pw_dir;
}