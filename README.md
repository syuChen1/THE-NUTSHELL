# COP4600-Project-1-FLEX-and-BISON

to run the program:
```
make
./nutshell
```

TODO:
- [x] Alias expansions should only be performed on the first word of each command. (right now is performing in every word)
- [ ] Metacharacter
    - [x] > < | &
    - [ ] Still need to work on \ and "
        - [x] unable to access \
        - [ ] when do " , will mess out quote STRING unquote ( "STRING" )
- [x] Other Commands
- [x] Wildcard Matching
- [ ] test more complex pipelining. 

DEBUG:
- [ ] quote STRING unquote
    - Right now if you only have one quote and hit ENTER, cmd will wait for the next quote. Need to work on it so that if you have only one quote, it will act like a meta character, and metacharacter inside quote will not exit the quote. 
- [x] when trying to cd ./.. or cd ~/.. or cd ../. , it give wrong directory. I have codes for debugging cd ../.. and cd ./. But still needs minor adjustment to get the above code to work.  
- [x] cd te?t can not work. will return correct path, but syscall can not go there?
- [ ] cd "test dir"/"nested dir"

Extra Credit:
- [ ] Tilde Expansion
- [ ] File Name Completion
