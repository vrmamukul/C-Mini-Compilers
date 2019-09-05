%{
#pragma GCC diagnostic ignored "-Wwrite-strings"
	
	#include "header.h"
	using namespace std;
	extern int yylex();
	extern int yylineno;
	extern char* yytext;
	extern FILE* yyout;
	int yyerror(char *s);
	vector<int>tempNames(8,0);
	vector<int>floatNames(32,0);
	vector<struct varSymbolTableEntry*>globalTableEntry;
	vector<struct fnNameTableEntry*>globalFuncTable; 
	vector<int>typeList;
	int scope=0;
	int activeFuncPtr = 0;
	int callNamePtr = -1;
	bool error=false;
	int paramPos = 0;
	int passedParam = 0;
	bool funcRedecFlag = false;
	string redecFuncName;
	bool returnFlag = false;
	int nextQuad = 0;
	vector<string> interCode;
	vector<string> delay;
	vector<string> delaySwitch;
	vector<string> delayFree;
	int tempCount = 0;
	int condCount = 1;
	int nextCount = 1;
	int tempStart = 0;
	int fncQuad=0;
	int AND_OR = 0;
	string arrName;
	string arrNameAssign;
	vector<int> arrDim;
	vector<string> array1(1000);
	int cntr=0;
	int shift=0;
	int prod = 1;
	int pro = 1;
	int scopevar = 0;
	vector<int>scopeList(100);
	vector<string> arrAssignDim;
	int foundPos;
	int arrFlag = 0;
	vector<int> arrAssignDimValue;
	vector<string> toFree;
	int toFreeFlag = 0;
	int assignFun = 0;
	string currType1;
	string idType;
	int assFlag = 0;
	string idName;
	int arrAssFlag = 0;
%}

%union{
	struct falseListStruct falseList;
	struct attrb1Struct attrb1;
	int intType;
	float floatType;
	int quad; 
}


%start  code

%token <attrb1> INT_LIT
%token <attrb1> FLOAT_LIT
%token <attrb1> STR DEFAULT

%token <attrb1>  LT_EQ GT_EQ LT GT EQ_EQ NOT_EQ PLUS MINUS MULTI DIV POW AMP HASH HEADER RETURN BREAK CONTINUE AND OR NOT ASSIGN COMMA O_SB C_SB CP OP O_CURLY C_CURLY DOT SEMI COLON FOR WHILE IF ELSE SWITCH CASE PRINTF SCANF DQ  EF INT FLOAT INCR DECR PLUS_ASS MINUS_ASS MULT_ASS DIV_ASS

%type <attrb1> VAR_DEC  DEC DTYPE DIMLIST DIMLIST_1 EXP TERM ELIST EXP1 VAL_LIST Z CURLY_CLS ARR
%type <attrb1>LEFT ID  ASS  IFELSE-STAT  WHILE-STAT  EXP_LIST EXP_LI FOR-STAT  FUNC_DECL FUNC_HEAD DECL_PLIST DECL_PARAM RES_ID DECL_PL FUNC_DEF PLIST PARAMLIST  SWITCH_STMT    INC_DEC FUNC_CALL
%type <attrb1> VARLIST ID_ARR ASS_OP stmt stmtList VAL1 VALUE_LIST
%type <quad> M
%type <falseList> WHILE_EXP IFELSE FOR_EXP  SWITCH_HEAD CASE_STMT CASE_LIST DEF_STMT

%nonassoc IFX
%nonassoc ELSE
%right ASSIGN
%left OR
%left AND
%left LT GT LT_EQ GT_EQ EQ_EQ NOT_EQ
%left PLUS MINUS
%left DIV MULTI
%nonassoc UMINUS
%right NOT  
%left PLUS_ASS MINUS_ASS

%%

code:		stmtList 		{
								int mainFlag = 0;
								for(int i=0;i<globalFuncTable.size();i++){
									if(globalFuncTable[i]->name == "main"){
										mainFlag = 1;
										break;
									}
								}
								if(mainFlag == 0){
									cout<<"Main Function Missing in the Code"<<endl;
								}
								string temp = "end";
								genCode(temp);
							}
			;

stmtList:	/*empty*/
			| stmt stmtList {  	
								$$.breakList = catinateList($1.breakList,$2.breakList);
								$$.continueList = catinateList($1.continueList,$2.continueList);	 
							}		
			;

stmt:		HASH HEADER 				{ }
			| VAR_DEC SEMI      		{ }
			| ASS SEMI 	  				{ 
											if(delay.size()!=0){
												for(int i=0;i<delay.size();i++){
													genCode(delay[i]);
												}
												delay.clear();
											}
											
										}

			| IFELSE-STAT   			{ 
											
											$$.breakList = $1.breakList;
											$$.continueList = $1.continueList;
										}
			| WHILE-STAT				{ 
											
												
										}
			| FOR-STAT					{}
			| FUNC_DECL	SEMI			{ 
											if(funcRedecFlag==1){
												cout<<"ReDeclaration of function "<<redecFuncName<<endl;
												error=1;
												funcRedecFlag=0;
												redecFuncName.clear();
											}
											
										}

			| FUNC_DEF					{ }
			| SWITCH_STMT				{ }
			| O_CURLY  { scope++;}  stmtList C_CURLY	{ 	
															scope--;
															$$.breakList = $3.breakList;
															$$.continueList = $3.continueList;	
														}

			| BREAK SEMI 				{ 
											
											$$.breakList = new vector<int>();
											(*$$.breakList).push_back(nextQuad);
											string temp = "goto ";
											
											genCode(temp); 
										}
			| CONTINUE SEMI				{ 
											
											$$.continueList = new vector<int>();
											(*$$.continueList).push_back(nextQuad);
											string temp = "goto ";
											genCode(temp); 	
										}
			| RETURN EXP SEMI			{ 
				 							returnFlag = true; 
											string temp = "return "+ $2.name[0];
											genCode(temp);
											if($2.name[0][0]=='_'){
												freeTemp($2.name[0]);
											}
										}
			| SEMI						{ }
			| error SEMI   				{ cout<<"Syntax Error ! Line :"<<yylineno<<endl; error = 1;}
			;


/******************************************* VARIABLE DECLARATION **************************************************/


VAR_DEC:   DEC  							
			;

DEC : 		DTYPE VARLIST		
										{ 	
											if($2.type!=NULL && $2.type[0]=="errorType"){
												if($$.type==NULL) $$.type = new string("errorType");
												else $$.type[0] = "errorType";
											}
											else{
												patchtype($1.type,typeList,activeFuncPtr); 
												typeList.clear();
												for(int i=0;i<delay.size();i++){
													if($1.type[0] == "int" && delaySwitch[i]=="float"){
														int newTemp = getTemp();
													
														string temp = "convertToInt " + delayFree[i] + ", _t" + to_string(newTemp);
														genCode(temp);
														if(delayFree[i][0]=='_'){
															freeFloat(delayFree[i]);
														}
														delayFree[i].clear();
														delayFree[i]= "_t" + to_string(newTemp);
														delay[i] += delayFree[i];
														freeTemp(delayFree[i]);
														genCode(delay[i]);
													}
													else if($1.type[0] == "float" && delaySwitch[i]=="int"){
														int newTemp = float();
														string temp = "convertToFloat " + delayFree[i] + ", _f" + to_string(newTemp);
														genCode(temp);
														if(delayFree[i][0]=='_'){
															freeTemp(delayFree[i]);
														}
														delayFree[i].clear();
														delayFree[i]= "_f" + to_string(newTemp);
														delay[i] += delayFree[i];
														freeFloat(delayFree[i]);
														genCode(delay[i]);
													}
													else{
														delay[i] += delayFree[i];
														genCode(delay[i]);
														if(delayFree[i].substr(0,2)=="_t") freeTemp(delayFree[i]);
														if(delayFree[i].substr(0,2)=="_f") freeFloat(delayFree[i]);
													}
												}
												delayFree.clear();
												delay.clear();
												delaySwitch.clear();
											}
										}
			;

			
DTYPE : 	INT 							{  string temp = "int"; $$.type = new string(temp); currType1 = temp;}
			| FLOAT 						{  string temp = "float"; $$.type = new string(temp); currType1 = temp;}
			;

