#pragma once
#include<bits/stdc++.h>
#include <stdio.h>
#include <string>

using namespace std;


int checkNameType(string name);
void genCode1(int flag1,int flag2,string name1,string name2);
int checkVarPos(string name);
int genCode2(int flag1,int flag2,int flag3,string name1,string name2,string name3,string operation);
void genMipsCode(string code);
int getTemp();
void freeTemp(string name);
void assignTemp(string name);
void genCode3(int flag1,int flag2,string name1,string name2);
void moveVal(int flag,string name);
void genCode4(int flag1,int flag2,string name1,string name2);
void gencode5(int flag1,int flag2,int flag3,string name1,string name2,string name3);
int  getFloat();
void freeFloat(string name);
void assignFloat(string name);
void convertToFloat(string name1,string name2);
void convertToInt(string name1,string name2);
void genCode6(int flag1,int flag2,string name1,string name2);
void pushParam(int flag,string name);
string checkVarType(string name);
string genVarCode(int flag,string name,string reg);
string genArrCode(int flag,string name,string reg);
string regType(string name);
void freeReg(string type, int pos);
void assignReg(string name);
void oprTerm(string term1, string term2, string term3, string opr);
void eqTerm(string term1, string term2);
