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
#include <algorithm>
#include <iostream>
using namespace std;

int yylex();
int yyerror(char *s);

int runCD(string arg);

int runSetAlias(string name, string word);
bool aliasLoopCheck(string token1, string token2);
int printAlias();
int unsetAlias(string name);
void removeSubstrs(std::string &str, const std::string &substr, int dot);

int updateEnv(string variable, string word);
bool envLoopCheck(string  token1, string token2);
int printEnv();
int unsetEnv(string variable);
string pathInput(string first, string second);
int runSysCommand(std::vector<std::string> commands);

string getUserHomeDir(string user);
%}

%code requires {
#include "nutshell.h"
}


%define api.value.type union
%start cmd_line
%token <std::string*> BYE CD STRING ALIAS END UNALIAS SETENV PRINTENV UNSETENV  PATH NON_BUILD_IN_COMMAND
%type <std::string*> COMBINE_INPUT PATH_INPUT
%type <int> COMMAND NON_BUILD_IN BUILD_IN

%%
cmd_line    :
	  BYE END 		                {exit(1); return 1; }
  | COMMAND END                 {return 1;}

COMMAND     :
  NON_BUILD_IN                  {$$ = $1;}
  | BUILD_IN                    {$$ = $1;}
  | STRING                      {cout << "this is a file :" << $1 <<endl; $$ = 1;}
  
NON_BUILD_IN    :
	  CD STRING         			    {$$ = runCD(*$2);}
  | CD                          {$$ = runCD("~");}
	| ALIAS STRING STRING 		    {if(!aliasLoopCheck(*$2, *$3)){ 
                                  $$ = runSetAlias(*$2, *$3);}}
  | ALIAS                       {$$ = printAlias();}
  | UNALIAS STRING              {$$ = unsetAlias(*$2);}
  | SETENV STRING PATH_INPUT    {if(!envLoopCheck(*$2, *$3)){$$ = updateEnv(*$2,*$3);}}
  | PRINTENV                    {$$ = printEnv();}
  | UNSETENV STRING             {$$ = unsetEnv(*$2);}

BUILD_IN        :
  NON_BUILD_IN_COMMAND COMBINE_INPUT    {commands.push_back(*$1); $$ = runSysCommand(commands);}

COMBINE_INPUT   :
     STRING COMBINE_INPUT       {commands.push_back(*$1);}
   | STRING                     {commands.push_back(*$1);}
   |                            {}

PATH_INPUT  :
    PATH STRING ':' PATH_INPUT   {$$ = new std::string(*$1 + pathInput(*$2,*$4));}
  | STRING ':' PATH_INPUT        {$$ = new std::string(pathInput(*$1,*$3));}
  | STRING                       {$$ = new std::string(*$1);}

%%

int yyerror(char *s) {
  printf("%s\n",s);
  return 0;
  }

// CD
int runCD(string arg) {
  //if the first argument is ~
  if (arg[0] == '~'){
    std::string temp;
    std::string a;
    if(isalpha(arg[1]) == 0)
    { 
      temp = varTable["HOME"];
      a = arg;
      temp += a.substr(1);
    }
    else {
      temp = varTable["PWD"];
      temp = temp + '/' + arg;
    }
    removeSubstrs(temp, "/..", 2);
    removeSubstrs(temp, "/.", 1);
    auto found = temp.find('.');
    if(found != string::npos) temp.erase(found);
    cout << "path : " << temp << endl;
		if(chdir(toCharArr(temp)) == 0) {
			dot = temp;
      dotdot = getPrevPath(toCharArr(temp));
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
    auto found = temp.find('.');
    if(found != string::npos) temp.erase(found);
    //cout << "path : " << temp << endl;

    // if(t[strlen(t)-2] == ' '){
    //   t[strlen(t)-2] = '\0';
    // }
    // if(t[strlen(t)-1] == ' '){
    //   t[strlen(t)-1] = '\0';
    // }
    cout << "path relative: " << temp << endl;
		if(chdir(toCharArr(temp)) == 0) {
			dot = temp;
      dotdot = getPrevPath(toCharArr(temp));
      varTable["PWD"] = temp;
		}
		else {
			//strcpy(varTable.word[0], varTable.word[0]); // fix
			printf("Directory not found\n");
			return 1;
		}
	}

	else { // arg is absolute path
		if(chdir(toCharArr(arg)) == 0){
      std::string temp = arg;
      removeSubstrs(temp, "/..", 2);
      removeSubstrs(temp, "/.", 1);
      auto found = temp.find('.');
      if(found != string::npos) temp.erase(found);
      cout << "path : " << temp << endl;
			dot = temp;
      dotdot = getPrevPath(toCharArr(temp));
			varTable["PWD"] = temp;
			dotdot = getPrevPath(varTable["PWD"]);
		}
		else {
			printf("Directory not found\n");
      return 1;
		}
	}
	return 1;
}

// Alias
int runSetAlias(string name, string word) {
  if(name == word){
    cout << "Error, expansion of" << name << "would create a loop.\n";
		return 1;
	}
  else if(aliasTable.count(name) && aliasTable[name]== word){
		cout << "Error, expansion of" << name << "would create a loop.\n";
		return 1;
	}
	aliasTable[name] = word;
	return 1;
}

//check for infinite loop in alias table
bool aliasLoopCheck(string token1, string token2)
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
    value = aliasTable[token2];
  else
    return false;
  
  while(1)
  {
    if(token1 == value)
    {
      flag = true;
      std::cout << "inifinite alias loop detected!\n";
      break;
    }
    else if(!aliasTable.count(value))
    {
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

int unsetAlias(string name){
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
int updateEnv(string variable, string word){
  varTable[variable] = word;
  std::cout << "set " << variable << " to " << word << std::endl;
  return 1;
}

//check for infinite loop in environment variable table
bool envLoopCheck(string token1, string token2)
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
    value = varTable[token2];
  else
    return false;
  
  while(1)
  {
    if(token1 == value)
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

int unsetEnv(string variable){
  if(varTable.count(variable)){
    if(variable == "HOME" || variable == "PATH")
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

string pathInput(string first, string second){
  string str; 
  str = first + ":" + second;
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

string getUserHomeDir(string user){
  struct passwd* pw;
  if( ( pw = getpwnam(toCharArr(user))) == NULL ) {
    fprintf( stderr, "Unknown user\n");
    return "";
  }
  return pw->pw_dir;
}

int runSysCommand(std::vector<std::string> commands){

  std::reverse(commands.begin(), commands.end());
  char* path;
  for(auto it = executables.begin(); it != executables.end(); it++){
     for(char* x : it->second){
       if(strcmp(x, toCharArr(commands[0])) == 0){
          //printf("executable: %s \n", x);
          //printf("path: %s \n", toCharArr(it->first));
        path = toCharArr(it->first);
        break;
      }
    }
  }

  commands[0] = "/" + commands[0];
  commands[0] = std::string(path) + commands[0];
  printf("Executable: %s \n", toCharArr(commands[0]));

  pid_t pid;
  pid = fork();
  if(pid == -1){      
    printf("error forking! \n");
  }
  else if (pid == 0){ //child process
    if(commands.size() > 1){
      char* arguments[commands.size()+1];
      for(int i = 0; i< commands.size(); i++)
        arguments[i] = toCharArr(commands[i]);
      arguments[commands.size()] = NULL;
      execv(toCharArr(commands[0]), arguments);
     }
     else{
        execl(toCharArr(commands[0]), toCharArr(commands[0]), NULL);
      }
    }
  else{
    wait(NULL);
  }

  return 1;
}