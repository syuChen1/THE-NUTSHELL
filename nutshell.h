#ifndef NUTSHELL_H
#define NUTSHELL_H

#include <unordered_map>
#include <vector>
#define MAG   "\x1B[35m"
#define RESET "\x1B[0m"
// env variable table
extern std::unordered_map<std::string, std::string> varTable;
// alias table
extern std::unordered_map<std::string, std::string> aliasTable;
extern std::unordered_map<std::string, std::vector<char*>> executables; 


extern std::vector<std::vector<std::string>> cmd_table;


extern std::vector<char*> cwdFiles;

std::string getPrevPath(std::string cwd);
char* toCharArr(std::string str);
char* combineCharArr(char* first, char* second);
void removeChar(char* s, char c);
void getFileNames(std::vector<char*> *v, std::string path);
extern std::string getUserHomeDir(std::string user);
extern int tokenCount;
extern int commandCount;
extern bool firstWord;
extern std::string dot;
extern std::string dotdot;
#endif