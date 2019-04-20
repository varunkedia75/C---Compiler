%{
#pragma GCC diagnostic ignored "-Wwrite-strings"
	
	#include "header.h"
	using namespace std;
	extern int yylex();
	extern int yylineno;
	extern char* yytext;
	extern FILE* yyout;
	int yyerror(char *s);
	
	vector<struct varSymbolTableEntry*>globalTableEntry;
	vector<struct fnNameTableEntry*>globalFuncTable; 
	vector<int>typeList;
	int scope=0;
	int activeFuncPtr = 0;
	int callNamePtr = -1;
	bool error=false;
	int paramPos = 0;
	int passedParam=0;
	bool funcRedecFlag = false;
	string redecFuncName;
	bool returnFlag = false;
	int nextQuad=0;
	vector<string>interCode;
	int tempCount=0;
	vector<string> delay;

%}

%union{
	struct variableStruct variables;
	struct attrb1Struct attrb1;
	int intType;
	float floatType; 
}


%start  code

%token <attrb1> INT_LIT
%token <attrb1> FLOAT_LIT
%token <attrb1> STR DEFAULT

%token <attrb1>  LT_EQ GT_EQ LT GT EQ_EQ NOT_EQ PLUS MINUS MULTI DIV POW AMP HASH HEADER RETURN BREAK CONTINUE AND OR NOT ASSIGN COMMA O_SB C_SB CP OP O_CURLY C_CURLY DOT SEMI COLON FOR WHILE IF ELSE SWITCH CASE PRINTF SCANF DQ  EF INT FLOAT INCR DECR PLUS_ASS MINUS_ASS MULT_ASS DIV_ASS

%type <attrb1> VAR_DEC  DEC DTYPE DIMLIST EXP TERM ELIST EXP1
%type <attrb1>LEFT ID AR_OP REL_OP LOG_OP OPR ASS  IFELSE-STAT IFELSE WHILE-STAT WHILE_EXP EXP_LIST EXP_LI FOR-STAT FOR_EXP FUNC_DECL FUNC_HEAD DECL_PLIST DECL_PARAM RES_ID DECL_PL FUNC_DEF PLIST PARAMLIST FUNC_CALL SWITCH_STMT CASE_LIST CASE_STMT DEF_STMT INC_DEC
%type <attrb1> VARLIST ID_ARR ASS_OP

%left PLUS_ASS MINUS_ASS
%right NOT  
%left MULT DIV
%left PLUS MINUS
%right ASSIGN

%%

code:		stmtList 
			;

stmtList:	/*empty*/
			| stmt stmtList 		
			;

stmt:		HASH HEADER 				{ printf("HEADER\n");}
			| VAR_DEC SEMI      		{ printf("VAR_DEC\n");}
			| ASS SEMI 	  				{ 
											if(delay.size()!=0){
												for(int i=0;i<delay.size();i++){
													genCode(delay[i]);
												}
												delay.clear();
											}
											printf("ASS\n");
										}
			| IFELSE-STAT   			{ printf("IF_ELSE\n"); }
			| WHILE-STAT				{ printf("While\n");}
			| FOR-STAT					{ printf("For\n");}
			| FUNC_DECL	SEMI			{ 
											if(funcRedecFlag==1){
												cout<<"ReDeclaration of function "<<redecFuncName<<endl;
												error=1;
												funcRedecFlag=0;
												redecFuncName.clear();
											}
											printf("Function Declaration\n");
										}

			| FUNC_DEF					{ printf("Function Defination\n");}
			| SWITCH_STMT				{ printf("Switch\n");}
			| O_CURLY  { scope++;}  stmtList C_CURLY	{ printf("Block \n"); scope--;}	
			| BREAK SEMI 				{ printf("Break \n");}
			| CONTINUE SEMI				{ printf("Continue \n");}
			| RETURN EXP SEMI			{ printf("Return\n"); returnFlag = true; }
			| SEMI						{ printf("Semi\n");}
			| error SEMI   				{ printf("Error\n");}
			;


/******************************************* VARIABLE DECLARATION **************************************************/


