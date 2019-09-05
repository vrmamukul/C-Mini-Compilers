%{
#pragma GCC diagnostic ignored "-Wwrite-strings"
	
	#include "interHeader.h"
	using namespace std;
    
    extern int yylex();
	extern int yylineno;
	extern char* yytext;
	extern FILE* yyout;
	int yyerror(char *s);
    int fnVar=0;
    vector<pair<string,int>>variableMap;
    int offset = 0;
    vector<string>mipCode;
    vector<string> varName;
    vector<string> varType;
    vector<string> varOffset;
    vector<string> gloVarName;
    vector<string> gloVarType;
    vector<string> gloVarSize;
    vector<int>tempNames(8,0);
    vector<int>floatNames(32,0);
    vector<string>delay;
    string refParam;
    int paramCount=0;
%}

%union{
	 string* name;
     int integer;
}

%start  code
    
%token <name> LABEL STR INT_LIT FLOAT_LIT LT_EQ EQUAL MINUS MULTI  GOTO COLON 
                PLUS BEGIN_FUNC FUNC_BEGIN IF NEWLINE GT_EQ LT GT EQ_EQ NOT_EQ POW
                AND OR NOT COMMA DOT  CALL PARAM REFPARAM END DQ  EF DIV FUNC_END  RETURN
                CNVRTFLOAT CNVRTINT 
%type <name> TERM stmt stmtList OPR

%%

code:       stmtList
            ;

stmtList:    stmt
			| stmt NEWLINE stmtList
            | error NEWLINE stmtList {cout<<"error\n";}
            ;

