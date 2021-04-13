#include  <fcntl.h>                              //
#include  <stdio.h>                              //
#include  <stdlib.h>                             //
#include  <string.h>                             //
#include  <sys/types.h>                          //
#include  <sys/wait.h>                           //
#include  <sys/stat.h>                           //
#include  <termios.h>                            //
#include  <unistd.h>                             //
#include    <vector>
                                                 //
#define INPUT_END 1                              // INPUT_END means where the pipe takes input
#define OUTPUT_END 0  
                           // OUTPUT_END means where the pipe produces output
                                                 
char* WhichCommand(char* command[]){

    return "";
}

std::vector<char*> handleCmd(std::vector <char*> arr){
    
}

int main(int argc, char* argv[])                 //
{                                                //
    pid_t pid1;                                  // [STDIN -> terminal_input, STDOUT -> terminal_output]                       (of the parent process)
    pid_t pid2;                                  //
    int fd[2];                                   //
                                                 //
    pipe(fd);   
    
    pid1 = fork();                       // [STDIN -> terminal_input, STDOUT -> terminal_output, fd[0] -> pipe_input, fd[1] -> pipe_output]
    if(pid1 == 0)   
    {
        switch(WhichCommand(c))
        {
            case FIRST:
                close(fd[OUTPUT_END]);                    //[STDIN -> terminal_input, STDOUT -> terminal_output, fd[0] -> pipe_input] (of the ls process)
                dup2(fd[INPUT_END], STDOUT_FILENO);      // [STDIN -> terminal_input, STDOUT -> pipe_input, fd[0] -> pipe_input]      (of the ls process)
                close(fd[INPUT_END]);                    // [STDIN -> terminal_input, STDOUT -> pipe_input]                           (of the ls process)
                execv("wc", "wc", "-l", (char*) NULL);  
                break;

            case LAST:
                close(fd[INPUT_END]);                    // [STDIN -> terminal_input, STDOUT -> terminal_output, fd[1] -> pipe_output] (of the WC process)
                dup2(fd[OUTPUT_END], STDIN_FILENO);      // [STDIN -> pipe_output, STDOUT -> terminal_output, fd[1] -> pipe_output]    (of the WC process)
                close(fd[OUTPUT_END]);                   // [STDIN -> pipe_output, STDOUT -> terminal_output]                          (of the WC process)
                execv("wc", "wc", "-l", (char*) NULL);  
                break;

            case ONLY:
                execv("wc", "wc", "-l", (char*) NULL);
                break;

            case DEFAULT:
                close(fd[OUTPUT_END]);
                dup2(fd[OUTPUT_END], STDIN_FILENO);      // [STDIN -> pipe_output, STDOUT -> terminal_output, fd[1] -> pipe_output]    (of the WC process)
                dup2(fd[INPUT_END], STDOUT_FILENO);      // [STDIN -> pipe_output, STDOUT -> terminal_output, fd[1] -> pipe_output]    (of the WC process)
                close(fd[INPUT_END]);                   // [STDIN -> pipe_output, STDOUT -> terminal_output]                          (of the WC process)
                execv("wc", "wc", "-l", (char*) NULL);  
                break;
        }                       
    }                                            
    else if(pid1 > 0)                                    
    {                                            //
                                                 //
        close(fd[OUTPUT_END]);                   // [STDIN -> terminal_input, STDOUT -> terminal_output, fd[0] -> pipe_input] (of the parent process)
        close(fd[INPUT_END]);                    // [STDIN -> terminal_input, STDOUT -> terminal_output]                      (of the parent process)
        waitpid(-1, NULL, 0);                    // As the parent process - we wait for a process to die (-1) means I don't care which one - it could be either ls or wc
        waitpid(-1, NULL, 0);                    // As the parent process - we wait for the another process to die.
                                                 // At this point we can safely assume both process are completed
    }     
    return 0;                                       
}                                                