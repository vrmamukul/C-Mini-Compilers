%option noyywrap
%x COMMENT_SINGLE
%x COMMENT_MULTI

%top{
#include "header.h"
#include "ass5.tab.h"
}

%{
char* commentStart;
%}


int_const       [0-9]+
alphanum        [a-zA-Z0-9_]+
IComma            [\'\"]


%%

\".*?\"           { fprintf(yyout,"%s",yytext);}

<INITIAL>"//"     { commentStart = yytext; 
                    BEGIN(COMMENT_SINGLE);}

<COMMENT_SINGLE>\n  { char* comment = strndup(commentStart, yytext - commentStart); 
                      free(comment); 
                      BEGIN(INITIAL);}

<COMMENT_SINGLE>[^\n]+ {}

<INITIAL>"/*"     { commentStart = yytext; 
                    BEGIN(COMMENT_MULTI); }

<COMMENT_MULTI>"*/" { char* comment = strndup(commentStart, yytext + 2 - commentStart);
                      free(comment); 
                      BEGIN(INITIAL);}

<COMMENT_MULTI>.   {} 

<COMMENT_MULTI>\n  {} 



"#include"    {  yylval.attrb1.name = new string(yytext);  return HASH;}
"return"      {  yylval.attrb1.name = new string(yytext);  return RETURN;}
"break"       {  yylval.attrb1.name = new string(yytext);  return BREAK;}
"continue"    {  yylval.attrb1.name = new string(yytext);  return CONTINUE;} 

"int"         {  yylval.attrb1.name = new string(yytext); return INT;}
"float"       {  yylval.attrb1.name = new string(yytext); return FLOAT;}

"<="          {  yylval.attrb1.name = new string(yytext);  return LT_EQ;}
">="          {  yylval.attrb1.name = new string(yytext);  return GT_EQ;}
"<"           {  yylval.attrb1.name = new string(yytext);  return LT;}
">"           {  yylval.attrb1.name = new string(yytext);  return GT;}
"=="          {  yylval.attrb1.name = new string(yytext);  return EQ_EQ;}
"!="          {  yylval.attrb1.name = new string(yytext);  return NOT_EQ;}


"++"		  {  yylval.attrb1.name = new string(yytext);  return INCR;}
"--"		  {  yylval.attrb1.name = new string(yytext);  return DECR;}
"+="		  {  yylval.attrb1.name = new string(yytext);  return PLUS_ASS;}
"-=" 		  {  yylval.attrb1.name = new string(yytext);  return MINUS_ASS;}
"*="		  {  yylval.attrb1.name = new string(yytext);  return MULT_ASS;}
"/="		  {  yylval.attrb1.name = new string(yytext);  return DIV_ASS;}
"+"           {  yylval.attrb1.name = new string(yytext);  return PLUS;}
"-"           {  yylval.attrb1.name = new string(yytext);  return MINUS;}
"*"           {  yylval.attrb1.name = new string(yytext);  return MULTI;}
"/"           {  yylval.attrb1.name = new string(yytext);  return DIV;}
"^"           {  yylval.attrb1.name = new string(yytext);  return POW;}

"&"           {  yylval.attrb1.name = new string(yytext);  return AMP;}

"&&"          {  yylval.attrb1.name = new string(yytext);  return AND;}
"||"          {  yylval.attrb1.name = new string(yytext);  return OR;}
"!"			  {  yylval.attrb1.name = new string(yytext);  return NOT;}

"="           {  yylval.attrb1.name = new string(yytext);  return ASSIGN;}
","           {  yylval.attrb1.name = new string(yytext);  return COMMA;}

"["           {  yylval.attrb1.name = new string(yytext);  return O_SB;}
"]"           {  yylval.attrb1.name = new string(yytext);  return C_SB;}
"("           {  yylval.attrb1.name = new string(yytext);  return OP;}
")"           {  yylval.attrb1.name = new string(yytext);  return CP;}
"{"           {  yylval.attrb1.name = new string(yytext);  return O_CURLY;}
"}"           {  yylval.attrb1.name = new string(yytext);  return C_CURLY;}

"."           {  yylval.attrb1.name = new string(yytext);  return DOT;}
";"           {  yylval.attrb1.name = new string(yytext);  return SEMI;}
":"           {  yylval.attrb1.name = new string(yytext);  return COLON;}

"for"         {  yylval.attrb1.name = new string(yytext);  return FOR;}
"while"       {  yylval.attrb1.name = new string(yytext);  return WHILE;}

"if"          {  yylval.attrb1.name = new string(yytext);  return IF;}
"else"        {  yylval.attrb1.name = new string(yytext);  return ELSE;}

"switch"      {  yylval.attrb1.name = new string(yytext);  return SWITCH;}
"case"        {  yylval.attrb1.name = new string(yytext);  return CASE;}
"default"	  {  yylval.attrb1.name = new string(yytext);  return DEFAULT;}

"printf"      {  yylval.attrb1.name = new string(yytext);  return PRINTF;}
"scanf"       {  yylval.attrb1.name = new string(yytext);  return SCANF;}

{IComma}      {  yylval.attrb1.name = new string(yytext);  return DQ;}

{int_const}       				{  yylval.attrb1.name = new string(yytext);  return INT_LIT; }
{int_const}\.{int_const}    	{  yylval.attrb1.name = new string(yytext);  return FLOAT_LIT; }
\<{alphanum}+\.{alphanum}+\>   	{  yylval.attrb1.name = new string(yytext);  return HEADER;}
{alphanum}        				{  yylval.attrb1.name = new string(yytext);  return STR; }

[ \t]*        {}
[\n]          {}
  
[$]           { return EF;}

%%