VAR_DEC:   DEC  							
			;

DEC : 		DTYPE VARLIST					{ patchtype($1.type,typeList,activeFuncPtr); typeList.clear(); /* printList($2);*/}
			;
			
DTYPE : 	INT 							{  string temp = "int"; $$.type = new string(temp);}
			| FLOAT 						{  string temp = "float"; $$.type = new string(temp);}
			;

VARLIST :	ID_ARR 					
			| ID_ARR COMMA VARLIST 			
			| ID ASSIGN EXP COMMA VARLIST   { 	
												int position;
												if(searchVar($1.name,activeFuncPtr,scope,position)){
													cout<<"Variable already declared at the same level"<<endl;
													error =	true;
												}
												else if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
													cout<<"Redeclaration of Parameter as Variable"<<endl;
													error =	true;
												}
												else{
													int index = insertVarSymTab($1.name,activeFuncPtr); 
													cout<<index<<endl; 
													typeList.push_back(index);
													string temp = "t" + to_string(tempCount) + "=" + $3.name[0];
													genCode(temp);
													temp.clear();
													temp = globalFuncTable[activeFuncPtr]->varTable[index]->name + " = " + "t" + to_string(tempCount);
													genCode(temp);
													globalFuncTable[activeFuncPtr]->varTable[index]->tempVar = tempCount;
													tempCount++;
												}
											}
			
			| ID ASSIGN EXP 				{ 
												int position;
												if(searchVar($1.name,activeFuncPtr,scope,position)){
													cout<<"Variable already declared at the same level"<<endl;
													error =	true;
												}
												/*makelist*/
												else if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
													cout<<"Redeclaration of Parameter as Variable"<<endl;
													error =	true;
												}
												else{
													int index = insertVarSymTab($1.name,activeFuncPtr); 
													cout<<index<<endl; 
													typeList.push_back(index);
													string temp = "t" + to_string(tempCount) + "=" + $3.name[0];
													genCode(temp);
													temp.clear();
													temp = globalFuncTable[activeFuncPtr]->varTable[index]->name + " = " + "t" + to_string(tempCount);
													genCode(temp);
													globalFuncTable[activeFuncPtr]->varTable[index]->tempVar = tempCount;
													tempCount++;
												}
											}
			;


ID_ARR :    ID  							{ 	
												int position;
												if(searchVar($1.name,activeFuncPtr,scope,position)){
													cout<<"Variable already declared at the same level"<<endl;
													error =	true;
												}
												/*makelist*/
												else if((scope == 2) && searchParam($1.name,activeFuncPtr,position)){
													cout<<"Redeclaration of Parameter as Variable"<<endl;
													error =	true;
												}
												else{
													int index = insertVarSymTab($1.name,activeFuncPtr); cout<<index<<endl; typeList.push_back(index);
													error =	false;
												}
											}

										    /*Array Declaration only*/
			| ID DIMLIST 					{}
			;

ID : 		STR 							{$$.name = $1.name;}
			/*| MULTI ID*/		 
			;

DIMLIST :   O_SB INT_LIT C_SB
			| O_SB INT_LIT C_SB DIMLIST
			;



/**************************************************** EXP **********************************************************/

EXP : 		EXP1 OPR EXP 			{	
										if($1.type[0]=="errorType" || $3.type[0]=="errorType")
											$$.type = new string("errorType");
										else{ 
											$$.type = $1.type;
											cout<<$1.name[0]<<" "<<$3.name[0]<<endl;
											string temp = "t" + to_string(tempCount) + " = " + $1.name[0] + $2.name[0] + $3.name[0];
											genCode(temp);
											$$.name = new string("t"+to_string(tempCount));
											tempCount++;	
										}								
									}
			
			| EXP1					{
										if($1.type[0]=="errorType")
											$$.type = new string("errorType");
										else {
											$$.type = $1.type;
											$$.name = $1.name;
										}
									}						
			;

EXP1: 		TERM					{ $$.type = $1.type; $$.name = $1.name;}
			| OP EXP CP				{ $$.type = $2.type; }
			| NOT EXP1				{ $$.type = $2.type; }
			;

