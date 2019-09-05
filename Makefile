default:
	clear
	flex -l ass5.l
	bison -dv ass5.y 
	g++ -o ass5 ass5.tab.c lex.yy.c 
	./ass5 < input1.txt > interCode.txt

	flex -l interFlex.l
	bison -dv interBison.y 
	g++ -o interBison interBison.tab.c lex.yy.c 
	./interBison < interCode.txt > finalCode.s
	
clean:
	rm -f ass5 ass5.tab.c lex.yy.c ass5.output ass5.tab.h interBison interBison.tab.c interBison.tab.h