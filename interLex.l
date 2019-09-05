%option noyywrap

int_const       [0-9]+
label           [L]
alphanum        [a-zA-Z0-9_]+
IComma            [\'\"]


%%

"<="          {  yyval.name =  new string(yytext); return LT_EQ;}
">="          {  yyval.name =  new string(yytext); return GT_EQ;}
"<"           {  yyval.name =  new string(yytext); return LT;}
"!="          {  yyval.name =  new string("!="); return NOT_EQ;}
">"           {  yyval.name =  new string(yytext); return GT;}
"=="          {  yyval.name =  new string(yytext); return EQ_EQ;}


"+"           {  yyval.name =  new string(yytext); return PLUS;}
"-"           {  yyval.name =  new string(yytext); return MINUS;}
"*"           {  yyval.name =  new string(yytext); return MULTI;}
"/"           {  yyval.name =  new string(yytext); return DIV;}
"^"           {  yyval.name =  new string(yytext); return POW;}

"&&"          {  yyval.name =  new string(yytext); return AND;}
"||"          {  yyval.name =  new string(yytext); return OR;}
"!"			  {  yyval.name =  new string(yytext); 
                 return NOT;}

"="           {  yyval.name =  new string(yytext); return ASSIGN;}
","           {  yyval.name =  new string(yytext); return COMMA;}

"."           {  yyval.name =  new string(yytext); return DOT;}
":"           {  yyval.name =  new string(yytext); return COLON;}

"if"          {  yyval.name =  new string(yytext); return IF;}
"goto"        {  yyval.name =  new string(yytext); return GOTO;}
"call"        {  yyval.name =  new string(yytext); return CALL;}
"param"       {  yyval.name =  new string(yytext); return PARAM;}
"refparam"    {  yyval.name =  new string(yytext); return REFPARAM;}
"func begin"  {  yyval.name =  new string(yytext); return FUNC_BEGIN;}
"func end"    {  yyval.name =  new string(yytext); return FUNC_END;}
"end"         {  yyval.name =  new string(yytext); return END;}
"BeginFunc"   {  yyval.name =  new string(yytext); return BEGIN_FUNC;}

{label}{int_const}      {  yyval.name =  new string(yytext); return LABEL;}

{IComma}      {  yyval.name =  new string(yytext); return DQ;}

{int_const}       				{  yyval.integer =  new string(yytext); return INT_LIT; }
{int_const}\.{int_const}    	{  yyval.integer =  new string(yytext); return FLOAT_LIT; }
{alphanum}        				{  yyval.name =  new string(yytext); return STR; }

[ \t]*        {}
[\n]          { return NEWLINE;}
  
[$]           {  return EF;}
%%