OPR: 		AR_OP					{ $$.name = $1.name;}
			| LOG_OP				{ $$.name = $1.name;}
			| REL_OP				{ $$.name = $1.name;}
			;

AR_OP :		PLUS 					{ $$.name = $1.name;}
			| MINUS 				{ $$.name = $1.name;}
			| MULTI 				{ $$.name = $1.name;}
			| DIV					{ $$.name = $1.name;}
			| POW					{ $$.name = $1.name;}
			;

LOG_OP :	AND 					{ $$.name = $1.name;}
			| OR					{ $$.name = $1.name;}
			;

REL_OP :	LT						{ $$.name = $1.name;}
			| GT					{ $$.name = $1.name;}
			| LT_EQ					{ $$.name = $1.name;}
			| GT_EQ					{ $$.name = $1.name;}
			| EQ_EQ					{ $$.name = $1.name;}
			| NOT_EQ				{ $$.name = $1.name;}
			;

TERM :		ID 						{
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
													if(globalFuncTable[0]->varTable[position]->tempVar==-1){
													 int tempVar = assignName(position,0,1,$$.name);
													 $$.name = new string("t"+to_string(tempVar));
													}
													else{
														$$.name = new string("t" + to_string(globalFuncTable[0]->varTable[position]->tempVar));
													}
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
												if(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar==-1){
													int tempVar = assignName(position,activeFuncPtr,0,$$.name);
													$$.name = new string("t"+to_string(tempVar));
												}
												else{
													$$.name = new string("t" + to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->tempVar));
												}
											}
											else {
												$$.type = &(globalFuncTable[activeFuncPtr]->varTable[position]->type);
												if(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar==-1){
													int tempVar = assignName(position,activeFuncPtr,1,$$.name);
													$$.name = new string("t"+to_string(tempVar));
												}
												else{
													$$.name = new string("t" + to_string(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar));
												}
											}
										}
									}
			
			| INT_LIT				{ 
										$$.type = new string("int");
										string temp = "t"+to_string(tempCount) + " = " + $1.name[0];
										genCode(temp);
										$$.name = new string("t"+to_string(tempCount)); 
										tempCount++;
									}			
			| FLOAT_LIT				{ 
										$$.type = new string("float");
										string temp = "t" + to_string(tempCount)+" = " + $1.name[0];
										genCode(temp);
										$$.name = new string("t"+to_string(tempCount)); 
										tempCount++;
									}
			| ARR					
			| FUNC_CALL 			{ $$.type = $1.type; }

			| ID INC_DEC			{
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
													if(globalFuncTable[0]->varTable[position]->tempVar==-1){
													 	int tempVar = assignName(position,0,1,$$.name);
														$$.name = new string("t"+to_string(tempVar));
														string s;
														s.push_back(' ');
														s.push_back($2.name[0][0]);
														s.push_back(' ');
														s.push_back('1');
                                                        string temp = "t" + to_string(tempVar) + " = " + "t" + to_string(tempVar)+ s;
                                                        delay.push_back(temp);
                                                        string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar);
                                                        delay.push_back(temp1);

													}
													else{
														$$.name = new string("t" + to_string(globalFuncTable[0]->varTable[position]->tempVar));
														int tempVar1 = globalFuncTable[0]->varTable[position]->tempVar;
														string s;
														s.push_back(' ');
														s.push_back($2.name[0][0]);
														s.push_back(' ');
														s.push_back('1');
                                                        string temp = "t" + to_string(tempVar1) + " = " + "t" + to_string(tempVar1) + s;
                                                        delay.push_back(temp);
                                                        string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar1);
                                                        delay.push_back(temp1);
													}
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
												if(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar==-1){
													int tempVar = assignName(position,activeFuncPtr,0,$$.name);
													$$.name = new string("t"+to_string(tempVar));
													string s;
													s.push_back(' ');
													s.push_back($2.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
                                                    string temp = "t" + to_string(tempVar)+" = " + "t" + to_string(tempVar)+ s;
                                                    delay.push_back(temp);
                                                    string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar);
                                                    delay.push_back(temp);
												}
												else{
													$$.name = new string("t" + to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->tempVar));
													int  tempVar1 = globalFuncTable[activeFuncPtr]->varTable[position]->tempVar;
													string s;
													s.push_back(' ');
													s.push_back($2.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
                                                    string temp = "t" + to_string(tempVar1) + " = " + "t" + to_string(tempVar1) + s;
                                                    delay.push_back(temp);
                                                    string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar1);
                                                    delay.push_back(temp1);
												}
											}
											else {
												$$.type = &(globalFuncTable[activeFuncPtr]->varTable[position]->type);
												if(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar==-1){
													int tempVar = assignName(position,activeFuncPtr,1,$$.name);
													$$.name = new string("t"+to_string(tempVar));
													string s;
													s.push_back(' ');
													s.push_back($2.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
                                                    string temp = "t" + to_string(tempVar)+" = " + "t" + to_string(tempVar)+ s;
                                                    delay.push_back(temp);
                                                    string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar);
                                                    delay.push_back(temp1);
												}
												else{
													$$.name = new string("t" + to_string(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar));
													int tempVar1 = globalFuncTable[activeFuncPtr]->varTable[position]->tempVar;
													string s;
													s.push_back(' ');
													s.push_back($2.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
                                                    string temp = "t" + to_string(tempVar1) + " = " + "t" + to_string(tempVar1) + s;
                                                    delay.push_back(temp);
                                                    string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar1);
                                                    delay.push_back(temp1);
												}
											}
										}
									}
			
			| INC_DEC ID			{
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
													if(globalFuncTable[0]->varTable[position]->tempVar==-1){
													 	int tempVar = assignName(position,0,1,$$.name);
														$$.name = new string("t"+to_string(tempVar));
														string s;
														s.push_back(' ');
														s.push_back($1.name[0][0]);
														s.push_back(' ');
														s.push_back('1');
                                                        string temp = "t" + to_string(tempVar) + " = " + "t" + to_string(tempVar)+ s;
                                                        genCode(temp);
                                                        string temp1 = $2.name[0] + " = " + "t" + to_string(tempVar);
                                                        genCode(temp1);
													}
													else{
														$$.name = new string("t" + to_string(globalFuncTable[0]->varTable[position]->tempVar));
														int tempVar1 = globalFuncTable[0]->varTable[position]->tempVar;
														string s;
														s.push_back(' ');
														s.push_back($1.name[0][0]);
														s.push_back(' ');
														s.push_back('1');
                                                        string temp = "t" + to_string(tempVar1) + " = " + "t" + to_string(tempVar1) + s;
                                                        genCode(temp);
                                                        string temp1 = $2.name[0] + " = " + "t" + to_string(tempVar1);
                                                        genCode(temp1);
													}
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
												if(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar==-1){
													int tempVar =  assignName(position,activeFuncPtr,0,$$.name);
													$$.name = new string("t"+to_string(tempVar));
													string s;
													s.push_back(' ');
													s.push_back($1.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
                                                    string temp = "t" + to_string(tempVar)+" = " + "t" + to_string(tempVar)+ s;
                                                    genCode(temp);
                                                    string temp1 = $2.name[0] + " = " + "t" + to_string(tempVar);
                                                    genCode(temp1);
												}
												else{
													$$.name = new string("t" + to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->tempVar));
													int  tempVar1 = globalFuncTable[activeFuncPtr]->varTable[position]->tempVar;
													string s;
													s.push_back(' ');
													s.push_back($1.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
                                                    string temp = "t" + to_string(tempVar1) + " = " + "t" + to_string(tempVar1) + s;
                                                    genCode(temp);
                                                    string temp1 = $2.name[0] + " = " + "t" + to_string(tempVar1);
                                                    genCode(temp1);
												}
											}
											else {
												$$.type = &(globalFuncTable[activeFuncPtr]->varTable[position]->type);
												if(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar==-1){
													int tempVar = assignName(position,activeFuncPtr,1,$$.name);
													$$.name = new string("t"+to_string(tempVar));
													string s;
													s.push_back(' ');
													s.push_back($1.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
                                                    string temp = "t" + to_string(tempVar)+" = " + "t" + to_string(tempVar)+ s;
                                                    genCode(temp);
                                                    string temp1 = $2.name[0] + " = " + "t" + to_string(tempVar);
                                                    genCode(temp1);
												}
												else{
													$$.name = new string("t" + to_string(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar));
													int tempVar1 = globalFuncTable[activeFuncPtr]->varTable[position]->tempVar;
													string s;
													s.push_back(' ');
													s.push_back($1.name[0][0]);
													s.push_back(' ');
													s.push_back('1');
                                                    string temp = "t" + to_string(tempVar1) + " = " + "t" + to_string(tempVar1) + s;
                                                    genCode(temp);
                                                    string temp1 = $2.name[0] + " = " + "t" + to_string(tempVar1);
                                                    genCode(temp1);
												}
											}
										}
									}
			;

