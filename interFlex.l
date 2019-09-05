%option noyywrap
%x COMMENT_SINGLE
%x COMMENT_MULTI

%top{
#include "interHeader.h"
#include "interBison.tab.h"
}

int_const       [0-9]+
label           [L]
label2          "CONDITION"
alphanum        [a-zA-Z0-9_]+
IComma          [\'\"]


%%

"<="          { yylval.name =  new string(yytext); return LT_EQ;}
">="          { return GT_EQ;}
"<"           { return LT;}
">"           { yylval.name =  new string(yytext); return GT;}
"=="          { return EQ_EQ;}
"!="          { return NOT_EQ;}

"+"           { return PLUS;}
"-"           { return MINUS;}
"*"           { return MULTI;}
"/"           { return DIV;}
"^"           { return POW;}

"&&"          { return AND;}
"||"          { return OR;}
"!"			  { return NOT;}

"="           { yylval.name =  new string(yytext); return EQUAL;}
","           { return COMMA;}

"."           { return DOT;}
":"           { return COLON;}

"if"          { return IF;}
"goto"        { return GOTO;}
"call"        { return CALL;}
"param"       { return PARAM;}
"refparam"    { return REFPARAM;}
"func begin"  { return FUNC_BEGIN;}
"func end"    { return FUNC_END;}
"end"         { return END;}
"BeginFunc"   { return BEGIN_FUNC;}
"return"      { return RETURN;}


"convertToFloat"        {  return CNVRTFLOAT; }
"convertToInt"         {  return CNVRTINT; }
{label2}{int_const}     { yylval.name =  new string(yytext); return LABEL;}   
{label}{int_const}      { yylval.name =  new string(yytext); return LABEL;}

{IComma}      { return DQ;}

{int_const}       				{ yylval.name =  new string(yytext); return INT_LIT; }
{int_const}\.{int_const}    	{ yylval.name =  new string(yytext); return FLOAT_LIT; }
{alphanum}        				{ yylval.name =  new string(yytext); return STR; }

[ \t]*        {}
[\n]          { return NEWLINE;}
  
[$]           { return EF;}

%%

