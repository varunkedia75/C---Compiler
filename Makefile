default:
	clear
	flex -l ass5.l
	bison -dv ass5.y 
	g++ -o ass5 ass5.tab.c lex.yy.c 
	./ass5 
	
clean:
	rm -f ass5 ass5.tab.c lex.yy.c ass5.output ass5.tab.h