INC_DEC :	INCR					{ $$.name = $1.name;}
			| DECR					{ $$.name = $1.name;}
			;

ARR : 		ELIST C_SB
			;

ELIST :		ID O_SB EXP				{ }		
			| ELIST C_SB O_SB EXP
			;

/**************************************************ASSIGNMENTS**********************************************************/


ASS : 		LEFT ASS 				{ 
											if($1.type[0] == $2.type[0]){
												$$.type = $1.type;
												cout<<$1.name[0]<<" "<<$2.name[0]<<endl;
												int* flag = codeGenAssign($$.name,$1.name,$2.name);
												if(flag!=NULL){
													*flag = tempCount++;
												}
												$$.name = $2.name;
											}
											else{
												if($1.type[0]!="errorType" && $1.type[0]!="errorType" ) cout<<"Type mismatch\n";
												$$.type = new string("errorType");
											}
									}

			| EXP					{ 	
										$$.type = $1.type;
										$$.name = $1.name;}

			| ID ASS_OP EXP 		{
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
													if(globalFuncTable[0]->varTable[position]->tempVar==-1){
													 	int tempVar = assignName(position,0,1,$$.name);
														$$.name = new string("t"+to_string(tempVar));
														string s(1,$2.name[0][0]);
                                                        string temp = "t" + to_string(tempVar) + " = " + "t" + to_string(tempVar)+ s + $3.name[0];
                                                        genCode(temp);
                                                        string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar);
                                                        genCode(temp1);
													}
													else{
														$$.name = new string("t" + to_string(globalFuncTable[0]->varTable[position]->tempVar));
                                                        int tempVar1 = globalFuncTable[0]->varTable[position]->tempVar;
														string s(1,$2.name[0][0]);
                                                        string temp = "t" + to_string(tempVar1) + " = " + "t" + to_string(tempVar1) + s + $3.name[0];
                                                        genCode(temp);
                                                        string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar1);
                                                        genCode(temp1);
													}
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
													if(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar==-1){
														int tempVar = assignName(position,activeFuncPtr,0,$$.name);
														$$.name = new string("t"+to_string(tempVar));
														string s(1,$2.name[0][0]);
                                                        string temp = "t" + to_string(tempVar)+" = " + "t" + to_string(tempVar)+ s + $3.name[0];
                                                        genCode(temp);
                                                        string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar);
                                                        genCode(temp1);
													}
													else{
														$$.name = new string("t" + to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->tempVar));
                                                        int  tempVar1 = globalFuncTable[activeFuncPtr]->varTable[position]->tempVar;
														string s(1,$2.name[0][0]);
                                                        string temp = "t" + to_string(tempVar1) + " = " + "t" + to_string(tempVar1) + s + $3.name[0];
                                                        genCode(temp);
                                                        string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar1);
                                                        genCode(temp1);
													}
												}
												else {
													type = (globalFuncTable[activeFuncPtr]->varTable[position]->type);
													if(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar==-1){
														int tempVar = assignName(position,activeFuncPtr,1,$$.name);
														$$.name = new string("t"+to_string(tempVar));
														string s(1,$2.name[0][0]);
                                                        string temp = "t" + to_string(tempVar)+" = " + "t" + to_string(tempVar)+ s + $3.name[0];
                                                        genCode(temp);
														
                                                        string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar);
                                                        genCode(temp1);
													}
												else{
													$$.name = new string("t" + to_string(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar));
													int tempVar1 = globalFuncTable[activeFuncPtr]->varTable[position]->tempVar;
													string s(1,$2.name[0][0]);
                                                    string temp = "t" + to_string(tempVar1) + " = " + "t" + to_string(tempVar1) + s + $3.name[0];
                                                    genCode(temp);
                                                    string temp1 = $1.name[0] + " = " + "t" + to_string(tempVar1);
                                                    genCode(temp1);
												}
											}
												
												if($3.type[0] != type){
													cout<<"Type mismatch\n";
													$$.type = new string("errorType");
													error=1;
												}	
												else{
													$$.type = &type;
												}
											}
									}
			;



