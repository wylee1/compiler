%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define DEBUG	0

#define	 MAXSYM	100
#define	 MAXSYMLEN	20
#define	 MAXTSYMLEN	15
#define	 MAXTSYMBOL	MAXSYM/2

#define STMTLIST 500

typedef struct nodeType {
	int token;
	int tokenval;
	struct nodeType *son;
	struct nodeType *brother;
	} Node;

#define YYSTYPE Node*
	
int tsymbolcnt=0;
int errorcnt=0;

FILE *yyin;
FILE *fp;

extern char symtbl[MAXSYM][MAXSYMLEN];
extern int maxsym;
extern int lineno;

void DFSTree(Node*);
Node * MakeOPTree(int, Node*, Node*);
Node * MakeNode(int, int);
Node * MakeListTree(Node*, Node*);
void codegen(Node* );
void prtcode(int, int);

void	dwgen();
int	gentemp();
void	assgnstmt(int, int);
void	numassgn(int, int);
void	addstmt(int, int, int);
void	substmt(int, int, int);
void	mulstmt(int, int, int);
void	divstmt(int, int, int);
void	modstmt(int, int, int);
int		insertsym(char *);
%}

%token	ADD SUB ASSGN ID NUM STMTEND START END ASSIGNADD ASSIGNSUB ASSIGNMUL ASSIGNDIV MUL DIV DOUBLE DDOUBLE INC DEC

%left ADD SUB
%left MUL DIV


%%
program	: START stmt_list END	{ if (errorcnt==0) {codegen($2); dwgen();} }
		;

stmt_list: 	stmt_list stmt 	{$$=MakeListTree($1, $2);}
		|	stmt			{$$=MakeListTree(NULL, $1);}
		| 	error STMTEND	{ errorcnt++; yyerrok;}
		;

stmt	: 	stmt_expr
		|	stmt_while
		|	stmt_if
		|	stmt_function
		;

stmt_expr	:	ID ASSGN expr_calBasic STMTEND	{ $1->token = ID2; $$=MakeOPTree(ASSGN, $1, $3);}
			|	ID ASSIGNADD expr_calBasic STMTEND {$1->token = ID2; $$=MakeOPTree(ASSIGNADD, $1, $3);}
			|	ID ASSIGNSUB expr_calBasic STMTEND {$1->token = ID2; $$=MakeOPTree(ASSIGNSUB, $1, $3);}
			|	ID ASSIGNMUL expr_calBasic STMTEND {$1->token = ID2; $$=MakeOPTree(ASSIGNMUL, $1, $3);}
			|	ID ASSIGNDIV expr_calBasic STMTEND {$1->token = ID2; $$=MakeOPTree(ASSIGNDIV, $1, $3);}
			|	expr_calBasic
			;
expr_calBasic	:	expr_calBasic ADD expr_calBasic	{ $$=MakeOPTree(ADD, $1, $3); }
				|	expr_calBasic SUB expr_calBasic	{ $$=MakeOPTree(SUB, $1, $3); }
				|	expr_calBasic MUL expr_calBasic	{ $$=MakeOPTree(MUL, $1, $3); }
				|	expr_calBasic DIV expr_calBasic	{ $$=MakeOPTree(DIV, $1, $3); }
				|	expr_calBasic DOUBLE expr_calBasic	{ $$=MakeOPTree(DOUBLE, $1, $3); }
				|	expr_calBasic DDOUBLE expr_calBasic	{ $$=MakeOPTree(DDOUBLE, $1, $3); }
				|	INC term { $$=MakeOPTree(INCREMENT, $2, NULL); }
				|	DEC term { $$=MakeOPTree(DECREMENT, $2, NULL); }
				|	term
				;


term	:	ID		{ $$ = MakeNode(ID, $1); }
		|	NUM		{ $$ = MakeNode(NUM, $1); }
		;


%%
int main(int argc, char *argv[]) 
{
	printf("\nsample CBU compiler v2.0\n");
	printf("(C) Copyright by Jae Sung Lee (jasonlee@cbnu.ac.kr), 2022.\n");
	
	if (argc == 2)
		yyin = fopen(argv[1], "r");
	else {
		printf("Usage: cbu2 inputfile\noutput file is 'a.asm'\n");
		return(0);
		}
		
	fp=fopen("a.asm", "w");
	
	yyparse();
	
	fclose(yyin);
	fclose(fp);

	if (errorcnt==0) 
		{ printf("Successfully compiled. Assembly code is in 'a.asm'.\n");}
}