stmt:       /*empty*/
            | TERM EQUAL TERM PLUS TERM         
                                            {   
                                                if(isdigit($5[0][0])){
                                                    int newReg = getTemp();
                                                    
                                                    string temp = "\tli $t" + to_string(newReg) + ", " + $5[0];
                                                    $5[0] = "_t" + to_string(newReg);
                                                    genMipsCode(temp);
                                                } 
                                                string term1,term2,term3,opr;
                                                term1 = $1[0];
                                                term2 = $3[0];
                                                term3 = $5[0];
                                                opr = "add";
                                                oprTerm(term1, term2, term3, opr);
                                            }
            | TERM EQUAL TERM MINUS TERM            
                                            {
                                                if(isdigit($5[0][0])){
                                                    int newReg = getTemp();
                                                    
                                                    string temp = "\tli $t" + to_string(newReg) + ", " + $5[0];
                                                    $5[0] = "_t" + to_string(newReg);
                                                    genMipsCode(temp);
                                                }
                                                string term1,term2,term3,opr;
                                                term1 = $1[0];
                                                term2 = $3[0];
                                                term3 = $5[0];
                                                opr = "sub";
                                                oprTerm(term1, term2, term3, opr);
                                            }
            
            | TERM EQUAL TERM MULTI TERM               
                                            {
                                                if(isdigit($5[0][0])){
                                                    int newReg = getTemp();
                                                    
                                                    string temp = "\tli $t" + to_string(newReg) + ", " + $5[0];
                                                    $5[0] = "_t" + to_string(newReg);
                                                    genMipsCode(temp);
                                                }
                                                string term1,term2,term3,opr;
                                                term1 = $1[0];
                                                term2 = $3[0];
                                                term3 = $5[0];
                                                opr = "mul";
                                                oprTerm(term1, term2, term3, opr);
                                            }
            
            | TERM EQUAL TERM DIV TERM           
                                            {
                                                if(isdigit($5[0][0])){
                                                    int newReg = getTemp();
                                                    
                                                    string temp = "\tli $t" + to_string(newReg) + ", " + $5[0];
                                                    $5[0] = "_t" + to_string(newReg);
                                                    genMipsCode(temp);
                                                }
                                                string term1,term2,term3,opr;
                                                term1 = $1[0];
                                                term2 = $3[0];
                                                term3 = $5[0];
                                                opr = "div";
                                                oprTerm(term1, term2, term3, opr);
                                            }

            | TERM EQUAL TERM                        
                                            {
                                                if(isdigit($3[0][0]) || $3[0][0]=='-'){
                                                    char type = $1[0][1];
                                                    if(type=='t'){
                                                        string temp = "\tli $" + $1[0].substr(1) + ", " + $3[0];
                                                        genMipsCode(temp);
                                                    } 
                                                    else{
                                                        string temp = "\tli.s $" + $1[0].substr(1) + ", " + $3[0];
                                                        genMipsCode(temp);
                                                    } 
                                                }
                                                else{
                                                    string term1,term2,opr;
                                                    term1 = $1[0];
                                                    term2 = $3[0];
                                                    eqTerm(term1, term2);                                                                                                
                                                }
                                            }

                                                    
            
            | IF TERM OPR TERM GOTO LABEL       {
                                                    int flag1 = checkNameType($2[0]);
                                                    if(flag1 == 1 || flag1 == 2)
                                                        assignReg($2[0]);

                                                    if(isdigit($4[0][0])){
                                                        string type = $2[0].substr(1,1);
                                                        if($2[0][0] != '_')
                                                            type = regType($2[0]);
                                                        if(type=="t"){
                                                            int newReg = getTemp();                                                            
                                                            string temp = "\tli $t" + to_string(newReg) + ", " + $4[0];
                                                            $4[0] = "_t" + to_string(newReg);
                                                            genMipsCode(temp);
                                                        } 
                                                    }
                                                    int flag2 = checkNameType($4[0]);

                                                    if(flag2 == 1 || flag2 == 2)
                                                        assignReg($4[0]);

                                                    if(flag1 == 0)
                                                        $2[0] = genVarCode(1,$2[0],"");

                                                    if(flag1 == 3){
                                                        $2[0] = genArrCode(1,$2[0],"");  
                                                    }
                                                    if(flag2 == 0)
                                                        $4[0] = genVarCode(1,$4[0],"");

                                                    if(flag2 == 3){
                                                        $4[0] = genArrCode(1,$4[0],"");  
                                                    }
                                                    

                                                    if($3[0] == "="){
                                                        string temp = "\tbeq $" + $2[0].substr(1) + ", $" + $4[0].substr(1) + " " + $6[0];
                                                        genMipsCode(temp);
                                                    }
                                                    else if($3[0]== "<="){
                                                        string temp = "\tble $" + $2[0].substr(1) + ", $" + $4[0].substr(1) + " " + $6[0];
                                                        genMipsCode(temp);
                                                    }
                                                    else if($3[0]== "!="){
                                                        string temp = "\tbne $" + $2[0].substr(1) + ", $" + $4[0].substr(1) + " " + $6[0];
                                                        genMipsCode(temp);
                                                    }
                                                    else{
                                                        string temp = "\tbgt $" + $2[0].substr(1) + ", $" + $4[0].substr(1) + " " + $6[0];
                                                        genMipsCode(temp);
                                                    }
                                                    freeReg($2[0].substr(1,1),stoi($2[0].substr(2)));
                                                    freeReg($4[0].substr(1,1),stoi($4[0].substr(2)));
                                                }

            | GOTO LABEL                            {  string temp = "\tj "+ $2[0]; genMipsCode(temp);}
            | LABEL COLON                           {  string temp = ($1)[0] + ":"; genMipsCode(temp); }
            | FUNC_BEGIN TERM                       {  string temp = ($2)[0] + ":"; genMipsCode(temp); }
            | BEGIN_FUNC TERM                       {  
                                                        
                                                        fnVar = stoi(($2)[0]);
                                                        string temp = "\taddi\t$sp,$sp,-"+ to_string(fnVar*4); 
                                                        genMipsCode(temp);
                                                        string t2 = "\taddi $sp, $sp, -4";
                                                        genMipsCode(t2);
                                                        string tt = "\tsw $ra, 0($sp)";
                                                        genMipsCode(tt);
                                                    }
            
            | RETURN TERM                           {
                                                       
                                                       int flag = checkNameType($2[0]);
                                                       if(flag==1 || flag == 2){
                                                           string temp = "\tmove $v0, $" + $2[0].substr(1); 
                                                           genMipsCode(temp);
                                                           freeReg($2[0].substr(1,1),stoi($2[0].substr(2)));
                                                       }
                                                       else{
                                                           int pos = checkVarPos($2[0]);
                                                           int freeReg = getTemp();
                                                           string temp = "\tlw $t" + to_string(freeReg) + ", " + to_string(pos) + "($sp)";
                                                           genMipsCode(temp);
                                                           temp.clear();
                                                           temp = "\tmove $v0, $t" + to_string(freeReg);
                                                           tempNames[freeReg]=0; 
                                                           genMipsCode(temp);
                                                       }

                                                        string t1 = "\tlw $ra, 0($sp)";
                                                        genMipsCode(t1);
                                                        string t2 = "\taddi $sp, $sp, 4";
                                                        genMipsCode(t2);
                                                  
                                                       string temp = "\taddi\t$sp,$sp," + to_string(fnVar*4); 
                                                       genMipsCode(temp);

                                                       string tmp = "\tjr $ra"; 
                                                       genMipsCode(tmp);
                                                    } 
            | FUNC_END                              {  string tmp = "\n"; genMipsCode(tmp);}
            
            | CNVRTFLOAT TERM COMMA TERM            {
                                                        convertToFloat($2[0],$4[0]);  
                                                    }

            
            | CNVRTINT TERM COMMA TERM              {
                                                        convertToInt($2[0],$4[0]);
                                                    }
            
            | PARAM TERM                            {
                                                        int flag = checkNameType($2[0]);
                                                        pushParam(flag,$2[0]);
                                                    }

            | REFPARAM TERM                         {
                                                        refParam = $2[0];
                                                        paramCount=0;
                                                    }

            | CALL TERM COMMA TERM                  {
                                                        fnVar = stoi(($4)[0]);
                                                        string tmp = "\taddi\t$sp,$sp,-"+ to_string(4);
                                                        genMipsCode(tmp);
                                                        string temp = "\tjal " + $2[0];
                                                        genMipsCode(temp);
                                                        temp.clear();
                                                        int flag = checkNameType(refParam);
                                                        if(flag==0){
                                                            int pos2 = checkVarPos(refParam);
                                                            int freeReg = getTemp();
                                                            string temp = "\tmove $t" + to_string(freeReg) + ", $v0";
                                                            genMipsCode(temp);
                                                            temp.clear();
                                                            
                                                            temp = "\taddi\t$sp,$sp, "+ to_string(fnVar*4);
                                                            genMipsCode(temp);
                                                            temp.clear();

                                                            temp = "\tsw $t" + to_string(freeReg) + ", " + to_string(pos2) + "($sp)";
                                                            genMipsCode(temp);
                                                            tempNames[freeReg] = 0;
                                                        }
                                                        else{
                                                            string temp = "\tlw $" + refParam.substr(1)  + ", 0($sp)";
                                                            genMipsCode(temp);
                                                            temp.clear();

                                                            temp = "\taddi\t$sp,$sp, "+ to_string(fnVar*4);
                                                            genMipsCode(temp);
                                                            temp.clear();
                                                        }
                                                      
                                                    }
            | END
            ;