LEFT :		ID ASSIGN 				{
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
													$$.name = new string("01"+ to_string(position));
												}
												else{
													cout<<"Identifier "<<$1.name[0]<<" Not Declared"<<endl;
													$$.type = new string("errorType");
													error = true;
												}
											}
											else{
												if(found==1){
													$$.type = &(globalFuncTable[activeFuncPtr]->paramTable[position]->type);
													$$.name = new string("10"+ to_string(position));
													
												}
												else{
													$$.type = &(globalFuncTable[activeFuncPtr]->varTable[position]->type);
													$$.name = new string("11"+ to_string(position));
													
												}
									
											}
										
									}
			;	

ASS_OP :    PLUS_ASS				{ $$.name = $1.name;}
			| MINUS_ASS				{ $$.name = $1.name;}
			| MULT_ASS				{ $$.name = $1.name;}
			| DIV_ASS				{ $$.name = $1.name;}
			;		



/**************************************************** IF-ELSE  **********************************************************/


IFELSE-STAT : IFELSE stmt ELSE stmt
			| IFELSE stmt
			;

IFELSE :	IF OP ASS CP
			; 


/**************************************************** SWITCH  ***********************************************************/


SWITCH_STMT: SWITCH OP ASS CP O_CURLY CASE_LIST DEF_STMT C_CURLY 
			;

