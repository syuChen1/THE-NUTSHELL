#ifndef NUTSHELL_H
#define NUTSHELL_H
#include <unordered_map>
#include <vector>
// env variable table
extern std::unordered_map<std::string, std::string> varTable;
// alias table
extern std::unordered_map<std::string, std::string> aliasTable;
extern std::vector<char*> filenames;

std::string getPrevPath(std::string cwd);
char* toCharArr(std::string str);
char* combineCharArr(char* first, char* second);
void removeChar(char* s, char c);
void getFileNames();
extern char* getUserHomeDir(char *user);

extern char* tilde;
extern int tokenCount;
extern char* dot;
extern char* dotdot;
#endif