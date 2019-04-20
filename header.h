#pragma once
#include<bits/stdc++.h>
#include <stdio.h>
#include <string>

using namespace std;

/*******************************************DATA STRUCTURS*********************************************/

struct variableStruct {
	float val;
	string * type;
	
};

struct attrb1Struct{
  	string* name;
  	string* type;
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

int insertVarSymTab(string* name,int activeFuncPtr);
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
int assignName(int position,int activeFuncPtr,int flag,string* name);
int* codeGenAssign(string* name1,string* lhs,string* rhs);