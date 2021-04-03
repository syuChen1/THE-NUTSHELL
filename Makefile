all:
	flex nutshscanner.l
	bison -d nutshparser.y
	g++ -o nutshell nutshell.cpp lex.yy.c nutshparser.tab.c
