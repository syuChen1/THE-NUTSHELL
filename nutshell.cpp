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

vector<char*> filenames;
std::unordered_map<std::string, std::string> varTable;
std::unordered_map<std::string, std::string> aliasTable;
char* tilde;
char* dot;
char* dotdot;
int tokenCount = 0;

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

void getFileNames(){
    filenames.clear();
    struct dirent *de;
    DIR *dr = opendir(".");
    if (dr == NULL)  // opendir returns NULL if couldn't open directory
    {
        printf("Could not open current directory" );
        return;
    }
    while ((de = readdir(dr)) != NULL)
        filenames.push_back(de->d_name);
    closedir(dr);
    std::sort(filenames.begin(), filenames.end());
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
    varTable["HOME"] = cwd;
    varTable["PROMPT"] = "nutshell";
    varTable["PATH"] = "~/bin";

    //set . to curr path
    dot = toCharArr(cwd);

    //set .. to prev path
    cwd = getPrevPath(cwd);
    dotdot = toCharArr(cwd);

    tilde = toCharArr("/root");

    system("clear");
    while(1)
    {
        printf(MAG "[%s]>> " RESET, toCharArr(varTable["PWD"]));
        tokenCount = 0;
        getFileNames();
        yyparse();
    }

    return 0;
}
