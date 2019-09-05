#pragma once
#include<bits/stdc++.h>
#include <stdio.h>
#include <string>

using namespace std;

/*******************************************DATA STRUCTURS*********************************************/

struct falseListStruct {
	vector<int>*falseList;
	int begin;
	int incBegin;
	int test;
	string* result;
	string* type;
};

struct attrb1Struct{
  	string* name;
  	string* type;
	vector<int>*dimList;
	vector<int>*continueList;
	vector<int>*breakList;
	vector<int>*shortTrueList;
	vector<int>*shortFalseList;
	int returnQuad;
};

struct varSymbolTableEntry{
		string name;
		string type;
		int  eleType;
		vector<int>dimListPtr;
		int scope;
		int tag;
		int tempVar;
};

struct fnNameTableEntry{
	string name;
	string returnType;
	vector<struct varSymbolTableEntry*>paramTable;
	vector<struct varSymbolTableEntry*>varTable;
	int cntParam;
	bool fnDec ;
};


struct sp{
	struct varSymbolTableEntry*  varTable;
	struct sp* next;
};




/*******************************************FUNCTION DECL*********************************************/

int insertVarSymTab(string* name,int activeFuncPtr, int elemType);
int insertFuncTab(string* name,string* returnType);
void patchtype(string* type ,vector<int>nameList,int activeFuncPtr);
bool searchVar(string* name,int activeFuncPtr,int currScope,int &position);
void deleteVarList(int activeFunPtr);
bool searchFuncEntry(string* name,int &position);
bool searchParam(string* name,int activeFuncPtr,int &position);
void insertParam(string* name,string* type,int activeFuncPtr);
bool checkParamType(int paramPos,string* type,int callNamePtr);
bool checkParamType(int paramPos,string* type,int callNamePtr);
void genCode(string code);
void backPatch(vector<int>*list1,int quad);
vector<int>* catinateList(vector<int>*list1,vector<int>*list2);
int getTemp();
void freeTemp(string name);
void freeFloat(string name);
int  getFloat();
int idSearch(string s);
int getSize(int activeFuncPtr);

/*****************************************************************************************************/
