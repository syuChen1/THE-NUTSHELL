#ifndef NUTSHELL_H
#define NUTSHELL_H
#include <unordered_map>
// env variable table
extern std::unordered_map<std::string, std::string> varTable;
// alias table
extern std::unordered_map<std::string, std::string> aliasTable;

std::string getPrevPath(std::string cwd);
char* toCharArr(std::string str);
char* combineCharArr(char* first, char* second);
extern char* tilde;
#endif