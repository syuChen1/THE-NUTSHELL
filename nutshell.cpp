#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "nutshell.h"
#include <unistd.h>
#include <limits.h>
#include <iostream>
#include <cstdio>
#include <dirent.h>
#include <vector>
#include <algorithm>
#include "nutshparser.tab.h"

#define MAG   "\x1B[35m"
#define RESET "\x1B[0m"
using namespace std;

vector<char*> cwdFiles;
std::unordered_map<std::string, std::string> varTable;
std::unordered_map<std::string, std::string> aliasTable;
std::unordered_map<std::string, std::vector<char*>> executables; 
std::string dot;
std::string dotdot;
int tokenCount = 0;

Cmd_t cmdTable;
Command_t* make_Command_object(std::string name, std::vector<std::string> args, std::string input, std::string output , int order, bool buildin)
{
    Command_t* res;
    res->name = name;
    cout << res->name << endl;
    cout << res->args.size() << endl;

    res->args = args;
    cout << "above" << endl;
    cout << input << endl;
    res->input = input;
    cout << res->args.size() << endl;
    res->output = output;
    res->order = order;
    res->buildin = buildin;
    cout << "here" << endl;
    return res;
}
File_t* make_File_object(std::string name, int accessible, std::string input, std::string output, int order)
{
    File_t* res;
    res->name = name;
    res->accessible = accessible;
    res->input = input;
    res->output = output;
    res->order = order;
    return res;

}
Cmd_t make_Cmd_object(std::vector<Command_t*>* command, std::vector<File_t*>* file)
{
    Cmd_t res;
    res.comVector = command;
    res.fileVector = file;
    return res;

}

void removeChar(char* s, char c)
{
    int j, n = strlen(s);
    for (int i = j = 0; i < n; i++)
        if (s[i] != c)
            s[j++] = s[i];
    s[j] = '\0';
}
//function to copy string to char array
char* toCharArr(std::string str){
    char *temp = new char [str.length()+1];
    strcpy(temp, str.c_str());
    return temp;
}

//function to combine two char array
char* combineCharArr(char* first, char* second){
  char *str = (char*) malloc(1 + strlen(first)+ strlen(second) );
  strcpy(str, first);
  strcat(str, second);
  return str;
}

void getFileNames(vector<char*> *v, string path){
    v->clear();
    struct dirent *de;
    DIR *dr = opendir(toCharArr (path));
    if (dr == NULL)  // opendir returns NULL if couldn't open directory
    {
        return;
    }
    while ((de = readdir(dr)) != NULL)
        v->push_back(de->d_name);
    closedir(dr);
    std::sort(v->begin(), v->end());
}

int getPathFiles(char *path){

    char* temp = toCharArr(path);
    removeChar(temp, '.');
    char *token = strtok(temp, toCharArr(":"));

    // Keep printing tokens while one of the
    // delimiters present in str[].
    while (token != NULL)
    {
      struct dirent *de;
      DIR *dr = opendir(token);
      if (dr != NULL){
        std::vector<char*> filenames;
        std::string s = token;
        getFileNames(&filenames, s);
        executables[s] = filenames;
        token = strtok(NULL, ":");
      }
      else{
        token = strtok(NULL, ":");
      }
    }

    return 1;
}


//function to get the current dir path
string getcwd_string( void ) {
   char buff[PATH_MAX];
   getcwd( buff, PATH_MAX );
   string cwd( buff );
   return cwd;
}

//function to find prev path
string getPrevPath(string cwd){
    char *temp = toCharArr(cwd);
    char *pointer = strrchr(temp, '/');
    while(*pointer != '\0') {
        *pointer ='\0';
        pointer++;
    }

    cwd = temp;
    return cwd;
}

int main(){
    //get the curr dir path
    string cwd = getcwd_string();

    varTable["PWD"] = cwd;
    varTable["HOME"] = "/root";
    varTable["PROMPT"] = "nutshell";
    varTable["PATH"] = ".:/bin:/usr/bin";
    //set . to curr path
    dot = toCharArr(cwd);

    //set .. to prev path
    cwd = getPrevPath(cwd);
    dotdot = toCharArr(cwd);

    system("clear");
    while(1)
    {
        printf(MAG "[%s]>> " RESET, toCharArr(varTable["PWD"]));
        tokenCount = 0;
        getFileNames(&cwdFiles, ".");
        getPathFiles(toCharArr(varTable["PATH"]));
        yyparse();
    }

    return 0;
}