CASE_LIST : /*empty*/
			| CASE_STMT CASE_LIST
			;

DEF_STMT :	/*empty*/
			| DEFAULT COLON stmtList
			;

CASE_STMT : CASE VAL1 COLON stmtList
			;

VAL1 : 		INT_LIT
			;			 


/*************************************************** WHILE-LOOP ********************************************************/


WHILE-STAT :WHILE_EXP stmt
		    ;

WHILE_EXP : WHILE OP ASS CP
			;


/**************************************************** FOR-LOOP **********************************************************/


FOR-STAT :  FOR_EXP stmt
		    ;

FOR_EXP : 	FOR OP EXP_LIST SEMI EXP_LIST SEMI EXP_LIST CP
			;

EXP_LIST : 	/*empty*/
			| EXP_LI 

EXP_LI : 	ASS COMMA EXP_LI
			| ASS
			;


/**************************************************** FUNCTION_DEC ********************************************************/


FUNC_DECL : FUNC_HEAD 					
			;

FUNC_HEAD : RES_ID OP DECL_PLIST CP			{	scope=2;    }
			;


RES_ID :	DTYPE ID						{	
												int position; 
												bool found=searchFuncEntry($2.name,position);
												if(found){
													funcRedecFlag = true;
													redecFuncName = $2.name[0];
												}
												else{
													position = insertFuncTab($2.name,$1.name);
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
												if(found){
													cout<<"Redefinition of parameter "<<$2.name[0]<<"\n";
													error=true;
												}
												else{
													insertParam($2.name,$1.name,activeFuncPtr);
												}
											}
			| DTYPE ID O_SB C_SB
			| DTYPE ID O_SB INT_LIT C_SB
			;


/**************************************************** FUNCTION_DEF **********************************************************/


FUNC_DEF : FUNC_DECL O_CURLY stmtList C_CURLY	{
													scope=0;
													if(funcRedecFlag==1 ){
														if(globalFuncTable[activeFuncPtr]->fnDec){
															globalFuncTable[activeFuncPtr]->fnDec = 0;
														}
														else{
															cout<<"Redefinition of function "<<redecFuncName<<endl;
															error=1;
														}
													}

													if(returnFlag == false){
														cout<<"Return type required\n";
														error = true;
													}
													returnFlag = false;
													funcRedecFlag=0;
													redecFuncName.clear();
													deleteVarList(activeFuncPtr);
													activeFuncPtr=0;
												}
			;


/**************************************************** FUNCTION_CALL **********************************************************/


FUNC_CALL: ID 							{
											int position; 
											bool found=searchFuncEntry($1.name,position);
											if(!found){
												cout<<"Undefined reference to function "<<$1.name[0]<<endl;
												error = 1;
											}
											else{
												callNamePtr = position;
											}
 										} 

			OP PARAMLIST CP				{	
										
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
												}
											}
											else
												$$.type = new string("errorType"); 
											paramPos=0;
											passedParam=0;
											callNamePtr = -1;
										}
			;

