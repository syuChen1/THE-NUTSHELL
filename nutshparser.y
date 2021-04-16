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
#include <sstream>
#include <fcntl.h>
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

// [0]fileName [1]Args [2]STDIN [3]STDOUT [4]ORDER [5]TYPE
int PipeCall(std::vector<std::vector<std::string>> cmd_table);

int RedirectCall(std::vector<std::vector<std::string>> cmd_table);
%}

%code requires {
#include "nutshell.h"
}


%define api.value.type union
%start cmd_line
%token <std::string*> BYE CD STRING ALIAS END UNALIAS SETENV PRINTENV UNSETENV  PATH 
%type <std::string*> PATH_INPUT COMBINE_INPUT
%type <int> CMD COMMAND  PIPE REDIRECT


%%
cmd_line    :
	  BYE END 		                {exit(1); return 1; }
  | CMD END                     {return 1;}

CMD     :
    COMMAND                     {$$ = 1;}
  | PIPE '&'                    {background = true; PipeCall(cmd_table); $$ =1; }
  | PIPE                        {PipeCall(cmd_table); $$ =1; }
  | REDIRECT '&'                {background = true; RedirectCall(cmd_table); $$ =1;}
  | REDIRECT                    {RedirectCall(cmd_table); $$ =1;}


PIPE   :
    STRING COMBINE_INPUT   {
                                          cmd_table[commandCount].push_back(*$1);
                                          cmd_table[commandCount].push_back(*$2);
                                          cmd_table[commandCount].push_back("STDIN"); 
                                          cmd_table[commandCount].push_back("STDOUT"); 
                                          cmd_table[commandCount].push_back(to_string(commandCount)); 
                                          cmd_table[commandCount].push_back("NONBI"); 
                                          commandCount++;
                                          $$ = 1;
                                        }  
  | PIPE '|' PIPE                       {$$ = 1;}  


REDIRECT    : 
    STRING COMBINE_INPUT '>' STRING    {
                                                      cmd_table[commandCount].push_back(*$1);
                                                      cmd_table[commandCount].push_back(*$2);
                                                      cmd_table[commandCount].push_back("STDIN"); 
                                                      cmd_table[commandCount].push_back("STDOUT"); 
                                                      cmd_table[commandCount].push_back(to_string(commandCount)); 
                                                      cmd_table[commandCount].push_back("NONBI"); 
                                                      commandCount++;
                                                      cmd_table[commandCount].push_back(*$4);
                                                      cmd_table[commandCount].push_back("");
                                                      cmd_table[commandCount].push_back(cmd_table[commandCount-1][0]); 
                                                      cmd_table[commandCount].push_back("STDOUT"); 
                                                      cmd_table[commandCount].push_back(to_string(commandCount)); 
                                                      cmd_table[commandCount].push_back("FILE"); 
                                                      commandCount++;
                                                      $$ = 1;
                                                    }    
  | STRING COMBINE_INPUT '<' STRING    {
                                                      cmd_table[commandCount].push_back(*$4);
                                                      cmd_table[commandCount].push_back("");
                                                      cmd_table[commandCount].push_back("STDIN"); 
                                                      cmd_table[commandCount].push_back("STDOUT"); 
                                                      cmd_table[commandCount].push_back(to_string(commandCount)); 
                                                      cmd_table[commandCount].push_back("FILE"); 
                                                      commandCount++;
                                                      cmd_table[commandCount].push_back(*$1);
                                                      cmd_table[commandCount].push_back(*$2);
                                                      cmd_table[commandCount].push_back(cmd_table[commandCount-1][0]); 
                                                      cmd_table[commandCount].push_back("STDOUT"); 
                                                      cmd_table[commandCount].push_back(to_string(commandCount)); 
                                                      cmd_table[commandCount].push_back("NONBI");
                                                      commandCount++;
                                                      $$ = 1;
                                                    }    
  

COMMAND    :
	  CD STRING  END        			    {runCD(*$2);return 1;}
  | CD   END                       {runCD("~"); return 1;}
	| ALIAS STRING STRING END		    {if(!aliasLoopCheck(*$2, *$3)){ 
                                  runSetAlias(*$2, *$3);} return 1;}
  | ALIAS  END                     { printAlias(); return 1;}  

  | UNALIAS STRING  END            {unsetAlias(*$2);return 1;}
  | SETENV STRING PATH_INPUT END   {if(!envLoopCheck(*$2, *$3)){updateEnv(*$2,*$3);}return 1;}

  | PRINTENV    END                { printEnv(); return 1;}  
  | UNSETENV STRING  END           {unsetEnv(*$2);return 1;}

                                        
