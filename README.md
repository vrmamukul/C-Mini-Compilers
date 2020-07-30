# C-Mini-Compilers

### A compiler for C like language which supports arithmetic, relational and logical operators, various data types, reading and printing from the console along with iterative and conditional statements using Bison and Flex.

## How to run file


### Method 1: Use makefile

```
make clean
make -f makefile

```

### Method 2: Use direct commands

```
flex -l ass5.l
bison -dv ass5.y 
g++ -o ass5 ass5.tab.c lex.yy.c 
./ass5 < input1.txt > interCode.txt

flex -l interFlex.l
bison -dv interBison.y 
g++ -o interBison interBison.tab.c lex.yy.c 
./interBison < interCode.txt > finalCode.s

```