TERM:       STR                     { $$ = $1;}
            | INT_LIT               { $$ = $1;}
            | FLOAT_LIT             { $$ = $1;}
            | STR DOT STR DOT       { $$ = new string (($1[0] + "[" + $3[0] + "]"));}
            | MINUS INT_LIT         { $$ = new string ("-" + $2[0]);}

            ;


OPR :       LT_EQ           { $$ = $1;}
            | EQUAL         { $$ = $1;}
            | GT            { $$ = $1;}
            | NOT_EQ        { $$ = new string("!=");}
            ;

%%


int yyerror(char* s)
{
	
}

int checkNameType(string name){
    if(name.substr(0,2)=="_t") return 1;
    else if (name.substr(0,2)=="_f") return 2;
    else{
        if(name[name.size()-1]==']') return 3;
        else return 0;
    }
}

int checkVarPos(string name){
    int flag=0;
    int pos;
   
    for(int i=0;i<varName.size();i++){            
        if(varName[i]==name){
            string temp = varOffset[i];
            if(temp=="") pos = 0;
            else pos = stoi(temp);
            break;
        }
    }
    return pos;

}

string checkVarType(string name){
    int flag=0;
    int pos;
   
    for(int i=0;i<varName.size();i++){            
        if(varName[i]==name){
           return varType[i];
        }
    }
    for(int i=0;i<gloVarName.size();i++){            
        if(gloVarName[i]==name){
           return gloVarType[i];
        }
    }
}

bool isGlobal(string name){
    for(int i=0;i<varName.size();i++){            
        if(varName[i]==name){
           return false;
        }
    }
    return true;
}

void moveVal(int flag,string name){
    if(!flag){
        int pos = checkVarPos(name);
        int freeReg = getTemp();
        string temp = "\tmflo $t" + to_string(freeReg);
        genMipsCode(temp);
        temp.clear();
        temp = "\tsw $t" + to_string(freeReg) + ", " + to_string(pos) + "($sp)";
        genMipsCode(temp);
        tempNames[freeReg] = 0;
    }
    else{
        string temp = "\tmflo $" + name.substr(1);
        genMipsCode(temp);
    }
}