yyerror(s)
char *s;
{
	printf("%s (line %d)\n", s, lineno);
}


Node * MakeOPTree(int op, Node* operand1, Node* operand2)
{
Node * newnode;

	newnode = (Node *)malloc(sizeof (Node));
	newnode->token = op;
	newnode->tokenval = op;
	newnode->son = operand1;
	newnode->brother = NULL;
	operand1->brother = operand2;
	return newnode;
}

Node * MakeNode(int token, int operand)
{
Node * newnode;

	newnode = (Node *) malloc(sizeof (Node));
	newnode->token = token;
	newnode->tokenval = operand; 
	newnode->son = newnode->brother = NULL;
	return newnode;
}

Node * MakeListTree(Node* operand1, Node* operand2)
{
Node * newnode;
Node * node;

	if (operand1 == NULL){
		newnode = (Node *)malloc(sizeof (Node));
		newnode->token = newnode-> tokenval = STMTLIST;
		newnode->son = operand2;
		newnode->brother = NULL;
		return newnode;
		}
	else {
		node = operand1->son;
		while (node->brother != NULL) node = node->brother;
		node->brother = operand2;
		return operand1;
		}
}

void codegen(Node * root)
{
	DFSTree(root);
}

void DFSTree(Node * n)
{
	if (n==NULL) return;
	DFSTree(n->son);
	prtcode(n->token, n->tokenval);
	DFSTree(n->brother);
	
}

void prtcode(int token, int val)
{
	switch (token) {
	case ID:
		fprintf(fp,"RVALUE %s\n", symtbl[val]);
		break;
	case ID2:
		fprintf(fp, "LVALUE %s\n", symtbl[val]);
		break;
	case NUM:
		fprintf(fp, "PUSH %d\n", val);
		break;
	case ADD:
		fprintf(fp, "+\n");
		break;
	case SUB:
		fprintf(fp, "-\n");
		break;
	case MUL:
		fprintf(fp, "*\n");
		break;
	case DIV:
		fprintf(fp, "/\n");
		break;
	case ASSGN:
		fprintf(fp, ":=\n");
		break;
	case ASSIGNADD:
		fprintf(fp, ":=\n+\n");
		break;
	case ASSIGNSUB:
		fprintf(fp, ":=\n-\n");
		break;
	case ASSIGNMUL:
		fprintf(fp, ":=\n*\n");
		break;
	case ASSIGNDIV:
		fprintf(fp, ":=\n/\n");
		break;
	case DOUBLE:
		fprintf(fp, "PUSH 2\n");
		fprintf(fp, "*\n");
		break;
	case DDOUBLE:
		fprintf(fp, "PUSH 4\n");
		fprintf(fp, "*\n");
		break;
	case INC:
        fprintf(fp, "PUSH 1\n");
        fprintf(fp, "+\n");
        break;
    case DEC:
        fprintf(fp, "PUSH 1\n");
        fprintf(fp, "-\n");
        break;
	case STMTLIST:
	default:
		break;
	};
}


/*
int gentemp()
{
char buffer[MAXTSYMLEN];
char tempsym[MAXSYMLEN]="TTCBU";

	tsymbolcnt++;
	if (tsymbolcnt > MAXTSYMBOL) printf("temp symbol overflow\n");
	itoa(tsymbolcnt, buffer, 10);
	strcat(tempsym, buffer);
	return( insertsym(tempsym) ); // Warning: duplicated symbol is not checked for lazy implementation
}
*/
void dwgen()
{
int i;
	fprintf(fp, "HALT\n");
	fprintf(fp, "$ -- END OF EXECUTION CODE AND START OF VAR DEFINITIONS --\n");

// Warning: this code should be different if variable declaration is supported in the language 
	for(i=0; i<maxsym; i++) 
		fprintf(fp, "DW %s\n", symtbl[i]);
	fprintf(fp, "END\n");
}

