#include <stdio.h> 
#include <stdlib.h> 
#include <unistd.h> 
#include <sys/types.h> 
#include <string.h> 
#include <sys/wait.h> 
#include <bits/stdc++.h> 
#include <sstream> 
#include <iostream>
#include <fcntl.h>
using namespace std;

//function to copy string to char array
char* toCharArr(std::string str){
    char *temp = new char [str.length()+1];
    strcpy(temp, str.c_str());
    return temp;
}
  
int main(int argc, char **argv) 
{ 
     //FILE * fp;
     char* string;
     int fd;
    mode_t mode = S_IRUSR | S_IWUSR | S_IRGRP | S_IROTH;
    char *filename = "text3.txt";

    if(access("txt3.txt", F_OK) == -1)
        fd = creat(filename, mode);
    
    int file_desc = open("text3.txt", O_WRONLY | O_APPEND);
      
    // here the newfd is the file descriptor of stdout (i.e. 1)
    dup2(file_desc, 1); 
          
    // All the printf statements will be written in the file
    // "tricky.txt"
    printf("I will be printed in the file tricky.txt\n");
      
    return 0;

    int rd;     // read() return
    int rdup;       // dup():ed stdin for child
    int wdup;       // dup():ed stdout for child
    char inbuf[80];  // Input from child
    char    *eol;       // End of line
    
    int toParent[2];  // Used to store two ends of first pipe 
    int toChild[2];  // Used to store two ends of second pipe 
  
    pid_t p; 
  
	pipe(toParent);
	pipe(toChild);
	
	int nums[5];
	
    char* chararr[5] = { toCharArr("/bin/echo"), toCharArr("hello"), toCharArr(">"), toCharArr("text.txt"), NULL};
    char* chararr2[3] = { toCharArr("/bin/echo"), toCharArr("hello"), NULL};

    for(int i = 0; i < 5; i++)
    {
        if((strcmp(chararr[i], ">") == 0) || (strcmp(chararr[i], "<") == 0))
        {

        }
    }
	
    p = fork(); 
  
    if (p < 0) 
    { 
        fprintf(stderr, "fork Failed" ); 
        return 1; 
    } 
  
    // Child process 
    else if (p == 0) 
    {  
        close(toParent[1]);
        close(toChild[0]);

        close(0);
        // Create a "new stdin", which WILL be 0 (zero)
         if ((rdup = dup(toChild[0])) < 0) {
            fprintf(stderr, "Failed dup(stdin)\n");
            return 4;
        }

        close(1);

         // Create a "new stdout", which WILL be 1 (one)
        if ((wdup = dup(toParent[1])) < 0) {
            fprintf(stderr, "Failed dup(stdout)\n");
            return 5;
        }

        fprintf(stderr, "rdup: %d, wdup %d\n", rdup, wdup);

        execv("/bin/echo", chararr);

        fprintf(stderr, "Parent: execl() failed!\n");
        return 4;

    }
  
    // parent process 
    else
    { 
        wait(NULL);
        // Close the ends we don't need, to avoid writing back to ourself
        close(toChild[0]);
        close(toParent[1]);

         // Write one line to the child and expect a reply, or EOF.
    do {
        write(toChild[1], "Hello\n", strlen("Hello\n"));
        if ((rd = read(toParent[0], inbuf, 80)) > 0) {
            // Chop off ending EOL
            if ((eol = rindex(inbuf, '\n')) != NULL)
                *eol = '\0';
            printf("Parent: Read \"%s\" from child.\n", inbuf);
        }
    } while (rd > 0);

    fprintf(stderr, "Parent: Child done!\n");

    return 0;


    } 
return 0;
}