PARAMLIST: PLIST							
			| /*empty*/
			;

PLIST: 	EXP									{
												
												int paramCnt = globalFuncTable[callNamePtr]->cntParam;
												paramPos=paramCnt-1;
												if(paramPos>=0){
													bool correct =checkParamType(paramPos,$1.type,callNamePtr);
													passedParam++;
													if(!correct){
														cout<<"Type mismatch for parameter\n";
														error=true;
													}
												}
	
												paramPos--;
											}

			| EXP COMMA PLIST				{
												int paramCnt = globalFuncTable[callNamePtr]->cntParam;
												if(paramPos>=0){
													bool correct = checkParamType(paramPos,$1.type,callNamePtr);
													passedParam++;
													if(!correct){
														cout<<"Type mismatch for parameter\n";
														error=true;
													}
												}
												paramPos--;
											}
			;


/*****************************************************************************************************************************/

%%


int yyerror(char* s)
{
	
}

int insertVarSymTab(string* name,int activeFuncPtr){
	struct varSymbolTableEntry* tmp = (struct varSymbolTableEntry*)malloc(sizeof(struct varSymbolTableEntry));
	tmp->name = name[0];
	tmp->eleType = 0;
	tmp->scope = scope;
	tmp->tag = 0;
	tmp->tempVar =-1;

	int index = globalFuncTable[activeFuncPtr]->varTable.size();
	globalFuncTable[activeFuncPtr]->varTable.push_back(tmp);
	return index;
}


