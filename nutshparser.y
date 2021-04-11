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
#include <sys/wait.h>
#include <dirent.h>
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

int runSysCommand(char *command, char* arg);
int runSysCommandNoArg(char *command);

char* getUserHomeDir(char *user);
%}

%union {char *string;}

%start cmd_line
%token <string> BYE CD STRING ALIAS END UNALIAS SETENV PRINTENV UNSETENV  META PATH
%type <string> COMBINE_INPUT PATH_INPUT NON_BUILDIN

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
  | NON_BUILDIN END               {return 1;}
  | META

NON_BUILDIN     :
   STRING COMBINE_INPUT END  {runSysCommand($1, $2); return 1;}
  | STRING END                {runSysCommandNoArg($1); return 1;}


COMBINE_INPUT   :
  STRING COMBINE_INPUT       {$$ = combineCharArr(combineCharArr($1, toCharArr(" ")), $2);}
   | STRING                  {$$ = $1;}

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
    std::string temp = varTable["HOME"];
    std::string a = arg;
    temp += a.substr(1);
    removeSubstrs(temp, "/..", 2);
    removeSubstrs(temp, "/.", 1);
    char* t = toCharArr(temp);
    removeChar(t, '.');
    printf("path: %s \n", t);
		if(chdir(t) == 0) {
			dot = t;
      dotdot = toCharArr(getPrevPath(t));
      varTable["PWD"] = t;
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
    char* t = toCharArr(temp);
    removeChar(t, '.');
    printf("path: %s \n", t);
    if(t[strlen(t)-2] == ' '){
      t[strlen(t)-2] = '\0';
    }
    if(t[strlen(t)-1] == ' '){
      t[strlen(t)-1] = '\0';
    }
    printf("path relative: %s\n", toCharArr(t));
		if(chdir(t) == 0) {
			dot = t;
      dotdot = toCharArr(getPrevPath(t));
      varTable["PWD"] = t;
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
      char* t = toCharArr(temp);
      removeChar(t, '.');
      printf("path: %s \n", t);
			dot = t;
      dotdot = toCharArr(temp);
			varTable["PWD"] = t;
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
  if(aliasTable.count(token2))
    value = aliasTable[toCharArr(token2)];
  else
    return false;
  
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
      //if(aliasTable[token2] == nullptr)
        //unsetAlias(toCharArr(token2));
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
  if(varTable.count(token2))
    value = varTable[toCharArr(token2)];
  else
    return false;
  
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
      //unsetEnv(toCharArr(token2));
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

char* getUserHomeDir(char *user){
  struct passwd* pw;
  if( ( pw = getpwnam(user)) == NULL ) {
    fprintf( stderr, "Unknown user\n");
  }
  return pw->pw_dir;
}

int runSysCommand(char *command, char* arg){
  //printf("arg1: %s \n", arg);

  bool found = false;
  char* path;
  for(auto it = executables.begin(); it != executables.end(); it++){
    for(char* x : it->second){
      if(strcmp(x, command) == 0){
        // printf("executable: %s \n", x);
        // printf("path: %s \n", toCharArr(it->first));
        path = toCharArr(it->first);
        found = true;
        break;
      }
    }
  }
  if(!found){
    printf("%s: command not found\n", command);
    return 1;
  }
  char* argument[100];
  if(found && strlen(arg) != 0){
    if(arg[strlen(arg)-2] == ' '){
      arg[strlen(arg)-2] = '\0';
    }
    if(arg[strlen(arg)-1] == ' '){
      arg[strlen(arg)-1] = '\0';
    }
    //printf("arg: %s \n", arg);
    //printf("arg2: %s \n", arg);
    char *token = strtok(arg, " ");
    int i = 1;
    argument[0] = command;
    while (token != NULL)
    {
        argument[i++] = token;
        token = strtok(NULL, " ");
    }
    argument[i] = NULL;
      //  for(int j = 0; j< i; j++){
      //    printf("argument: %s \n", argument[j]);
      //  }

    command = combineCharArr(toCharArr("/"),command);
    command = combineCharArr(path, command);
      // printf("command: %s \n", command);
  }
    pid_t pid;
    pid = fork();
    if(pid == -1){
      printf("error forking! \n");
    }
    else if (pid == 0){ //child process
      // printf("command and args \n");
      execv(command, argument);
    }
    else{
      wait(NULL);
    }

  return 1;
}

int runSysCommandNoArg(char *command){
  
  bool found = false;
  char* path;
  for(auto it = executables.begin(); it != executables.end(); it++){
    for(char* x : it->second){
      if(strcmp(x, command) == 0){
        // printf("executable: %s \n", x);
        // printf("path: %s \n", toCharArr(it->first));
        path = toCharArr(it->first);
        found = true;
        break;
      }
    }
  }
  if(!found){
    printf("%s: command not found\n", command);
    return 1;
  }
  command = combineCharArr(toCharArr("/"),command);
  command = combineCharArr(path, command);
   pid_t pid;
    pid = fork();
    if(pid == -1){
      printf("error forking! \n");
    }
    else if (pid == 0){ //child process
      // printf("only one command \n");
      execl(command, command , (char*)0);
    }
    else{
      wait(NULL);
    }

  return 1;

}