void genMipsCode(string code){
    mipCode.push_back(code);
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


int getFloat(){
	int i;
	for(i=1;i<32;i++){
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

void assignReg(string name){
    if (name[1] == 't')
        assignTemp(name);
    if (name[1] == 'f')
        assignFloat(name);
}

void assignTemp(string name){
    string temp = name.substr(2);
	int index = stoi(temp);
	tempNames[index] = 1;
}

void assignFloat(string name){
    string temp = name.substr(2);
	int index = stoi(temp);
	floatNames[index] = 1;
}

string regType(string name){
    string type = checkVarType(name);
    if(type=="int"){
        return "t";
    }
    else{
        return "f";
    }
}

void freeReg(string type, int pos){
    if(type == "t"){
        tempNames[pos] = 0;  
    }
    if(type == "f"){
        floatNames[pos] = 0;                                                     
    }
}


string genVarCode(int flag,string name,string reg){
//  flag -> LHS(0) or RHS(1)
    int pos;
    if(!isGlobal(name)){
        pos = checkVarPos(name);
    }
    string type = checkVarType(name);
    string str, temp;
    int freeReg1;
    if(type=="int"){
        type = "t";
        freeReg1 = getTemp();
    }
    else{
        type = "f";
        str = "c1";
        freeReg1 = getFloat();
    }
    
    string tmpN;
    if(!isGlobal(name)){
        tmpN = to_string(pos) + "($sp)";
    }
    else{
        tmpN = name;
    }

    if(flag==1){
        temp = "\tlw"+ str + " $" + type + to_string(freeReg1) + ", " + tmpN;
        str = "_" + type + to_string(freeReg1);
    }
    else{
        temp = "\tsw" + str + " $" + reg + ", " + tmpN;
        str = "";
        freeReg(type,freeReg1);
    }
    genMipsCode(temp);
    return str;
}

string genArrCode(int flag,string name,string reg){
//  flag -> LHS(0) or RHS(1)
    string tempName;
    tempName = name.substr(0, name.find("["));  
    string tempIndx;
    tempIndx = name.substr(name.find("[")+1,name.find("]"));  
    tempIndx.resize(tempIndx.size()-1);
    int pos = checkVarPos(tempName);   

    int freeInt = getTemp();
    string temp = "\tli $t" + to_string(freeInt) + ", 4";
    genMipsCode(temp);
    temp.clear();

    temp = "\tmul $" + tempIndx.substr(1) + ", $t" + to_string(freeInt) + ", $" + tempIndx.substr(1);
    genMipsCode(temp);

    temp = "\tli $t" + to_string(freeInt) + ", " + to_string(pos);
    genMipsCode(temp);
    temp = "\tadd $t" + to_string(freeInt) + ", $t" + to_string(freeInt) + ", $" + tempIndx.substr(1);
    genMipsCode(temp);
    temp.clear();
    freeTemp(tempIndx);

    temp = "\tadd $sp, $sp, $t" + to_string(freeInt); 
    genMipsCode(temp);

    string newReg;
    if(flag == 0){
        string type = regType(tempName);
        newReg = "";

        if(type=="t"){
            temp = "\tsw $" + reg + ", 0($sp)";
        }
        else{
            temp = "\tswc1 $" + reg + ", 0($sp)";
        }
        genMipsCode(temp);
    }
    else{
        string type = regType(tempName);

        int freeTemp;
        if(type=="t"){
            freeTemp = getTemp();
            temp = "\tlw $" + type + to_string(freeTemp) + ", 0($sp)";
            genMipsCode(temp);
        }
        else{
            int freeFloat = getFloat();
            temp = "\tlwc1 $" + type + to_string(freeFloat) + ", 0($sp)";
            genMipsCode(temp);
            freeTemp = freeFloat;
        }
        newReg = "_" + type + to_string(freeTemp);
    }
    temp = "\tsub $sp, $sp, $t" + to_string(freeInt); 
    genMipsCode(temp);
    freeReg("t",freeInt);
    return newReg;
}


void convertToFloat(string term1,string term2){
    int flag1 = checkNameType(term1);

    if(flag1 == 0)
        term1 = genVarCode(1,term1,"");
    if(flag1 == 3){
        term1 = genArrCode(1,term1,"");  
    }

    int freeReg = getFloat();
    string temp = "\tmtc1 $" + term1.substr(1) + ", $f" + to_string(freeReg);
    genMipsCode(temp);
    temp = "\tcvt.s.w $f" + to_string(freeReg) + ", $f" + to_string(freeReg);
    genMipsCode(temp);
    
    int flag2 = checkNameType(term2);

    if(flag2 == 0)
        genVarCode(0,term2,"_f" + to_string(freeReg));
    else if(flag2 == 3){
        genArrCode(0,term2,"_f" + to_string(freeReg));  
    }
    else{
        string temp = "\tmov.s $" + term2.substr(1) + ", $f" + to_string(freeReg);
        genMipsCode(temp);
    }
    freeFloat("_f"+ to_string(freeReg));
}

void convertToInt(string term1,string term2){
    int flag1 = checkNameType(term1);

    if(flag1 == 0)
        term1 = genVarCode(1,term1,"");
    if(flag1 == 3){
        term1 = genArrCode(1,term1,"");  
    }

    int freeReg = getTemp();
    string temp = "\tcvt.w.s $" + term1.substr(1) + ", $" + term1.substr(1);
    genMipsCode(temp);
    temp = "\tmfc1 $t" + to_string(freeReg) + ", $" + term1.substr(1);
    genMipsCode(temp);
    
    int flag2 = checkNameType(term2);

    if(flag2 == 0)
        genVarCode(0,term2,"_t" + to_string(freeReg));
    else if(flag2 == 3){
        genArrCode(0,term2,"_t" + to_string(freeReg));  
    }
    else{
        string temp = "\tmove $" + term2.substr(1) + ", $t" + to_string(freeReg);
        genMipsCode(temp);
    }
    freeFloat("_t"+ to_string(freeReg));
}

void pushParam(int flag,string name){
    if(flag==0){
        int pos = checkVarPos(name);
        int freeReg = getTemp();
        string temp = "\tlw $t"  + to_string(freeReg) +   ", " + to_string(pos+ 4*paramCount) + "($sp)";
        genMipsCode(temp);
        temp.clear();

        temp = "\taddi\t$sp,$sp, -4";
        genMipsCode(temp);
        temp.clear();
        temp = "\tsw $t" + to_string(freeReg) +   ", 0($sp)";
        genMipsCode(temp);
        tempNames[freeReg]=0;
    }
    else if(flag==1){
        
        string temp = "\taddi\t$sp,$sp, -4";
        genMipsCode(temp);
        temp.clear();

        temp = "\tsw $" + name.substr(1) + ", 0($sp)";
        genMipsCode(temp);
        freeTemp(name);
    
    }
    else{
        string temp = "\taddi\t$sp,$sp, -4";
        genMipsCode(temp);
        temp.clear();

        temp = "\tswc1 $" + name.substr(1) + ", 0($sp)";
        genMipsCode(temp);
        freeFloat(name);
    }

    paramCount++;
}


void oprTerm(string term1, string term2, string term3, string opr){  

    int flag1 = checkNameType(term1);
    int flag2 = checkNameType(term2);
    int flag3 = checkNameType(term3);

    string reg2, reg3;

    if(flag1 == 1 || flag1 == 2)
        assignReg(term1);
    if(flag2 == 1 || flag2 == 2)
        assignReg(term2);
    if(flag3 == 1 || flag3 == 2)
        assignReg(term3);

    if(flag2 == 0)
        term2 = genVarCode(1,term2,"");
    if(flag3 == 0)
        term3 = genVarCode(1,term3,"");                                                       

    if(flag2 == 3){
        term2 = genArrCode(1,term2,"");  
    }
    if(flag3 == 3){
        term3 = genArrCode(1,term3,"");  
    }

    if(flag1 == 0 || flag1 == 3){
        string type;
        if(flag1 == 0)
            type = regType(term1);
        else{
            string tempName;
            tempName = term1.substr(0, term1.find("["));  
            type = regType(tempName);
        }
        string s;
        int newReg;
        if(type == "t"){
            s = "";
            newReg = getTemp();
        }
        else{
            s = ".s"; 
            newReg = getFloat();
        }
        string tmp = "\t" + opr + s + " $" + type + to_string(newReg) + ", $" + term2.substr(1) + ", $" + term3.substr(1) ;
        genMipsCode(tmp); 

        if(flag1 == 0){
            string reg1 = genVarCode(0,term1,type + to_string(newReg));  
            freeReg(type, newReg);
        }
        else{
            string reg1 = genArrCode(0,term1,type + to_string(newReg));  
            freeReg(type, newReg);
        }
    }

    if(flag1 == 1 || flag1 == 2){
        string s;
        if(flag1 == 1)
            s = "";
        else
            s = ".s"; 

        assignReg(term1);
        string tmp = "\t" + opr + s + " $" + term1.substr(1) + ", $" + term2.substr(1) + ", $" + term3.substr(1) ;
        genMipsCode(tmp); 
    }
    freeReg(term2.substr(1,1), stoi(term2.substr(2)));
    freeReg(term3.substr(1,1), stoi(term3.substr(2)));
}

void eqTerm(string term1, string term2){
    int flag1 = checkNameType(term1);
    int flag2 = checkNameType(term2);

    string reg2, reg3;

    if(flag1 == 1 || flag1 == 2)
        assignReg(term1);
    if(flag2 == 1 || flag2 == 2)
        assignReg(term2);

    if(flag2 == 0)
        term2 = genVarCode(1,term2,"");

    if(flag2 == 3){
        term2 = genArrCode(1,term2,"");  
    }

    if(flag1 == 0 || flag1 == 3){
        string type;
        if(flag1 == 0)
            type = regType(term1);
        else{
            string tempName;
            tempName = term1.substr(0, term1.find("["));  
            type = regType(tempName);
        }
        string s;
        int newReg;
        if(type == "t"){
            s = "e";
            newReg = getTemp();
        }
        else{
            s = ".s"; 
            newReg = getFloat();
        }
        string tmp = "\tmov"  + s + " $" + type + to_string(newReg) + ", $" + term2.substr(1) ;
        genMipsCode(tmp); 
        if(flag1 == 0){
            string reg1 = genVarCode(0,term1,type + to_string(newReg));  
            freeReg(type, newReg);
        }
        else{
            string reg1 = genArrCode(0,term1,type + to_string(newReg));  
            freeReg(type, newReg);
        }

    }

    if(flag1 == 1 || flag1 == 2){
        string s;
        if(flag1 == 1)
            s = "e";
        else
            s = ".s"; 

        assignReg(term1);
        string tmp = "\tmov" + s + " $" + term1.substr(1) + ", $" + term2.substr(1) ;
        genMipsCode(tmp); 
    }

    freeReg(term2.substr(1,1), stoi(term2.substr(2)));
}

int main()
{   
    
    genMipsCode("\t.data");
    string line;
    /* To load variables and there mapping*/
    
    line.clear();
    ifstream myfile2 ("localVar.txt");
    if (myfile2.is_open())
    {
        while ( getline (myfile2,line) )
        {
            string sName1 = line;
            line.clear();
            getline (myfile2,line);
            string sOff1 = line;
            line.clear();
            getline (myfile2,line);
            string sType1 = line;
            line.clear();
            varName.push_back(sName1);
            varOffset.push_back(sOff1);
            varType.push_back(sType1);
        }
    }

    line.clear();
    ifstream myfile3 ("globalVar.txt");
    if (myfile3.is_open())
    {
        while ( getline (myfile3,line) )
        {
            string sName1 = line;
            line.clear();
            getline (myfile3,line);
            string sType1 = line;
            line.clear();
            string sSize;
            if(sType1.size()>6){
                if(sType1.substr(sType1.size()-6)=="_array"){
                    line.clear();
                    getline (myfile3,line);
                    sSize = line;
                }
            }
            else{
                sSize = "4";
            }
            gloVarName.push_back(sName1);
            gloVarType.push_back(sType1);
            gloVarSize.push_back(sSize);
        }
    }

    string temp = "\n";
    for(int i =0;i<gloVarName.size();i++){
        temp.clear(); 
        if(gloVarType[i].size()>6){
            if(gloVarType[i].substr(gloVarType[i].size()-6)=="_array"){
                temp = "\t\t" + gloVarName[i] + ":\t.space\t" + gloVarSize[i];
            }
        }
        else{
            string type1;
            if(gloVarType[i]=="int") type1 = "word";
            else type1 = "float";
            temp = "\t\t" + gloVarName[i] + ":\t." + type1 + "\t0" ;
            if(gloVarType[i]=="float") temp += ".0";
        }
        genMipsCode(temp);
    }

    temp = "\n";
    genMipsCode(temp);
    temp.clear(); 
    temp = "\t.text\n";
    genMipsCode(temp);
    temp.clear();
    temp = "\t.globl main\n";
    genMipsCode(temp);

    yyparse();
    for(auto x:mipCode){
        cout<<x<<endl;
    }
    return 1;
}