VARLIST :	ID_ARR 					
			| ID_ARR COMMA VARLIST 			{if($3.type!=NULL && $3.type[0]=="errorType");}
			| ID DIMLIST_1 ASSIGN O_CURLY 
											{	
												if($2.type!=NULL && $2.type[0]=="errorType");
												else{
													int position,index;
													if(searchVar($1.name,activeFuncPtr,scope,position)){
														cout<<"Variable already declared at the same level"<<endl;
														error =	true;

													}
													else if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
														cout<<"Redeclaration of Parameter as Variable"<<endl;
														error =	true;
													}
													else{

														index = insertVarSymTab($1.name,activeFuncPtr,1); 
														typeList.push_back(index);
														arrName = globalFuncTable[activeFuncPtr]->varTable[index]->name+ "_" + to_string(globalFuncTable[activeFuncPtr]->varTable[index]->scope) + "_" + globalFuncTable[activeFuncPtr]->name;
													}
													scopevar = 0;
													scopeList[0]=0;
												}
											}

				VAL_LIST					{	
												if(($2.type!=NULL && $2.type[0]=="errorType") || ($6.type!=NULL && $6.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													if(error==1){
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
													}
													int position;
													searchVar($1.name,activeFuncPtr,scope,position);
													if( (*($2.dimList))[0] == 0 ) (*($2.dimList))[0] = (*($6.dimList))[0] ;
													globalFuncTable[activeFuncPtr]->varTable[position]->dimListPtr = (*$2.dimList);
												}
											}

			| ID ASSIGN EXP COMMA VARLIST   { 	
												if(($3.type!=NULL && $3.type[0]=="errorType") || ($5.type!=NULL && $5.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													int position;
													if(searchVar($1.name,activeFuncPtr,scope,position)){
														cout<<"Variable already declared at the same level"<<endl;
														error =	true;
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
													}
													else if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
														cout<<"Redeclaration of Parameter as Variable"<<endl;
														error =	true;
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
													}
													else{
														if($3.returnQuad == -1){
															string funName = globalFuncTable[assignFun]->name;
															string typeFun = $3.type[0];
															string var_name = $3.name[0];
															string ass11 = $1.name[0] + "_" + to_string(scope) + "_" + globalFuncTable[activeFuncPtr]->name;
															string assgn = ass11 + " = " + var_name;
															genCode(assgn);
															int index = insertVarSymTab($1.name,activeFuncPtr,0); 
															typeList.push_back(index);
															if($3.name[0][1] == 'f')freeFloat($3.name[0]);
															if($3.name[0][1] == 't')freeTemp($3.name[0]);
														}
														else{
															int index = insertVarSymTab($1.name,activeFuncPtr,0); 
															typeList.push_back(index);
															string temp = globalFuncTable[activeFuncPtr]->varTable[index]->name+ "_" + to_string(globalFuncTable[activeFuncPtr]->varTable[index]->scope) + "_" + globalFuncTable[activeFuncPtr]->name + " = ";
															delaySwitch.push_back($3.type[0]);
															delay.push_back(temp);
															delayFree.push_back($3.name[0]);
														}
													}
												}
											}
			
			| ID ASSIGN EXP 				{ 
												if(($3.type!=NULL && $3.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													int position;
													if(searchVar($1.name,activeFuncPtr,scope,position)){
														cout<<"Variable already declared at the same level"<<endl;
														error =	true;
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
													}
													/*makelist*/
													else if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
														cout<<"Redeclaration of Parameter as Variable"<<endl;
														error =	true;
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
													}
													else{
														if($3.returnQuad == -1){
															string funName = globalFuncTable[assignFun]->name;
															string var_name = $3.name[0];
															string typeFun = $3.type[0];
															if(currType1 == typeFun){
																string ass11 = $1.name[0] + "_" + to_string(scope) + "_" + globalFuncTable[activeFuncPtr]->name;
																string assgn = ass11 + " = " + var_name;
																genCode(assgn);
															}
															if($3.name[0][1] == 'f')freeFloat($3.name[0]);
															if($3.name[0][1] == 't')freeTemp($3.name[0]);
															int index = insertVarSymTab($1.name,activeFuncPtr,0); 
															typeList.push_back(index);
														}
														else{
															int index = insertVarSymTab($1.name,activeFuncPtr,0); 
															typeList.push_back(index);
															string temp = globalFuncTable[activeFuncPtr]->varTable[index]->name+ "_" + to_string(globalFuncTable[activeFuncPtr]->varTable[index]->scope) + "_" + globalFuncTable[activeFuncPtr]->name + " = ";
															delaySwitch.push_back($3.type[0]);
															delay.push_back(temp);
															delayFree.push_back($3.name[0]);
														}
													}
												}
											}
			;

VAL_LIST : 	VALUE_LIST C_CURLY 				{	
												if($1.type!=NULL && $1.type[0]=="errorType");
												else{
													if(arrDim[0]==0) arrDim[0]=scopeList[0]+1;
													$1.dimList = new vector<int>();
													for(int i=0; i<arrDim.size(); i++){
														(*$1.dimList).push_back(arrDim[i]);
													}
													arrDim.clear();
													arrName = "";
												}												
											}
			COMMA VARLIST					{
												if(($1.type!=NULL && $1.type[0]=="errorType") || ($5.type!=NULL && $5.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													$$.dimList = $1.dimList;
												}
											}
											

			| VALUE_LIST C_CURLY  			{
												if($1.type!=NULL && $1.type[0]=="errorType"){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													if(arrDim[0]==0) arrDim[0]=scopeList[0]+1;
													$$.dimList = new vector<int>();
													for(int i=0; i<arrDim.size(); i++){
														(*$$.dimList).push_back(arrDim[i]);
													}
													arrDim.clear();
													arrName = "";	
												}											
											}
			;


ID_ARR :    ID  							{ 	
												int position;
												if(searchVar($1.name,activeFuncPtr,scope,position)){
													cout<<"Variable already declared at the same level"<<endl;
													error =	true;
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												/*makelist*/
												else if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
													cout<<"Redeclaration of Parameter as Variable"<<endl;
													error =	true;
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													int index = insertVarSymTab($1.name,activeFuncPtr,0); typeList.push_back(index);
												}

											}

			| ID DIMLIST 					{
												if(($2.type!=NULL && $2.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													int position;
													if(searchVar($1.name,activeFuncPtr,scope,position)){
														cout<<"Variable already declared at the same level"<<endl;
														error =	true;
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
													}
													/*makelist*/
													else if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
														cout<<"Redeclaration of Parameter as Variable"<<endl;
														error =	true;
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
													}
													else{
														int index = insertVarSymTab($1.name,activeFuncPtr,1); typeList.push_back(index);
														globalFuncTable[activeFuncPtr]->varTable[index]->dimListPtr = (*$2.dimList);
													}
												}
											}
			;

ID : 		STR 							{
												$$.name = $1.name; 
												if(idSearch($1.name[0])==1) 
												{
													cout<<"Keyword error"<<endl;
													error = 1;
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												
											}
			;

DIMLIST :   O_SB INT_LIT C_SB				{
												$$.dimList = new vector<int>();
												(*$$.dimList).push_back(stoi($2.name[0]));
												arrDim.push_back(stoi($2.name[0]));
											}
			| O_SB INT_LIT C_SB DIMLIST		{
												if(($4.type!=NULL && $4.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													(*$4.dimList).insert((*$4.dimList).begin(),stoi($2.name[0]));
													$$.dimList = $4.dimList;
													arrDim.insert(arrDim.begin(),stoi($2.name[0]));
												}
											}
			;

DIMLIST_1 : O_SB C_SB						{
												$$.dimList = new vector<int>();
												(*$$.dimList).push_back(0);
												arrDim.push_back(0);
											}
			| O_SB C_SB DIMLIST				{
												if(($3.type!=NULL && $3.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													arrDim.insert(arrDim.begin(),0);
													$$.dimList = $3.dimList;
													(*$$.dimList).insert((*$$.dimList).begin(), 0) ;
												}
											}
			| DIMLIST						{
												if(($1.type!=NULL && $1.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													$$.dimList = $1.dimList;
												}
											}
			;

VALUE_LIST : TERM 				{	
									if(($1.type!=NULL && $1.type[0]=="errorType")){
										if($$.type==NULL) $$.type = new string("errorType");
										else $$.type[0] = "errorType";
									}
									else{
										int pos = getTemp();
										string temp = "_t" + to_string(pos) + " = " + to_string(shift+cntr);
										genCode(temp);
										string temp1 = arrName + "." + "_t" + to_string(pos) + ". = " + $1.name[0];
										genCode(temp1);

										freeTemp("_t" + to_string(pos));
										if($1.name[0][0]=='_') freeTemp($1.name[0]);
									}
								}

			| TERM COMMA        { 	
									if(($1.type!=NULL && $1.type[0]=="errorType"));
									else{
										if(scopevar==0) scopeList[scopevar]++;
										int pos = getTemp();
										string temp = "_t" + to_string(pos) + " = " + to_string(shift+cntr);
										genCode(temp);
										string temp1 = arrName + "." + "_t" + to_string(pos) + ". = " + $1.name[0];
										genCode(temp1);

										freeTemp("_t" + to_string(pos));
	                                    // array1[shift+cntr] = $1.name[0];
										cntr++;
	                                    if($1.name[0][0]=='_') freeTemp($1.name[0]); 

										if(arrDim[arrDim.size()-1] != 0){
											if(cntr >= arrDim[arrDim.size()-1]){
												cout<<"ERROR TERM due to overflow in index at scope "<<scopevar<<endl;
												error = 1;
											}
										}
									}
                                } 

            VALUE_LIST   		{	
            						if(($1.type!=NULL && $1.type[0]=="errorType") || ($4.type!=NULL && $4.type[0]=="errorType")){
										if($$.type==NULL) $$.type = new string("errorType");
										else $$.type[0] = "errorType";
									}
									else{
	            						if(error==1){
	            							if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
	            						}
	                                    cntr--;
	                                }
                                }
			| O_CURLY 
				{
					scopevar++; scopeList[scopevar]=0; cntr=0;
				}  
				Z  
					{
						if(($3.type!=NULL && $3.type[0]=="errorType")){
							if($$.type==NULL) $$.type = new string("errorType");
							else $$.type[0] = "errorType";
						}						
					}
            ;

Z 			: VALUE_LIST 
						{
							if(($1.type!=NULL && $1.type[0]=="errorType"));
							else{
								scopeList[scopevar]=0; 
								scopevar--; 
								cntr=0;
							}
						} 
				CURLY_CLS 
							{
								if(($1.type!=NULL && $1.type[0]=="errorType")){
									if($$.type==NULL) $$.type = new string("errorType");
									else $$.type[0] = "errorType";
								}					
							}
			;


CURLY_CLS 	: C_CURLY 
			|  C_CURLY COMMA 
							{  	
								scopeList[scopevar]++;
								prod=1;
								for(int i = scopevar+1; i<arrDim.size(); i++){
									prod = prod * arrDim[i];
								}
								shift += prod;
								if(arrDim[scopevar] != 0){
									if(scopeList[scopevar] >= arrDim[scopevar]){
											cout<<"ERROR COMMA due to overflow in index at scope "<<scopevar<<endl;
											error = 1;
									}
								}

							}
				VALUE_LIST  {	
								if(($4.type!=NULL && $4.type[0]=="errorType")){
									if($$.type==NULL) $$.type = new string("errorType");
									else $$.type[0] = "errorType";
								}
								else{
									if(error==1){
										if($$.type==NULL) $$.type = new string("errorType");
										else $$.type[0] = "errorType";
									}
									pro=1;
									for(int i = scopevar+1; i<arrDim.size(); i++){
										pro = pro * arrDim[i];
									}
									shift -= pro;	
								}							
							}	
			;


/***************************************************EXPRESSION**********************************************************/

EXP: 		EXP PLUS EXP 			{	
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											int pos;
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
													pos = getTemp();
												}
												else if($1.type[0]=="float" && $3.type[0]=="float"){
													$$.type = new string("float");
													pos = getFloat();
												}
												else{
													$$.type = new string("float");
													if($1.type[0]=="float"){
														int newFloat = getFloat();
														string temp = "convertToFloat " + $3.name[0] + " , _f" + to_string(newFloat);
														genCode(temp);
														if($3.name[0][0]=='_') freeTemp($3.name[0]);
														$3.name[0].clear();
														$3.name[0] =  "_f" + to_string(newFloat);
													}
													else{
														int newFloat = getFloat();
														string temp = "convertToFloat "+ $1.name[0] + " , _f" + to_string(newFloat);
														genCode(temp);
														freeTemp($1.name[0]);
														$1.name[0].clear();
														$1.name[0] =  "_f" + to_string(newFloat);
													}
													pos = getFloat();
												}
												string temp;
												if($$.type[0]=="int"){
													temp = "_t" + to_string(pos) + " = " + $1.name[0] + $2.name[0] + $3.name[0];
													$$.name = new string("_t"+to_string(pos));
												}
												else{
													temp = "_f" + to_string(pos) + " = " + $1.name[0] + $2.name[0] + $3.name[0];
													$$.name = new string("_f"+to_string(pos));
												}
												genCode(temp);
												if($1.name[0].substr(0,2)=="_t") freeTemp($1.name[0]);
												if($3.name[0].substr(0,2)=="_t") freeTemp($3.name[0]);
												if($1.name[0].substr(0,2)=="_f") freeFloat($1.name[0]);
												if($3.name[0].substr(0,2)=="_f") freeFloat($3.name[0]);
											}
										}								
									}
									
			
			| EXP MINUS EXP 		{
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{	
											int pos;
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
													pos = getTemp();
												}
												else if($1.type[0]=="float" && $3.type[0]=="float"){
													$$.type = new string("float");
													pos = getFloat();
												}
												else{
													$$.type = new string("float");
													if($1.type[0]=="float"){
														int newFloat = getFloat();
														string temp = "convertToFloat " + $3.name[0] + " , _f" + to_string(newFloat);
														genCode(temp);
														if($3.name[0][0]=='_') freeTemp($3.name[0]);
														$3.name[0].clear();
														$3.name[0] =  "_f" + to_string(newFloat);
													}
													else{
														int newFloat = getFloat();
														string temp = "convertToFloat "+ $1.name[0] + " , _f" + to_string(newFloat);
														genCode(temp);
														freeTemp($1.name[0]);
														$1.name[0].clear();
														$1.name[0] =  "_f" + to_string(newFloat);
													}
													pos = getFloat();
												}
												string temp;
												if($$.type[0]=="int"){
													temp = "_t" + to_string(pos) + " = " + $1.name[0] + $2.name[0] + $3.name[0];
													$$.name = new string("_t"+to_string(pos));
												}
												else{
													temp = "_f" + to_string(pos) + " = " + $1.name[0] + $2.name[0] + $3.name[0];
													$$.name = new string("_f"+to_string(pos));
												}
												genCode(temp);
												if($1.name[0].substr(0,2)=="_t") freeTemp($1.name[0]);
												if($3.name[0].substr(0,2)=="_t") freeTemp($3.name[0]);
												if($1.name[0].substr(0,2)=="_f") freeFloat($1.name[0]);
												if($3.name[0].substr(0,2)=="_f") freeFloat($3.name[0]);
											}	
										}							
									}
			
			| MINUS EXP 	 		{	
										int pos;
										$$.type = new string($2.type[0]);
										if($2.type[0]!="errorType"){
											string temp;
											if($$.type[0]=="int"){
												int tmp1 = getTemp(), tmp2 = getTemp();
												temp = "_t" + to_string(tmp1) + " = -1";
												genCode(temp);
												temp = "_t" + to_string(tmp2) + " = " + "_t" + to_string(tmp1) + " * "+ $2.name[0];
												freeTemp("_t"+to_string(tmp1));
												$$.name = new string("_t"+to_string(tmp2));
											}
											else{
												int tmp1 = getFloat(), tmp2 = getFloat();
												temp = "_f" + to_string(tmp1) + " = -1";
												genCode(temp);
												temp = "_f" + to_string(tmp2) + " = " + "_f" + to_string(tmp1) + " * "+ $2.name[0];
												freeFloat("_f"+to_string(tmp1));
												$$.name = new string("_f"+to_string(tmp2));
											}
											genCode(temp);
										}								
									}
			
			
			| EXP MULTI EXP 		{	
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											int pos;
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
													pos = getTemp();
												}
												else if($1.type[0]=="float" && $3.type[0]=="float"){
													$$.type = new string("float");
													pos = getFloat();
												}
												else{
													$$.type = new string("float");
													if($1.type[0]=="float"){
														int newFloat = getFloat();
														string temp = "convertToFloat " + $3.name[0] + " , _f" + to_string(newFloat);
														genCode(temp);
														if($3.name[0][0]=='_') freeTemp($3.name[0]);
														$3.name[0].clear();
														$3.name[0] =  "_f" + to_string(newFloat);
													}
													else{
														int newFloat = getFloat();
														string temp = "convertToFloat "+ $1.name[0] + " , _f" + to_string(newFloat);
														genCode(temp);
														freeTemp($1.name[0]);
														$1.name[0].clear();
														$1.name[0] =  "_f" + to_string(newFloat);
													}
													pos = getFloat();
												}
												string temp;
												if($$.type[0]=="int"){
													temp = "_t" + to_string(pos) + " = " + $1.name[0] + $2.name[0] + $3.name[0];
													$$.name = new string("_t"+to_string(pos));
												}
												else{
													temp = "_f" + to_string(pos) + " = " + $1.name[0] + $2.name[0] + $3.name[0];
													$$.name = new string("_f"+to_string(pos));
												}
												genCode(temp);
												if($1.name[0].substr(0,2)=="_t") freeTemp($1.name[0]);
												if($3.name[0].substr(0,2)=="_t") freeTemp($3.name[0]);
												if($1.name[0].substr(0,2)=="_f") freeFloat($1.name[0]);
												if($3.name[0].substr(0,2)=="_f") freeFloat($3.name[0]);
											}	
										}							
									}
			
			| EXP DIV EXP 			{	
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											int pos;
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
													pos = getTemp();
												}
												else if($1.type[0]=="float" && $3.type[0]=="float"){
													$$.type = new string("float");
													pos = getFloat();
												}
												else{
													$$.type = new string("float");
													if($1.type[0]=="float"){
														int newFloat = getFloat();
														string temp = "convertToFloat " + $3.name[0] + " , _f" + to_string(newFloat);
														genCode(temp);
														if($3.name[0][0]=='_') freeTemp($3.name[0]);
														$3.name[0].clear();
														$3.name[0] =  "_f" + to_string(newFloat);
													}
													else{
														int newFloat = getFloat();
														string temp = "convertToFloat "+ $1.name[0] + " , _f" + to_string(newFloat);
														genCode(temp);
														freeTemp($1.name[0]);
														$1.name[0].clear();
														$1.name[0] =  "_f" + to_string(newFloat);
													}
													pos = getFloat();
												}
												string temp;
												if($$.type[0]=="int"){
													temp = "_t" + to_string(pos) + " = " + $1.name[0] + $2.name[0] + $3.name[0];
													$$.name = new string("_t"+to_string(pos));
												}
												else{
													temp = "_f" + to_string(pos) + " = " + $1.name[0] + $2.name[0] + $3.name[0];
													$$.name = new string("_f"+to_string(pos));
												}
												genCode(temp);
												if($1.name[0].substr(0,2)=="_t") freeTemp($1.name[0]);
												if($3.name[0].substr(0,2)=="_t") freeTemp($3.name[0]);
												if($1.name[0].substr(0,2)=="_f") freeFloat($1.name[0]);
												if($3.name[0].substr(0,2)=="_f") freeFloat($3.name[0]);
											}		
										}						
									}
			
			| EXP AND M {
							if(($1.type!=NULL && $1.type[0]=="errorType"));
							else{
								AND_OR = 1;
								string temp = "if " + $1.name[0] + "<= 0 goto ";	
								genCode(temp);
								string temp1 = "L" + to_string(nextQuad) + " : ";	
								genCode(temp1);
								if($1.shortFalseList == NULL){
									$1.shortFalseList = new vector <int>();
								}
								(*$1.shortFalseList).push_back($3);
							}
						}
				EXP 			
						{	
							if(($1.type!=NULL && $1.type[0]=="errorType") || ($5.type!=NULL && $5.type[0]=="errorType")){
								if($$.type==NULL) $$.type = new string("errorType");
								else $$.type[0] = "errorType";
							}
							else{
								if($1.type[0]=="errorType" || $5.type[0]=="errorType")
									$$.type = new string("errorType");
								else{ 
									if($1.type[0]=="int" && $5.type[0]=="int"){
										$$.type = new string("int");
									}
									else
										$$.type = new string("float");
									$$.shortFalseList = catinateList($1.shortFalseList,$5.shortFalseList);
									if($1.shortTrueList != NULL){
										backPatch($1.shortTrueList,$3);
									}
									$$.shortTrueList = $5.shortTrueList; 	
									$$.name = $5.name ;
									if($1.name[0][0]=='_') freeTemp($1.name[0]);
								}		
							}						
						}
					
			| EXP OR M {
							if(($1.type!=NULL && $1.type[0]=="errorType"));
							else{
								AND_OR = 1;
								string temp = "if " + $1.name[0] + "> 0 goto ";	
								genCode(temp);
								string temp1 = "L" + to_string(nextQuad) + " : ";	
								genCode(temp1);
								if($1.shortTrueList == NULL){
									$1.shortTrueList = new vector <int>();
								}
								(*$1.shortTrueList).push_back($3);
							}
						}
				EXP 			
						{	
							if(($1.type!=NULL && $1.type[0]=="errorType") || ($5.type!=NULL && $5.type[0]=="errorType")){
								if($$.type==NULL) $$.type = new string("errorType");
								else $$.type[0] = "errorType";
							}
							else{
								if($1.type[0]=="errorType" || $5.type[0]=="errorType")
									$$.type = new string("errorType");
								else{ 
									if($1.type[0]=="int" && $5.type[0]=="int"){
										$$.type = new string("int");
									}
									else
										$$.type = new string("float");

									$$.shortTrueList = catinateList($1.shortTrueList,$5.shortTrueList);
									if($1.shortFalseList != NULL){
										backPatch($1.shortFalseList,$3+1);
									}

									$$.shortFalseList = $5.shortFalseList; 	

									$$.name = $5.name ;
									if($1.name[0][0]=='_') freeTemp($1.name[0]);
									
								}
							}
						}

			| EXP LT EXP 			{
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{	
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
												}
												else
													$$.type = new string("float");
												int pos = getTemp();

												string temp0 = "if " + $1.name[0] + " >= " + $3.name[0] + " goto L" + to_string(nextQuad+4);
												genCode(temp0);
												$$.name = new string("_t"+to_string(pos));
												if($1.name[0][0]=='_') freeTemp($1.name[0]);
												if($3.name[0][0]=='_') freeTemp($3.name[0]);

												string temp1 = "L" + to_string(nextQuad) + " : ";
												genCode(temp1);

												string temp11 = $$.name[0] + " = 1";
												genCode(temp11);

												string temp2 = "goto L" + to_string(nextQuad+3);
												genCode(temp2); 
												
												string temp3 = "L" + to_string(nextQuad) + " : ";
												genCode(temp3);

												string temp33 = $$.name[0] + " = 0";
												genCode(temp33);

												string temp4 = "L" + to_string(nextQuad) + " : ";
												genCode(temp4);		
											}
										}								
									}
			| EXP GT EXP 			{	
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
												}
												else
													$$.type = new string("float");
												int pos = getTemp();

												string temp0 = "if " + $1.name[0] + " <= " + $3.name[0] + " goto L" + to_string(nextQuad+4);
												genCode(temp0);
												$$.name = new string("_t"+to_string(pos));
												if($1.name[0][0]=='_') freeTemp($1.name[0]);
												if($3.name[0][0]=='_') freeTemp($3.name[0]);

												string temp1 = "L" + to_string(nextQuad) + " : ";
												genCode(temp1);

												string temp11 = $$.name[0] + " = 1";
												genCode(temp11);

												string temp2 = "goto L" + to_string(nextQuad+3);
												genCode(temp2); 
					
												string temp3 = "L" + to_string(nextQuad) + " : ";
												genCode(temp3);

												string temp33 = $$.name[0] + " = 0";
												genCode(temp33);

												string temp4 = "L" + to_string(nextQuad) + " : ";
												genCode(temp4);			
											}
										}	
									}
			| EXP LT_EQ EXP 		{	
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
												}
												else
													$$.type = new string("float");
												int pos = getTemp();

												string temp0 = "if " + $1.name[0] + " > " + $3.name[0] + " goto L" + to_string(nextQuad+4);
												genCode(temp0);
												$$.name = new string("_t"+to_string(pos));
												if($1.name[0][0]=='_') freeTemp($1.name[0]);
												if($3.name[0][0]=='_') freeTemp($3.name[0]);

												string temp1 = "L" + to_string(nextQuad) + " : ";
												genCode(temp1);

												string temp11 = $$.name[0] + " = 1";
												genCode(temp11);

												string temp2 = "goto L" + to_string(nextQuad+3);
												genCode(temp2); 
					
												string temp3 = "L" + to_string(nextQuad) + " : ";
												genCode(temp3);

												string temp33 = $$.name[0] + " = 0";
												genCode(temp33);

												string temp4 = "L" + to_string(nextQuad) + " : ";
												genCode(temp4);		
											}	
										}							
									}
			| EXP GT_EQ EXP			{	
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
												}
												else
													$$.type = new string("float");
												int pos = getTemp();

												string temp0 = "if " + $1.name[0] + " < " + $3.name[0] + " goto L" + to_string(nextQuad+4);
												genCode(temp0);
												$$.name = new string("_t"+to_string(pos));
												if($1.name[0][0]=='_') freeTemp($1.name[0]);
												if($3.name[0][0]=='_') freeTemp($3.name[0]);

												string temp1 = "L" + to_string(nextQuad) + " : ";
												genCode(temp1);

												string temp11 = $$.name[0] + " = 1";
												genCode(temp11);

												string temp2 = "goto L" + to_string(nextQuad+3);
												genCode(temp2); 
					
												string temp3 = "L" + to_string(nextQuad) + " : ";
												genCode(temp3);

												string temp33 = $$.name[0] + " = 0";
												genCode(temp33);

												string temp4 = "L" + to_string(nextQuad) + " : ";
												genCode(temp4);		
											}	
										}							
									}
									
			| EXP EQ_EQ EXP			{
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{	
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
												}
												else
													$$.type = new string("float");
												int pos = getTemp();

												string temp0 = "if " + $1.name[0] + " != " + $3.name[0] + " goto L" + to_string(nextQuad+4);
												genCode(temp0);
												$$.name = new string("_t"+to_string(pos));
												if($1.name[0][0]=='_') freeTemp($1.name[0]);
												if($3.name[0][0]=='_') freeTemp($3.name[0]);

												string temp1 = "L" + to_string(nextQuad) + " : ";
												genCode(temp1);

												string temp11 = $$.name[0] + " = 1";
												genCode(temp11);

												string temp2 = "goto L" + to_string(nextQuad+3);
												genCode(temp2); 
					
												string temp3 = "L" + to_string(nextQuad) + " : ";
												genCode(temp3);

												string temp33 = $$.name[0] + " = 0";
												genCode(temp33);

												string temp4 = "L" + to_string(nextQuad) + " : ";
												genCode(temp4);		
											}	
										}							
									}
			| EXP NOT_EQ EXP		{	
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											if($1.type[0]=="errorType" || $3.type[0]=="errorType")
												$$.type = new string("errorType");
											else{ 
												if($1.type[0]=="int" && $3.type[0]=="int"){
													$$.type = new string("int");
												}
												else
													$$.type = new string("float");
												int pos = getTemp();

												string temp0 = "if " + $1.name[0] + " == " + $3.name[0] + " goto L" + to_string(nextQuad+4);
												genCode(temp0);
												$$.name = new string("_t"+to_string(pos));
												if($1.name[0][0]=='_') freeTemp($1.name[0]);
												if($3.name[0][0]=='_') freeTemp($3.name[0]);

												string temp1 = "L" + to_string(nextQuad) + " : ";
												genCode(temp1);

												string temp11 = $$.name[0] + " = 1";
												genCode(temp11);

												string temp2 = "goto L" + to_string(nextQuad+3);
												genCode(temp2); 
					
												string temp3 = "L" + to_string(nextQuad) + " : ";
												genCode(temp3);

												string temp33 = $$.name[0] + " = 0";
												genCode(temp33);

												string temp4 = "L" + to_string(nextQuad) + " : ";
												genCode(temp4);		
											}
										}								
									}

			| EXP1					{
										if(($1.type!=NULL && $1.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											if($1.type[0]=="errorType")
												$$.type = new string("errorType");
											else {
												if($1.returnQuad == -1 && assFlag == 1){
													for(int i=0;i<delay.size()-2;i++){
														genCode(delay[i]);
														string tt = delay[i].substr(6);
														if(tt[0]=='_') freeTemp(tt);
													}
													delay.clear();
													string funName = globalFuncTable[assignFun]->name;
													string typeFun = $1.type[0];
													if(idType == typeFun){
														if(idType == "int"){
															int pos = getTemp();
															$1.name[0] = "_t" + to_string(pos);
														}
														else{
															int pos = getFloat();
															$1.name[0] = "_f" + to_string(pos);
														}
														string ref = "refparam " + $1.name[0];
														genCode(ref);
														string ref1 = "call " + funName + ", " + to_string(globalFuncTable[assignFun]->paramTable.size()+1);
														genCode(ref1);
														$1.type[0] = idType;
													}
													else{
														int pos = getTemp();
														int pos2 = getFloat();
														string var = "_t" + to_string(pos);
														string var2 = "_f" + to_string(pos2);
														if(idType == "int"){
															string ref = "refparam " + var2;
															genCode(ref);
															string ref1 = "call " + funName +", "+ to_string(globalFuncTable[assignFun]->paramTable.size()+1);
															genCode(ref1);
															string conv = "convertToInt " + var2 +", " + var;
															genCode(conv);
															$1.name[0] =  var;
															freeFloat(var2);
															$1.type[0] = idType;
														}
														else if(idType == "float"){
															string ref = "refparam " + var;
															genCode(ref);
															string ref1 = "call " + funName +", "+ to_string(globalFuncTable[assignFun]->paramTable.size()+1);
															genCode(ref1);
															string assgn = $1.name[0] + " = " + var2;
															genCode(assgn);
															$1.name[0] =  var2;
															freeTemp(var);
															$1.type[0] = idType;
														}
													}
													$1.returnQuad = 0;
												}

												else if($1.returnQuad == -1 && assFlag == 0){
													for(int i=0;i<delay.size()-2;i++){
														genCode(delay[i]);
														string tt = delay[i].substr(6);
														if(tt[0]=='_') freeTemp(tt);
													}
													delay.clear();
													string funName = globalFuncTable[assignFun]->name;
													string typeFun = $1.type[0];
													if(currType1 == typeFun){
														if(currType1 == "int"){

															int pos = getTemp();
															$1.name[0] = "_t" + to_string(pos);
														}
														else{
															int pos = getFloat();
															$1.name[0] = "_f" + to_string(pos);
														}
														string ref = "refparam " + $1.name[0];
														genCode(ref);
														string ref1 = "call " + funName + ", " + to_string(globalFuncTable[assignFun]->paramTable.size()+1);
														genCode(ref1);
														$1.type[0] = currType1;
													}
													else{
														int pos = getTemp();
														int pos2 = getFloat();
														string var = "_t" + to_string(pos);
														string var2 = "_f" + to_string(pos2);
														if(currType1 == "int"){
															string ref = "refparam " + var2;
															genCode(ref);
															string ref1 = "call " + funName +", "+ to_string(globalFuncTable[assignFun]->paramTable.size()+1);
															genCode(ref1);
															string conv = "convertToInt " + var2 +", " + var;
															genCode(conv);
															$1.name[0] =  var;
															freeFloat(var2);
															$1.type[0] = currType1;
														}
														else if(currType1 == "float"){
															string ref = "refparam " + var;
															genCode(ref);
															string ref1 = "call " + funName +", "+ to_string(globalFuncTable[assignFun]->paramTable.size()+1);
															genCode(ref1);
															string assgn = $1.name[0] + " = " + var2;
															genCode(assgn);
															$1.name[0] =  var2;
															freeTemp(var);
															$1.type[0] = currType1;
														}
													}
													$$.type = $1.type;
													$$.name = $1.name;
													$$.returnQuad = $1.returnQuad;
													$$.shortFalseList = $1.shortFalseList; 
													$$.shortTrueList = $1.shortTrueList;
												}
											}
										}
									}						
			;

EXP1: 		TERM					{ 
										if(($1.type!=NULL && $1.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											$$.type = $1.type;
											$$.name = $1.name;
											$$.returnQuad = $1.returnQuad;
										} 
									}
			| OP EXP CP				
						{ 
							if(($2.type!=NULL && $2.type[0]=="errorType")){
								if($$.type==NULL) $$.type = new string("errorType");
								else $$.type[0] = "errorType";
							}
							else{
								$$.type = $2.type; 
								$$.name = $2.name; 
								$$.returnQuad = $2.returnQuad; 
								$$.shortFalseList = $2.shortFalseList; 
								$$.shortTrueList = $2.shortTrueList;
							}
						}
			| NOT EXP1			{
									if(($2.type!=NULL && $2.type[0]=="errorType")){
										if($$.type==NULL) $$.type = new string("errorType");
										else $$.type[0] = "errorType";
									}
									else{
										 $$.type = $2.type;
										 $$.shortTrueList = $2.shortFalseList;
										 $$.shortFalseList = $2.shortTrueList;

										 string temp0 = "if " + $2.name[0] + " <= 0 goto L" + to_string(nextQuad+4);
										 genCode(temp0);
										 string temp1 = "L" + to_string(nextQuad) + " : ";
										 genCode(temp1);
										 string temp11 =  $2.name[0] + " = 0";
										 genCode(temp11);
										 string temp2 = "goto L" + to_string(nextQuad+3);
										 genCode(temp2);
										 string temp3 = "L" + to_string(nextQuad);
										 genCode(temp3);
										 string temp33 =  $2.name[0] + " = 1";
										 genCode(temp33);
										 string temp4 = "L" + to_string(nextQuad) + " : ";
										 genCode(temp4);

										 $$.name = $2.name;
									}
								}
			;

TERM :		ID 						{
										if(($1.type!=NULL && $1.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											int currScope = scope;
											int position;
											int found = 0;
											if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
												found = 1;
											}
											while(found == 0 && currScope > 0){
												if(searchVar($1.name,activeFuncPtr,currScope,position)){
													found = 2;
													break;
												}
												else{
													currScope--;
												}
											}
											if(found == 0){
													if(searchVar($1.name,0,0,position)){
														
														$$.type = &(globalFuncTable[0]->varTable[position]->type);
														string temp = globalFuncTable[0]->varTable[position]->name + "_0_global";
														$$.name = new string(temp);
	 												}
													else{
														cout<<"Identifier "<<$1.name[0]<<" Not Declared"<<endl;
														$$.type = new string("errorType");
														error = true;
													}
											}
											else{
												if(found==1) {
													$$.type = &(globalFuncTable[activeFuncPtr]->paramTable[position]->type);
														string temp = globalFuncTable[activeFuncPtr]->paramTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
														$$.name = new string(temp);
												}
												else {
													$$.type = &(globalFuncTable[activeFuncPtr]->varTable[position]->type);
													string temp = globalFuncTable[activeFuncPtr]->varTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->varTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
													$$.name = new string(temp);
												}
											}
										}
									}
			
			| INT_LIT				{ 
										if(arrFlag){arrAssignDimValue.push_back(stoi($1.name[0]));} 
										$$.type = new string("int");
										int pos = getTemp();
										string temp = "_t"+to_string(pos) + " = " + $1.name[0];
										genCode(temp);
										$$.name = new string("_t"+to_string(pos)); 
									}			
			| FLOAT_LIT				{ 
										$$.type = new string("float");
										int pos = getFloat();
										string temp = "_f"+to_string(pos) + " = " + $1.name[0];
										genCode(temp);
										$$.name = new string("_f"+to_string(pos));
									}
			| ARR					{
										if($1.type!=NULL && $1.type[0]=="errorType"){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											$$.name = $1.name; $$.type = $1.type;
										}
									}
			| FUNC_CALL 			{ 
										if(($1.type!=NULL && $1.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											$$.type = $1.type; $$.returnQuad = -1; 
										}
									}

			| ID INC_DEC			{	
										if(($1.type!=NULL && $1.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											int currScope = scope;
											int position;
											int found = 0;
											if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
												found = 1;
											}
											while(found == 0 && currScope > 0){
												if(searchVar($1.name,activeFuncPtr,currScope,position)){
													found = 2;
													break;
												}
												else{
													currScope--;
												}
											}
											if(found == 0){
													if(searchVar($1.name,0,0,position)){
														$$.type = &(globalFuncTable[0]->varTable[position]->type);
														string temp = globalFuncTable[0]->varTable[position]->name + "_0_global";
														$$.name = new string(temp);
														string s;
														s.push_back(' ');
														s.push_back($2.name[0][0]);
														s.push_back(' ');
														s.push_back('1');
														string tmp = temp +  " = " + temp + s;
														delay.push_back(tmp);
													}
													else{
														cout<<"Identifier "<<$1.name[0]<<" Not Declared"<<endl;
														$$.type = new string("errorType");
														error = true;
													}
												}
											else{
												if(found==1) {
													$$.type = &(globalFuncTable[activeFuncPtr]->paramTable[position]->type);
													string temp = globalFuncTable[activeFuncPtr]->paramTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
													$$.name = new string(temp);
													string s;
													s.push_back(' ');
													s.push_back($2.name[0][0]);
													s.push_back(' ');
													s.push_back('1');

													string tmp = temp +  " = " + temp + s;
													delay.push_back(tmp);
									
												}
												else {
													$$.type = &(globalFuncTable[activeFuncPtr]->varTable[position]->type);
													string temp = globalFuncTable[activeFuncPtr]->varTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->varTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
													$$.name = new string(temp);
													string s;
													s.push_back(' ');
													s.push_back($2.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
													string tmp = temp +  " = " + temp + s;
													delay.push_back(tmp);
												}
											}
										}
									}
			
			| INC_DEC ID			{	
										if(($2.type!=NULL && $2.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											int currScope = scope;
											int position;
											int found = 0;
											if((scope == 2) && searchParam($2.name,activeFuncPtr,position)){
												found = 1;
											}
											while(found == 0 && currScope > 0){
												if(searchVar($2.name,activeFuncPtr,currScope,position)){
													found = 2;
													break;
												}
												else{
													currScope--;
												}
											}
											if(found == 0){
													if(searchVar($2.name,0,0,position)){
														$$.type = &(globalFuncTable[0]->varTable[position]->type);
														string temp = globalFuncTable[0]->varTable[position]->name + "_0_global";
														$$.name = new string(temp);
														string s;
														s.push_back(' ');
														s.push_back($1.name[0][0]);
														s.push_back(' ');
														s.push_back('1');
														string tmp = temp +  " = " + temp + s;
														genCode(tmp);
														
													}
													else{
														cout<<"Identifier "<<$2.name[0]<<" Not Declared"<<endl;
														$$.type = new string("errorType");
														error = true;
													}
												}
											else{
												if(found==1) {
													$$.type = &(globalFuncTable[activeFuncPtr]->paramTable[position]->type);
													string temp = globalFuncTable[activeFuncPtr]->paramTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
													$$.name = new string(temp);
													string s;
													s.push_back(' ');
													s.push_back($1.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
													string tmp = temp +  " = " + temp + s;
													genCode(tmp);
													
												}
												else {
													$$.type = &(globalFuncTable[activeFuncPtr]->varTable[position]->type);
													string temp = globalFuncTable[activeFuncPtr]->varTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->varTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
													$$.name = new string(temp);
													string s;
													s.push_back(' ');
													s.push_back($1.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
													string tmp = temp +  " = " + temp + s;
													genCode(tmp);
												}
											}
										}
									}		
			;


INC_DEC :	INCR					{ $$.name = $1.name;}
			| DECR					{ $$.name = $1.name;}
			;


ARR : 		ELIST C_SB				{	
										if(($1.type!=NULL && $1.type[0]=="errorType") ){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											vector<int> tempList = globalFuncTable[activeFuncPtr]->varTable[foundPos]->dimListPtr;
											if(tempList.size() != arrAssignDim.size()){
												cout<<"Dimension mismatch"<<endl;
												error = 1;
												if($$.type==NULL) $$.type = new string("errorType");
												else $$.type[0] = "errorType";
											}
											else{
												int errFlag = 0;
												/*for(int i=0;i<tempList.size();i++){
													if(arrAssignDimValue[i] >= tempList[i]){
														cout<<"Dimension Overflow"<<endl;
														errFlag = 1;
														error = 1;
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
														break;
													}
												}*/
												if(errFlag == 0){
													$$.type = $1.type;
													int pos, pos1, pos2, i;
													string  temp, temp1, temp2, temp3;
													pos = getTemp();
													temp = "_t" + to_string(pos);
													temp1 = temp + " = " + arrAssignDim[0];
													genCode(temp1);
													for(i=1;i<tempList.size();i++){
														pos1 = getTemp();
														temp1 = "_t" + to_string(pos1);
														temp2 = temp1 + " = _t" + to_string(pos) + "*" + to_string(tempList[i]);
														genCode(temp2);
														freeTemp("_t" + to_string(pos));
														pos2 = getTemp();
														temp2 = "_t" + to_string(pos2);
														temp3 = temp2 + " = " + "_t" + to_string(pos1) + "+" + arrAssignDim[i];
														genCode(temp3);
														if(arrAssignDim[i-1][0]=='_') freeTemp(arrAssignDim[i-1]);
														freeTemp("_t" + to_string(pos1));
														pos = pos2;
													}
													if(arrAssignDim[i-1][0]=='_') freeTemp(arrAssignDim[i-1]);
													$$.name[0] = arrNameAssign + "._t" + to_string(pos) + ".";
													// cout<<"tyj  "<<$$.name[0]<<endl;
													// freeTemp("_t" + to_string(pos));
													toFree.push_back("_t" + to_string(pos));
												}
											}
											arrNameAssign = "";
											arrAssignDim.clear();
											arrAssignDimValue.clear();
											arrFlag = 0;
										}	
									}
			;

ELIST :		ID O_SB {	
						if(($1.type!=NULL && $1.type[0]=="errorType"));
						else{
							arrFlag = 1; 
						}
					}
			EXP
							{ 	
								if(($1.type!=NULL && $1.type[0]=="errorType") || ($4.type!=NULL && $4.type[0]=="errorType")){
									if($$.type==NULL) $$.type = new string("errorType");
									else $$.type[0] = "errorType";
								}
								else{
									int position;
									int currScope = scope;
									int found = 0;
									if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
										found = 1;
									}
									while(found == 0 && currScope > 0){
										if(searchVar($1.name,activeFuncPtr,currScope,position)){
											found = 2;
											break;
										}
										else{
											currScope--;
										}
									}

									if(found == 0){
										if(searchVar($1.name,0,0,position)){
											if(globalFuncTable[0]->varTable[position]->eleType == 0){
												cout<<"Error : Can't assign to Non-array type"<<endl;
												error = 1;
												if($$.type==NULL) $$.type = new string("errorType");
												else $$.type[0] = "errorType";
											}
											else{
												foundPos = position;
												$$.type = &(globalFuncTable[0]->varTable[position]->type);
												string temp = globalFuncTable[0]->varTable[position]->name + "_0_global";
												arrNameAssign = temp;
												$$.name = new string(temp);
												//cout<<"aaaaaa  "<<$4.name[0]<<endl;
												arrAssignDim.push_back($4.name[0]);
											}
										}
										else{
											cout<<"Identifier "<<$1.name[0]<<" Not Declared"<<endl;
											$$.type = new string("errorType");
											error = true;
										}
									}
									else{
										if(found==1){
										
											if(globalFuncTable[activeFuncPtr]->varTable[position]->eleType == 0){
												cout<<"Error : Can't assign to Non-array type"<<endl;
												error = 1;
												if($$.type==NULL) $$.type = new string("errorType");
												else $$.type[0] = "errorType";
											}
											else{
												$$.type = &(globalFuncTable[activeFuncPtr]->paramTable[position]->type);
												string temp = globalFuncTable[activeFuncPtr]->paramTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
												$$.name = new string(temp);
											}
										}
										else{
											
											if(globalFuncTable[activeFuncPtr]->varTable[position]->eleType == 0){
												cout<<"Error : Can't assign to Non-array type"<<endl;
												error = 1;
												if($$.type==NULL) $$.type = new string("errorType");
												else $$.type[0] = "errorType";
											}
											else{
												foundPos = position;
												$$.type = &(globalFuncTable[activeFuncPtr]->varTable[position]->type);
												string temp = globalFuncTable[activeFuncPtr]->varTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->varTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
												arrNameAssign = temp;
												$$.name = new string(temp);
												//cout<<"aaaaaa  "<<$4.name[0]<<endl;
												arrAssignDim.push_back($4.name[0]);
											}
										}
									}
									arrFlag = 0;
								}
							}	

			| ELIST C_SB O_SB 
					{	
						if(($1.type!=NULL && $1.type[0]=="errorType"));
						else{
							arrFlag = 1; 
						}
					} 
				EXP	{	
						if(($1.type!=NULL && $1.type[0]=="errorType") || ($5.type!=NULL && $5.type[0]=="errorType")){
							if($$.type==NULL) $$.type = new string("errorType");
							else $$.type[0] = "errorType";
						}
						else{
							$$.name = $1.name;
							arrAssignDim.push_back($5.name[0]);
						}
				}
			;

/************************************************ASSIGNMENTS **********************************************************/


ASS : 		LEFT ASS 				{ 	
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($2.type!=NULL && $2.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{	
											if($1.type[0]!="errorType" && $2.type[0]!="errorType" ){
												$$.type = $1.type;
												int pos;
												if($2.returnQuad!=-1){
													if(AND_OR == 0){

														if($1.type[0]=="int" && $2.type[0]=="int"){
															$$.type = new string("int");
														}
														else if($1.type[0]=="float" && $2.type[0]=="float"){
															$$.type = new string("float");
														}
														else{
															if($2.type[0]=="float"){
																int newTemp = getTemp();
																
																string temp = "convertToInt " + $2.name[0] + " , _t" + to_string(newTemp);
																genCode(temp);
																if($2.name[0][0]=='_')  freeFloat($2.name[0]);
																$2.name[0].clear();
																$2.name[0] =  "_t" + to_string(newTemp);
																$$.type = new string("int");
															}
															else{
																int newTemp = getFloat();
																string temp = "convertToFloat " + $2.name[0] + " , _f" + to_string(newTemp);
																genCode(temp);
																if($2.name[0][0]=='_')  freeTemp($2.name[0]);
																$2.name[0].clear();
																$2.name[0] =  "_f" + to_string(newTemp);
																$$.type = new string("float");
															}
														}
														if(arrAssFlag == 1){
															string temp = $1.name[0] + "=" + $2.name[0];
															genCode(temp);
														}
														$$.name = $2.name;
														if($2.name[0].substr(0,2)=="_t"){
															freeTemp($2.name[0]);
														}
														if($2.name[0].substr(0,2)=="_f"){
															freeFloat($2.name[0]);
														}
													}
													else if(AND_OR == 1){
														string temp = "if " + $2.name[0] + " <= 0 goto L"+ to_string(nextQuad+4);
														genCode(temp);
														backPatch($2.shortTrueList,nextQuad);
														string temp0 = "L" + to_string(nextQuad) + " : ";
														genCode(temp0);
														string temp00 =  $1.name[0] + " = 1";
														genCode(temp00);
														string temp01 = "goto L" + to_string(nextQuad+3);
														genCode(temp01); 
														if($2.shortFalseList!=NULL)
															backPatch($2.shortFalseList,nextQuad);
														string temp1 = "L" + to_string(nextQuad) + " : ";
														genCode(temp1);
														string temp11 =  $1.name[0] + " = 0";
														genCode(temp11);
														string temp2 = "L" + to_string(nextQuad) + " : ";
														genCode(temp2);
														
														$$.name = $2.name;
														if($2.name[0][0]=='_') freeTemp($2.name[0]);
													}
												}
												if(arrAssFlag != 1 && AND_OR != 1){
													string newStr = idName + " = " + $2.name[0];
													genCode(newStr);
												}
												if(arrAssFlag == 1){arrAssFlag = 0;}
												if(AND_OR == 1){AND_OR = 0;}
												/*else{
													//reverse(delay.begin(),delay.end()-2);
													for(int i=0;i<delay.size();i++){
														if(delay[i].substr(0,8) == "refparam") delay[i] += $1.name[0]; 
														genCode(delay[i]);
														string tt = delay[i].substr(6);
														if(tt[0]=='_') freeTemp(tt);
													}
													delay.clear();		
												}*/
											}
											else{
												$$.type = new string("errorType");
											}

											int i = toFree.size()-1;
											while(i>=0){
												freeTemp(toFree[i--]);
											}
											if(toFree.size()){
												toFree.clear();
											}	
											assFlag = 0;
										}
									}

			| EXP					{ 	
										if(($1.type!=NULL && $1.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											$$.type = $1.type;
											$$.name = $1.name;
											$$.shortTrueList = $1.shortTrueList;
											$$.shortFalseList = $1.shortFalseList;
											$$.returnQuad = $1.returnQuad;
										}
									}

			| ID ASS_OP EXP 		{		
											if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
												if($$.type==NULL) $$.type = new string("errorType");
												else $$.type[0] = "errorType";
											}
											else{
												int position;
												int currScope = scope;
												int found = 0;
												if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
													found = 1;
												}

												while(found == 0 && currScope > 0){
													if(searchVar($1.name,activeFuncPtr,currScope,position)){
														found = 2;
														break;
													}
													else{
														currScope--;
													}
												}
												
												if(found == 0){
													if(searchVar($1.name,0,0,position)){
														$$.type = &(globalFuncTable[0]->varTable[position]->type);
														string temp = globalFuncTable[0]->varTable[position]->name + "_0_global";
														$$.name = new string(temp);
														string s(1,$2.name[0][0]);
														string tmp = temp + " = " + temp + s + $3.name[0];
														genCode(tmp);
													}
													else{
														cout<<"Identifier "<<$1.name[0]<<" Not Declared"<<endl;
														$$.type = new string("errorType");
														error = true;
													}
												}
												else{
													string type;
													if(found==1) {
														type = (globalFuncTable[activeFuncPtr]->paramTable[position]->type);
														
														string temp = globalFuncTable[activeFuncPtr]->paramTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
														$$.name = new string(temp);
														string s(1,$2.name[0][0]);
														string tmp = temp + " = " + temp + s + $3.name[0];
														genCode(tmp);
														
													}
													else {
														type = (globalFuncTable[activeFuncPtr]->varTable[position]->type);
														string temp = globalFuncTable[activeFuncPtr]->varTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->varTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
														$$.name = new string(temp);
														string s(1,$2.name[0][0]);
											
														string tmp = temp + " = " + temp + s + $3.name[0];
														genCode(tmp);
														
													}
													
													if($3.type[0]=="errorType" || type=="errorType" ){					
														$$.type = new string("errorType");
														error=1;
													}	
													else{
														$$.type = &type;
													}
												}
											}
									}
			;



LEFT :		ID ASSIGN 				{	
										if(($1.type!=NULL && $1.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											assFlag = 1;
											int position;
											int currScope = scope;
											int found = 0;
											if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
												found = 1;
											}
											while(found == 0 && currScope > 0){
												if(searchVar($1.name,activeFuncPtr,currScope,position)){
													found = 2;
													break;
												}
												else{
													currScope--;
												}
											}
											if(found == 0){
												if(searchVar($1.name,0,0,position)){
													idName = $1.name[0] + "_0_" + globalFuncTable[activeFuncPtr]->name;
													$$.type = &(globalFuncTable[0]->varTable[position]->type);
													idType = $$.type[0];
													string temp = globalFuncTable[0]->varTable[position]->name + "_0_global";
													$$.name = new string(temp);
												}
												else{
													cout<<"Identifier "<<$1.name[0]<<" Not Declared"<<endl;
													$$.type = new string("errorType");
													error = true;

												}
											}
											else{
												if(found==1){
													idName = $1.name[0] + "_" + to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name;
													$$.type = &(globalFuncTable[activeFuncPtr]->paramTable[position]->type);
													idType = $$.type[0];
													string temp = globalFuncTable[activeFuncPtr]->paramTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
													$$.name = new string(temp);
													
												}
												else{
													idName = $1.name[0] + "_" + to_string(globalFuncTable[activeFuncPtr]->varTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name;
													$$.type = &(globalFuncTable[activeFuncPtr]->varTable[position]->type);
													idType = $$.type[0];
													string temp = globalFuncTable[activeFuncPtr]->varTable[position]->name + "_"+ to_string(globalFuncTable[activeFuncPtr]->varTable[position]->scope) + "_" + globalFuncTable[activeFuncPtr]->name ;
													$$.name = new string(temp);
												}
									
											}
										}
									}
			| ARR ASSIGN			{ 
										arrAssFlag = 1;
										if(($1.type!=NULL && $1.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											$$.name = $1.name; 
										}
									}
			;	

ASS_OP :    PLUS_ASS				{ $$.name = $1.name;}
			| MINUS_ASS				{ $$.name = $1.name;}
			| MULT_ASS				{ $$.name = $1.name;}
			| DIV_ASS				{ $$.name = $1.name;}
			;		



/**************************************************** IF-ELSE  **********************************************************/


IFELSE-STAT : IFELSE M stmt M 
						ELSE M {
								if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType"));
								else{
									//string temp0 = "L" + to_string($2) + " :"; 
									//interCode.insert(interCode.begin()+$2,temp0);
									//nextQuad++;
									//interCode[$2] = temp0 + interCode[$2];
									string temp = "goto L";
									genCode(temp); 
									string temp1 = "L" + to_string(nextQuad) + " :"; 
									genCode(temp1); 
									}
								}  
							stmt	{	
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType") || ($8.type!=NULL && $8.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											if($1.falseList!=NULL) backPatch($1.falseList,$6+1);
											$$.breakList = catinateList($3.breakList,$8.breakList);
											$$.continueList = catinateList($3.continueList,$8.continueList);
											interCode[$4] 	+= to_string(nextQuad);
											string temp = "L" + to_string(nextQuad) + " :"; 
											genCode(temp);
										}
									}

			| IFELSE M stmt M	%prec IFX   {	
												if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													//string temp0 = "L" + to_string($2) + " :"; 
													//interCode.insert(interCode.begin()+$2,temp0);
													//nextQuad++;
													//interCode[$2] = temp0 + interCode[$2];
													if($1.falseList!=NULL)backPatch($1.falseList,nextQuad);
										 			string temp = "L" + to_string(nextQuad) + " :"; 
													genCode(temp);	
													$$.breakList = $3.breakList;
													$$.continueList = $3.continueList;
												}
											}
			;

IFELSE :	IF OP ASS CP			{	
										if(($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											$$.falseList = new vector<int>();
											(*$$.falseList).push_back(nextQuad);
											if($3.shortTrueList != NULL){
												backPatch($3.shortTrueList, nextQuad+1);
											}
											$$.falseList = catinateList($3.shortFalseList,$$.falseList);
											string temp = "if " + $3.name[0] + " <= 0 goto ";
											genCode(temp);
											AND_OR = 0;	
											string temp0 = "L" + to_string(nextQuad) + " :"; 
											//interCode.insert(interCode.begin()+$2,temp0);
											//nextQuad++;
											genCode(temp0);
										}
									}
			; 


/**********************************************SWITCH-CASE  ***********************************************************/


SWITCH_STMT: SWITCH_HEAD O_CURLY CASE_LIST DEF_STMT C_CURLY {
																if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType") || ($4.type!=NULL && $4.type[0]=="errorType")){
																	if($$.type==NULL) $$.type = new string("errorType");
																	else $$.type[0] = "errorType";
																}
																else{
																	string tmp = "goto L" + to_string(nextQuad);
																	int currQuad = nextQuad;
																	genCode(tmp);  
																	string temp = "CONDITION" + to_string(condCount) +  " :";
																	genCode(temp);
																	for(int i=0;i<delaySwitch.size();i++){
																		
																		if($4.begin==1 && i==(delaySwitch.size()-1))
																			genCode(delaySwitch[i]);
																		else{
																			delaySwitch[i].insert(3,$1.result[0]);
																			genCode(delaySwitch[i]);
																		}
																	}
																	delaySwitch.clear();
																	if($3.falseList!=NULL) backPatch($3.falseList,currQuad);
																	if($4.falseList!=NULL) backPatch($4.falseList,currQuad);
																	$3.falseList=NULL;
																	$4.falseList=NULL;
																	tmp.clear();
																	tmp = "L" + to_string(currQuad) + " :";
																	genCode(tmp);
																}
															}
			;


SWITCH_HEAD: SWITCH OP ASS M CP 	{	
										if(($3.type!=NULL && $3.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											$$.test = $4;
											$$.result = $3.name;
											string temp = "goto CONDITION" + to_string(condCount);
											genCode(temp);
										}
									}


CASE_LIST : /*empty*/				{ $$.falseList = NULL;}
			| CASE_STMT CASE_LIST 	{ 
										if(($1.type!=NULL && $1.type[0]=="errorType") || ($2.type!=NULL && $2.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{ 
											$$.falseList = catinateList($1.falseList,$2.falseList);
											$$.begin = 1;
										}
									}
			;

DEF_STMT :	/*empty*/ { $$.falseList = NULL;}
			| DEFAULT COLON M 		{ 	 string temp1 = "L" + to_string(nextQuad) + " :"; genCode(temp1); }
					stmtList		{
										if(($5.type!=NULL && $5.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											string temp = "goto L" + to_string($3);
											delaySwitch.push_back(temp);
											$$.falseList = $5.breakList;
											$$.begin = 1;
										}
									}
			;

CASE_STMT : CASE VAL1 COLON M 		{ string temp1 = "L" + to_string(nextQuad) + " :"; genCode(temp1); }  
					stmtList		{  
										if(($6.type!=NULL && $6.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											string temp = "if  = " + $2.name[0] + " goto L" + to_string($4);
											delaySwitch.push_back(temp);
											$$.falseList = $6.breakList;
										}
									}
			;

VAL1 : 		INT_LIT					{ $$.name = $1.name;}
			;			 


/***************************************************** WHILE-LOOP **********************************************************/

WHILE-STAT: WHILE_EXP M 
						{
							if(($1.type!=NULL && $1.type[0]=="errorType"));
							else{
								string temp0 = "L" + to_string($2) + " :";
								genCode(temp0);
							}
						} 
			stmt		{	
							if(($1.type!=NULL && $1.type[0]=="errorType") || ($4.type!=NULL && $4.type[0]=="errorType")){
								if($$.type==NULL) $$.type = new string("errorType");
								else $$.type[0] = "errorType";
							}
							else{
								//string temp0 = "L" + to_string($2) + " :";
								//genCode(temp0); 
								// interCode[$2] = temp0 + interCode[$2];
								string temp = "goto L"+ to_string($1.begin) ;
								genCode(temp);
								if($4.continueList != NULL) backPatch($4.continueList,$1.begin);
								$4.continueList=NULL;
								temp.clear();
								if($4.breakList!=NULL) backPatch($4.breakList,nextQuad);
								backPatch($1.falseList,nextQuad);
								$4.breakList=NULL;
							 	temp = "L" + to_string(nextQuad) + " :"; 
								genCode(temp);
							}
					}
		    ;

WHILE_EXP:  WHILE M {string temp1 = "L" + to_string(nextQuad) + " :"; genCode(temp1);} 
				 OP ASS CP 			{	
				 						if(($5.type!=NULL && $5.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											$$.falseList = new vector<int>();
											(*$$.falseList).push_back(nextQuad);
											if($5.shortTrueList != NULL){
												backPatch($5.shortTrueList, nextQuad+1);
											}
											$$.falseList = catinateList($5.shortFalseList,$$.falseList);
											string temp = "if " + $5.name[0] + " <= 0 goto ";
											genCode(temp);
											$$.begin = $2;
											AND_OR = 0;
										}
									}
			;


/**************************************************** FOR-LOOP *************************************************************/


FOR-STAT:   FOR_EXP {	
						if(($1.type!=NULL && $1.type[0]=="errorType"));					
						else {
							string temp1 = "L" + to_string(nextQuad) + " :"; genCode(temp1);
						}
					} 
				stmt 
					{	
						if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
							if($$.type==NULL) $$.type = new string("errorType");
							else $$.type[0] = "errorType";
						}
						else{
							if($3.continueList != NULL) backPatch($3.continueList,$1.incBegin);
							$3.continueList=NULL;
							if($3.breakList!=NULL) backPatch($3.breakList,nextQuad+1);
							$3.breakList=NULL;
							string temp = "goto L" + to_string($1.incBegin);
							genCode(temp);
							string temp1 = "L" + to_string(nextQuad) + " :";
							genCode(temp1);
							if($1.falseList!=NULL) backPatch($1.falseList,nextQuad-1);
							$1.falseList=NULL;
						}
					}

		    ;

FOR_EXP : 	FOR OP EXP_LIST SEMI M 	{ 
										if(($3.type!=NULL && $3.type[0]=="errorType"));
										else{
											string temp1 = "L" + to_string(nextQuad) + " :"; genCode(temp1);
										}
									}
					EXP_LIST SEMI M	{	
										if(($3.type!=NULL && $3.type[0]=="errorType") || ($7.type!=NULL && $7.type[0]=="errorType"));
										else{
											string temp;
											if($7.name!=NULL) temp = "if " + $7.name[0] + " <= 0 goto ";
											else {
												temp = "if 1 <= 0 goto ";
											}
											genCode(temp);
											temp.clear();
											temp = "goto L";
											genCode(temp);
											string temp1 = "L" + to_string(nextQuad) + " :"; 
											genCode(temp1);
										}
					 				} 

					M EXP_LIST CP 	{	
										if(($3.type!=NULL && $3.type[0]=="errorType") || ($7.type!=NULL && $7.type[0]=="errorType") || ($12.type!=NULL && $12.type[0]=="errorType")){
											if($$.type==NULL) $$.type = new string("errorType");
											else $$.type[0] = "errorType";
										}
										else{
											$$.falseList = new vector<int>();
											if(delay.size()>0){
												for(int i=0;i<delay.size();i++){
													genCode(delay[i]);
												}
											}
											delay.clear();
											(*$$.falseList).push_back($9);
											$$.incBegin = $11-1;
											interCode[$9+1] += to_string(nextQuad+1);
											string temp = "goto L" + to_string($5);
											genCode(temp);
										}
									}

			;

EXP_LIST : 	/*empty*/
			| EXP_LI 
								{
									if(($1.type!=NULL && $1.type[0]=="errorType")){
										if($$.type==NULL) $$.type = new string("errorType");
										else $$.type[0] = "errorType";
									}
								}


EXP_LI : 	ASS COMMA EXP_LI
								{
									if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
										if($$.type==NULL) $$.type = new string("errorType");
										else $$.type[0] = "errorType";
									}
								}
			| ASS 				{
									if(($1.type!=NULL && $1.type[0]=="errorType")){
										if($$.type==NULL) $$.type = new string("errorType");
										else $$.type[0] = "errorType";
									}
								}
			;


/**************************************************** FUNCTION_DEC ********************************************************/


FUNC_DECL : FUNC_HEAD 						{ 	
												if(($1.type!=NULL && $1.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													$$.name = $1.name; 
												}
											}
			;

FUNC_HEAD : RES_ID OP DECL_PLIST CP			{	
												if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													scope=2;
													$$.name = $1.name;
												}  
											}
			;


RES_ID :	DTYPE ID						{	
												int position; 
												bool found=searchFuncEntry($2.name,position);
												if(found){
													funcRedecFlag = true;
													redecFuncName = $2.name[0];
													$$.name = $2.name;
													
												}
												else{
													position = insertFuncTab($2.name,$1.name);
													$$.name = $2.name;
													
												}
												scope=1;
												activeFuncPtr = position;
											}
			;

DECL_PLIST: /*empty*/ 					
			| DECL_PL
			;

DECL_PL: 	DECL_PARAM COMMA DECL_PL		
			| DECL_PARAM				
			;

DECL_PARAM : DTYPE
			| DTYPE ID						{

												int position;
												bool found = searchParam($2.name,activeFuncPtr,position);
												if(funcRedecFlag){
													if(found){
														if(globalFuncTable[activeFuncPtr]->paramTable[position]->type!= $1.name[0]) cout<<"Paramter " << $2.name[0]<<" type mismatch in declaration and definition\n"<<endl; 
													}
													else{
														cout<<"Parameter "<<$2.name[0]<<"not declared\n"<<endl;
													}	
												}
												else{
													if(found){
														cout<<"Redefinition of parameter "<<$2.name[0]<<"\n";
														error=true;
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
													}
													else{
														insertParam($2.name,$1.name,activeFuncPtr);
													}
												}
											}
			| DTYPE ID O_SB C_SB
			| DTYPE ID O_SB INT_LIT C_SB
			;


/******************************************************FUNCTION_DEF **********************************************************/


FUNC_DEF : FUNC_DECL 	{ 	
							if(($1.type!=NULL && $1.type[0]=="errorType"));
							else{
								string temp = "func begin " + $1.name[0]; 
								genCode(temp);
								string tmp = "BeginFunc ";
								fncQuad = nextQuad;
								genCode(tmp);
							}
						} 
					O_CURLY stmtList C_CURLY	{
													if(($1.type!=NULL && $1.type[0]=="errorType") || ($4.type!=NULL && $4.type[0]=="errorType")){
														if($$.type==NULL) $$.type = new string("errorType");
														else $$.type[0] = "errorType";
													}
													else{
														scope=0;
														if(funcRedecFlag==1 ){
															if(globalFuncTable[activeFuncPtr]->fnDec){
																globalFuncTable[activeFuncPtr]->fnDec = 0;
															}
															else{
																cout<<"Redefinition of function "<<redecFuncName<<endl;
																error=1;
																if($$.type==NULL) $$.type = new string("errorType");
																else $$.type[0] = "errorType";
															}
														}

														if(returnFlag == false){
															cout<<"Return type required\n";
															error = true;
															if($$.type==NULL) $$.type = new string("errorType");
															else $$.type[0] = "errorType";
														}
														returnFlag = false;

														int varUsed = getSize(activeFuncPtr);
														interCode[fncQuad] += to_string(varUsed);
														funcRedecFlag=0;
														redecFuncName.clear();
													
														activeFuncPtr=0;
														string temp = "func end"; 
														genCode(temp);
													}
												}
			;


/**************************************************** FUNCTION_CALL *********************************************************/


FUNC_CALL: ID 							{	
											if(($1.type!=NULL && $1.type[0]=="errorType"));
											else{
												int position; 
												bool found=searchFuncEntry($1.name,position);
												if(!found){
													cout<<"Undefined reference to function "<<$1.name[0]<<endl;
													error = 1;
												}
												else{
													callNamePtr = position;
													assignFun = callNamePtr;
												}
											}
 										} 

			OP PARAMLIST CP				{	
											if(($1.type!=NULL && $1.type[0]=="errorType") || ($4.type!=NULL && $4.type[0]=="errorType")){
												if($$.type==NULL) $$.type = new string("errorType");
												else $$.type[0] = "errorType";
											}
											else{
												if(error==1){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}

												if(callNamePtr!=-1){
													int paramCnt = globalFuncTable[callNamePtr]->cntParam;
													if(passedParam != paramCnt){
														$$.type= new string("errorType");
														cout<<"Number of Parameters are not correct\n";
														error=true;
													}
													else{
														string tmp = globalFuncTable[callNamePtr]->returnType;
														$$.type = new string(tmp);
														string temp = "refparam ";
														delay.push_back(temp);
														temp.clear();
														temp = "call " + globalFuncTable[callNamePtr]->name + " , " + to_string(paramCnt+1);
														delay.push_back(temp);
													}
												}
												else{
													$$.type = new string("errorType");
													error=1;
												}
												paramPos=0;
												passedParam=0;
												callNamePtr = -1;
											}
										}
			;

PARAMLIST: PLIST							
			| /*empty*/
			;

PLIST: 	EXP									{
												if(($1.type!=NULL && $1.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													int paramCnt = globalFuncTable[callNamePtr]->cntParam;
													paramPos=paramCnt-1;
													if(paramPos>=0){
														bool correct =checkParamType(paramPos,$1.type,callNamePtr);
														passedParam++;
														string temp = "param " + $1.name[0];
														delay.push_back(temp);
														if(!correct){
															cout<<"Type mismatch for parameter\n";
															error=true;
															if($$.type==NULL) $$.type = new string("errorType");
															else $$.type[0] = "errorType";
														}
													}
													paramPos--;
												}
											}

			| EXP COMMA PLIST				{	
												if(($1.type!=NULL && $1.type[0]=="errorType") || ($3.type!=NULL && $3.type[0]=="errorType")){
													if($$.type==NULL) $$.type = new string("errorType");
													else $$.type[0] = "errorType";
												}
												else{
													int paramCnt = globalFuncTable[callNamePtr]->cntParam;
													if(paramPos>=0){
														bool correct = checkParamType(paramPos,$1.type,callNamePtr);
														passedParam++;
														string temp = "param " + $1.name[0];
														delay.push_back(temp);
														if(!correct){
															cout<<"Type mismatch for parameter\n";
															error=true;
															if($$.type==NULL) $$.type = new string("errorType");
															else $$.type[0] = "errorType";
														}
													}
													paramPos--;
												}
											}
			;


/*****************************************EXTRA NONTERMINALS*****************************************************************/

M : 		/*empty*/ 						{ $$ = nextQuad;}
			;

N : 		/*empty*/
			;


/****************************************************************************************************************************/


%%
int yyerror(char* s)
{
	
}

int insertVarSymTab(string* name,int activeFuncPtr, int elemType){
	struct varSymbolTableEntry* tmp = new struct varSymbolTableEntry();
	tmp->name = name[0];
	tmp->eleType = elemType;
	tmp->scope = scope;
	tmp->tag = 0;
	tmp->tempVar =-1;
	int index = globalFuncTable[activeFuncPtr]->varTable.size();
	globalFuncTable[activeFuncPtr]->varTable.push_back(tmp);
	return index;
}


void insertParam(string* name,string* type,int activeFuncPtr){
	struct varSymbolTableEntry* tmp = new struct varSymbolTableEntry();
	tmp->name = name[0];
	tmp->eleType = 0;
	tmp->scope = scope;
	tmp->tag = 1;
	tmp->type = type[0];
	tmp->tempVar =-1;

	int index = globalFuncTable[activeFuncPtr]->paramTable.size();
	globalFuncTable[activeFuncPtr]->paramTable.push_back(tmp);
	globalFuncTable[activeFuncPtr]->cntParam++;
}


int insertFuncTab(string* name,string* returnType){
	struct fnNameTableEntry* tmp = new struct fnNameTableEntry();
	tmp->name = name[0];
	tmp->returnType = returnType[0];
	tmp->cntParam = 0;
	tmp->fnDec=true;

	int index = globalFuncTable.size();
	globalFuncTable.push_back(tmp);
	return index;
}


void patchtype(string* type,vector<int>nameList,int activeFuncPtr){
	for(auto x:nameList){
		globalFuncTable[activeFuncPtr]->varTable[x]->type = type[0];
	}	
}


void deleteVarList(int activeFuncPtr){
	globalFuncTable[activeFuncPtr]->varTable.clear();
}


bool searchFuncEntry(string* name,int &position){
	for(int i=0;i<globalFuncTable.size();i++){
		if(globalFuncTable[i]->name==name[0]){
			position=i;
			return 1;
		}
	}
	return 0;
}


bool searchVar(string* name,int activeFuncPtr,int currScope,int &position){
	for(int i=0;i<globalFuncTable[activeFuncPtr]->varTable.size();i++){
		if((globalFuncTable[activeFuncPtr]->varTable[i]->name == name[0]) && (globalFuncTable[activeFuncPtr]->varTable[i]->scope == currScope)){
			position = i;
			return 1; 
		}
	}
	return 0;
}


bool searchParam(string* name,int activeFuncPtr,int &position){
	for(int i=0;i<globalFuncTable[activeFuncPtr]->paramTable.size();i++){
		if(globalFuncTable[activeFuncPtr]->paramTable[i]->name == name[0]){
			position = i;
			return 1; 
		}
	}
	return 0;
}


bool checkParamType(int paramPos,string* type,int callNamePtr){
	string paramType = globalFuncTable[callNamePtr]->paramTable[paramPos]->type ; 
	return paramType == type[0]; 
}

void genCode(string code){
	interCode.push_back(code);
	nextQuad++;
}



void backPatch(vector<int>*list1,int quad){
	for(int i=0;i<list1[0].size();i++){
		
		int k = list1[0][i];
		string temp = "L" + to_string(quad) ;
		interCode[k] = interCode[k] + temp;
	}
}

vector<int>* catinateList(vector<int>*list1,vector<int>*list2){
	if(list1 == NULL){
		return list2;
	}
	else if(list2 == NULL){
		return list1;
	}
	else{
		for(int i=0;i<list2[0].size();i++){
			list1[0].push_back(list2[0][i]);
		}
		return list1;
	}
}

int idSearch(string s){
	string line;
    ifstream myfile ("keywords.txt");

    while ( !myfile.eof() ){
		getline (myfile,line);
    	if(line == s){
    		myfile.close();
    		return 1;
    	}
    	line.clear();
    }
    myfile.close();
    return 0;
}

int main()
{
	string* GlobalFnname = new string("global");
	string* returnType = new string("null");
	activeFuncPtr =0;
	insertFuncTab(GlobalFnname,returnType);
	globalFuncTable[activeFuncPtr]->fnDec = false;
	yyparse();
	if(error==true){
		FILE *fp11;
		fp11 = fopen("interCode.txt","w");
		fclose(fp11);
		return 1;
	}
	

	ofstream fout11 ("interCode.txt");
	for(int i=0;i<interCode.size();i++){
		fout11<<interCode[i]<<endl;
	}
	
	FILE *fp;
	fp = fopen("globalVar.txt","w");
	ofstream cout("globalVar.txt");
	for(int j=0;j<1;j++){
		for(int i=0;i<globalFuncTable[j]->varTable.size();i++){
			int scope = globalFuncTable[j]->varTable[i]->scope;
			cout<<globalFuncTable[j]->varTable[i]->name<<"_"<<scope<<"_"<<globalFuncTable[j]->name<<": .";
			if(globalFuncTable[j]->varTable[i]->type=="float") cout<<"float"<<" 0.0"<<endl;
			else cout<<"word"<<" 0"<<endl;
		}

		for(int i=0;i<globalFuncTable[j]->paramTable.size();i++){
			int scope = 1;
			cout<<globalFuncTable[j]->paramTable[i]->name<<"_"<<scope<<"_"<<globalFuncTable[j]->name<<": .";
			if(globalFuncTable[j]->paramTable[i]->type=="float") cout<<"float"<<" 0.0"<<endl;
			else cout<<"word"<<" 0"<<endl;
		}
	}

	ofstream fout ("localVar.txt");

    for(int i=1;i<globalFuncTable.size();i++){
        int off = 4;
        for(int j = 0;j<globalFuncTable[i]->varTable.size();j++){
			string scope = to_string(globalFuncTable[i]->varTable[j]->scope);
            string sName = globalFuncTable[i]->varTable[j]->name+"_"+scope+"_"+globalFuncTable[i]->name;
            fout<<sName<<endl;

            string offSet = to_string(off);
            fout<<offSet<<endl;

            if(globalFuncTable[i]->varTable[j]->eleType){
                int num = 1;
                int k = 0;
                for(int k =0; k <globalFuncTable[i]->varTable[j]->dimListPtr.size(); k++){
                    num = num*globalFuncTable[i]->varTable[j]->dimListPtr[k];
                }
                num = num*4;
                off = num + off;
            }
            else{
                off = off + 4;
            }

            string sType = (globalFuncTable[i]->varTable[j]->type);
            fout<<sType<<endl;
        }
	
		off += 4;
        for(int j = 0;j<globalFuncTable[i]->paramTable.size();j++){
			string scope="1";
            string sName = globalFuncTable[i]->paramTable[j]->name + "_"+scope+"_"+globalFuncTable[i]->name;
            fout<<sName<<endl;

			string offSet = to_string(off);
            fout<<offSet<<endl;
			off +=4;
            string sType = (globalFuncTable[i]->paramTable[j]->type);
            fout<<sType<<endl;
        }
	}
	fout.close();

	ofstream fout2 ("globalVar.txt");
	int i=0;
    for(int j = 0;j<globalFuncTable[i]->varTable.size();j++){
		string scope = to_string(globalFuncTable[i]->varTable[j]->scope);
        string sName = globalFuncTable[i]->varTable[j]->name+"_"+scope+"_"+globalFuncTable[i]->name;
        fout2<<sName<<endl;

        int num = 1;
        if(globalFuncTable[i]->varTable[j]->eleType){
            int k = 0;
            for(int k =0; k <globalFuncTable[i]->varTable[j]->dimListPtr.size(); k++){
                num = num*globalFuncTable[i]->varTable[j]->dimListPtr[k];
            }
            num = num*4;
        }

        string sType = (globalFuncTable[i]->varTable[j]->type);
	    if(globalFuncTable[i]->varTable[j]->eleType){
	        fout2<<sType<<"_array"<<endl;
	        fout2<<num<<endl;
	    }
	    else{
	        fout2<<sType<<endl;	    
	    }
    }
	fout2.close();

	return 0;
}


int getFloat(){
	int i;
	for(i=0;i<32;i++){
		if(floatNames[i]==0 && i%2==1){
			floatNames[i] = 1;
			return i;
		}		
	}
	cout<<"No temporary variables left\n";
	return -1;	
}


void freeFloat(string name){
	string temp = name.substr(2);
	int index = stoi(temp);
	floatNames[index] = 0;
}

int getTemp(){
	int i;
	for(i=0;i<8;i++){
		if(tempNames[i]==0){
			tempNames[i] = 1;
			return i;
		}		
	}
	cout<<"No temporary variables left\n";
	return -1;
}

void freeTemp(string name){
	string temp = name.substr(2);
	int index = stoi(temp);
	tempNames[index] = 0;
}

int getSize(int activeFuncPtr){
	int size =0;
	for(int i=0;i<globalFuncTable[activeFuncPtr]->varTable.size();i++){
		if(globalFuncTable[activeFuncPtr]->varTable[i]->eleType == 0) size++;
		else{
			int prod=1;
			for(int j=0;j<globalFuncTable[activeFuncPtr]->varTable[i]->dimListPtr.size();j++){
				prod *= globalFuncTable[activeFuncPtr]->varTable[i]->dimListPtr[j];
			}
			size += prod;
		}
	}
	return size;
}

