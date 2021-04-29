# THE NUTSHELL
A command interpreter for a Korn shell-like command language written in ``C/C++`` using ``Lex and Yacc`` running under Unix. The Nutshell will parse command lines and execute the
appropriate command(s). The core of the shell consists of shell commands, pipes, environment variables, aliases, pathname searching, tilde expansion and wild-carding.

to run the program:
```
make
./nutshell
```

![image](https://user-images.githubusercontent.com/44207825/116486591-03414980-a85c-11eb-8581-05a603ea236d.png)

List of build-in command word:
```
setenv variable word 
printenv
unsetenv variable
cd word
alias name word
unalias name
alias
bye
```
Non-build-in command:
```
The Nutshell will check (search for) the directories on the path 
that is the value of the environment variable PATH for the command. 
The command will be run only if the file exists and is executable.
```

Other features:
```
| for pipe
? for matching single character
* for matching a string of characters
~ for current user home path expansion
~/user for selected "user" home path expansion 
```