void insertParam(string* name,string* type,int activeFuncPtr){
	struct varSymbolTableEntry* tmp = (struct varSymbolTableEntry*)malloc(sizeof(struct varSymbolTableEntry));
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
	struct fnNameTableEntry* tmp = (struct fnNameTableEntry*)malloc(sizeof(struct fnNameTableEntry));
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

int assignName(int position,int activeFuncPtr,int flag,string* name){
	if(flag==1){
			string temp = "t" + to_string(tempCount) + " = " + to_string(1000001);
			genCode(temp);
			temp.clear();
			temp = globalFuncTable[activeFuncPtr]->varTable[position]->name + " = " + "t" + to_string(tempCount);
			genCode(temp);
			globalFuncTable[activeFuncPtr]->varTable[position]->tempVar = tempCount;
			tempCount++;
			return (tempCount-1);
	}
	else{
			string temp = "t" + to_string(tempCount) + " = " + to_string(1000001);
			genCode(temp);
			temp.clear();
			temp = globalFuncTable[activeFuncPtr]->paramTable[position]->name + " = " + "t" + to_string(tempCount);
			genCode(temp);
			globalFuncTable[activeFuncPtr]->paramTable[position]->tempVar = tempCount;
			tempCount++;
			return (tempCount-1); 
	}
}


// void assignNameLeft(int position,int activeFuncPtr,int flag,string* name){
// 	if(flag==1){
// 		if(activeFuncPtr==0) name = new string("01"+ to_string(position));
// 		else name = new string("11"+ to_string(position));
// 	}
// 	else{
// 		name = new string("10"+ to_string(position));	
// 	}
// 	cout<<"ssds "<<endl;
// 	cout<<name[0]<<endl;
// }



int* codeGenAssign(string* name,string* lhs,string* rhs){
	if(lhs[0][0]=='0'){
		string temp = lhs[0].substr(2);
		int position = stoi(temp);
		if(globalFuncTable[0]->varTable[position]->tempVar == -1){
			temp =  "t" + to_string(tempCount) + " = " + rhs[0];
			genCode(temp);
			temp.clear();
			string temp = globalFuncTable[0]->varTable[position]->name + " = " + "t" + to_string(tempCount);
			genCode(temp);
			return &globalFuncTable[0]->varTable[position]->tempVar;
		}
		else{
			string temp = "t" +  to_string(globalFuncTable[0]->varTable[position]->tempVar) + " = " + rhs[0];
			genCode(temp);
			temp.clear();
			temp = globalFuncTable[0]->varTable[position]->name + " = " + "t" + to_string(globalFuncTable[0]->varTable[position]->tempVar);
			genCode(temp);
		}
	}
	else{
		if(lhs[0][1]=='1'){
			string temp = lhs[0].substr(2);
			int position = stoi(temp);
			if(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar == -1){
				temp =  "t" +  to_string(tempCount) + " = " + rhs[0];
				genCode(temp);
				temp.clear();
				string temp = globalFuncTable[activeFuncPtr]->varTable[position]->name + " = " + "t"+ to_string(tempCount);
				genCode(temp);
				return &globalFuncTable[activeFuncPtr]->varTable[position]->tempVar;
			}
			else{
				string temp = "t" +  to_string(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar) + " = " + rhs[0];
				genCode(temp);
				temp.clear();
				temp = globalFuncTable[activeFuncPtr]->varTable[position]->name + " = " + "t" + to_string(globalFuncTable[activeFuncPtr]->varTable[position]->tempVar);
				genCode(temp);
			}
		}
		else{
			string temp = lhs[0].substr(2);
			int position = stoi(temp);
			if(globalFuncTable[activeFuncPtr]->paramTable[position]->tempVar == -1){
				temp = "t" +  to_string(tempCount) + " = " + rhs[0];
				genCode(temp);
				temp.clear();
				string temp = globalFuncTable[activeFuncPtr]->paramTable[position]->name + " = " +  "t" +  to_string(tempCount);
				genCode(temp);
				return &globalFuncTable[activeFuncPtr]->paramTable[position]->tempVar;

			}
			else{
				string temp = "t" + to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->tempVar) + " = " + rhs[0];
				genCode(temp);
				temp.clear();
				temp = globalFuncTable[activeFuncPtr]->paramTable[position]->name + " = " + "t" + to_string(globalFuncTable[activeFuncPtr]->paramTable[position]->tempVar);
				genCode(temp);
			}
		}
	}
	return NULL;
}



int main()
{
	string* GlobalFnname = new string("global");
	string* returnType = new string("null");
	activeFuncPtr =0;
	insertFuncTab(GlobalFnname,returnType);
	globalFuncTable[activeFuncPtr]->fnDec = false;
	yyparse();

	for(int i=0;i<globalFuncTable[0]->varTable.size();i++){
		cout<<globalFuncTable[0]->varTable[i]->name<<" "<<globalFuncTable[0]->varTable[i]->tempVar<<endl;
	}

	for(int i=0;i<interCode.size();i++){
		cout<<interCode[i]<<endl;
	}
	
	
	return 0;
}









/*

void printList(struct sp* a){
	struct sp* tmp = a;
	while(tmp!=NULL){
		struct varSymbolTableEntry* t = tmp->varTable;
		
		printf("%s ",t->name);
		printf("%s ",t->type);
		
		printf("\n");
		tmp = tmp->next;
	}
}
*/