COMBINE_INPUT   :
     %empty                     {string s = ""; $$ = &s;}
   | STRING                     {$$ = new std::string(*$1);}
   | COMBINE_INPUT STRING       {$$ = new std::string(*$1 + " " + *$2);}

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
      temp = dot;
      temp = temp + '/' + arg;
    }
    removeSubstrs(temp, "/..", 2);
    removeSubstrs(temp, "/.", 1);
    auto found = temp.find('.');
    if(found != string::npos) temp.erase(found);
   // cout << "path : " << temp << endl;
		if(chdir(toCharArr(temp)) == 0) {
			dot = temp;
      dotdot = getPrevPath(toCharArr(temp));
      dot = temp;
		}
		else {
			//strcpy(varTable.word[0], varTable.word[0]); // fix
			printf("Directory not found\n");
			return 1;
		}

  }
  // arg is relative path
	else if (arg[0] != '/') {
    std::string temp = dot;
    std::string a = arg;
		temp += "/";
    temp += a;
    //cout << temp << endl;
    removeSubstrs(temp, "/..", 2);
    removeSubstrs(temp, "/.", 1);
    auto found = temp.find('.');
    if(found != string::npos) temp.erase(found, 1);
    //cout << "path : " << temp << endl;

    // if(t[strlen(t)-2] == ' '){
    //   t[strlen(t)-2] = '\0';
    // }
    // if(t[strlen(t)-1] == ' '){
    //   t[strlen(t)-1] = '\0';
    // }
    //cout << "path relative: " << temp << endl;
		if(chdir(toCharArr(temp)) == 0) {
			dot = temp;
      dotdot = getPrevPath(toCharArr(temp));
      dot = temp;
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
      //cout << "path : " << temp << endl;
			dot = temp;
      dotdot = getPrevPath(toCharArr(temp));
			dot = temp;
			dotdot = getPrevPath(dot);
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
    //std::cout << "earsed " << name << std::endl;
    return 1;
  }
  else 
    std::cout << name << " not exist." << std::endl;
  return 1;
}

// Env Variable
int updateEnv(string variable, string word){
  varTable[variable] = word;
  //std::cout << "set " << variable << " to " << word << std::endl;
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


// [0]fileName [1]Args [2]STDIN [3]STDOUT [4]ORDER [5]TYPE
// 0 output // 1 input
int PipeCall(std::vector<std::vector<std::string>> cmd_table)
{
  int new_fds[2];
  int old_fds[2];

  for(int i = 0 ; i < commandCount; i++){
    if(i < commandCount -1){
      pipe(new_fds);
    }
    pid_t pid = fork();
    if(pid == 0)
    {

      if(i != 0)
      {
        dup2(old_fds[0], 0);
        close(old_fds[0]);
        close(old_fds[1]);
      }
      if(i < commandCount -1)
      {
        close(new_fds[0]);
        dup2(new_fds[1], 1);
        close(new_fds[1]);
      }
      //execute the command
      char* path;
      bool found = false;
      for(auto it = executables.begin(); it != executables.end(); it++)
      {
        for(char* x : it->second)
        {
          if(strcmp(x, toCharArr(cmd_table[i][0])) == 0)
          {
            path = toCharArr(it->first);
            found = true;
            break;
          }
        }
      }
      if(!found){
        cout << cmd_table[i][0] << ": command not found" << endl;
        return 0;
      }
      char *cc =strdup(toCharArr(cmd_table[i][0]));  
      cmd_table[i][0] = "/" + cmd_table[i][0];
      cmd_table[i][0] = std::string(path) + cmd_table[i][0];
      //printf("Executable: %s \n", toCharArr(cmd_table[i][0]));
      if(cmd_table[i][1].size() > 0)
      {
        char* arguments[cmd_table[i][1].size()+2];
        arguments[0] = strdup(cc);
        stringstream ss(cmd_table[i][1]);
        string word;
        int u = 1;
        while (ss >> word) {
        // printf("%s\n", toCharArr(word));
          arguments[u++] = toCharArr(word);
        }
        arguments[u] = NULL;
        if( execv(toCharArr(cmd_table[i][0]), arguments) < 0)
        {
          perror("execl error");
          return 1;
        }
      }
      else
      {
        if(execl(toCharArr(cmd_table[i][0]), toCharArr(cmd_table[i][0]), NULL) < 0)
          {
            perror("execl error");
            return 1;
          }
      }
    }
    else
    {
      if(i != 0){
        close(old_fds[0]);
        close(old_fds[1]);
      }
      if(i < commandCount -1){
        old_fds[0] = new_fds[0];
        old_fds[1] = new_fds[1];
      }
        if(!background) wait(NULL);
    }
  }
  if(cmd_table.size() > 1){
    close(old_fds[0]);
    close(old_fds[1]);
  }
}

// [0]fileName [1]Args [2]STDIN [3]STDOUT [4]ORDER [5]TYPE
int RedirectCall(std::vector<std::vector<std::string>> cmd_table){
  return 1;
}