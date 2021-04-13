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

struct Command_t
{
    std::string name;
    std::vector<std::string> args;
    std::string input;
    std::string output;
    int order;
    bool buildin;
};
struct File_t
{
    std::string name;
    int accessible;
    std::string input;
    std::string output;
    int order;
};
struct Cmd_t {
    std::vector<Command_t>* comVector;
    std::vector<File_t>* fileVector;
};
Command_t make_Command_object(std::string name, std::vector<std::string> args, std::string input, std::string output , int order, bool buildin);
File_t make_File_object(std::string name, int accessible, std::string input, std::string output, int order);
Cmd_t make_Cmd_object(std::vector<Command_t>* command, std::vector<File_t>* file);

extern std::vector<char*> cwdFiles;

std::string getPrevPath(std::string cwd);
char* toCharArr(std::string str);
char* combineCharArr(char* first, char* second);
void removeChar(char* s, char c);
void getFileNames(std::vector<char*> *v, std::string path);
extern std::string getUserHomeDir(std::string user);
extern int tokenCount;
extern std::string dot;
extern std::string dotdot;
#endif