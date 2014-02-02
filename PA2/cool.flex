/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include <string>
#include <sstream>
#include <iostream>
#include <string.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */


std::stringstream strBuf;

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN		<-
LE		<=

%x MULTILINECOMMENT
%x STRING
%x SINGLECOMMENT
%%

 /*
  *  Nested comments
  */
"(*"				{ BEGIN(MULTILINECOMMENT); } 
<MULTILINECOMMENT>\n		{ curr_lineno++; }
<MULTILINECOMMENT><<EOF>>	{ yylval.error_msg="EOF in comment\n";
                                  BEGIN(INITIAL);
				  return ERROR;
                                }
<MULTILINECOMMENT>.		{}
<MULTILINECOMMENT>"*)"		{ BEGIN(INITIAL); }

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{ASSIGN}		{ return ASSIGN; }
{LE}			{ return LE; }


\*			{ return '*'; }
\/			{ return '/'; }
\~			{ return '~'; }
\)			{ return ')'; }
\(			{ return '('; }
\;			{ return ';'; }
\:			{ return ':'; }
\{			{ return '{'; }
\} 			{ return '}'; }
\-			{ return '-'; } 
\+			{ return '+'; }
\=			{ return '='; }
\.			{ return '.'; }
\-			{ return '-'; }
\,			{ return ','; }
\<			{ return '<'; }
\@			{ return '@'; }



 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
[cC][lL][aA][sS][sS]		{ return CLASS; }
[eE][lL][sS][eE]			{ return ELSE; }
[fF][iI]				{ return FI; }
[iI][fF]				{ return IF; } 
[iI][nN]				{ return IN; }
[iI][nN][hH][eE][rR][iI][tT][sS]	{ return INHERITS; }
[lL][eE][tT]			{ return LET; }
[lL][oO][oO][pP]			{ return LOOP; }
[pP][oO][oO][lL]			{ return POOL; }
[tT][hH][eE][nN]			{ return THEN; }
[wW][hH][iI][lL][eE]		{ return WHILE; }
[cC][aA][sS][eE]			{ return CASE; }
[eE][sS][aA][cC]			{ return ESAC; }
[oO][fF]				{ return OF; }
[nN][eE][wW]			{ return NEW; }
[iI][sS][vV][oO][iI][dD]		{ return ISVOID; }

[t][rR][uU][eE]			{ cool_yylval.boolean=1;
                                  return BOOL_CONST;
                                }
f[aA][lL][sS][eE]		{ cool_yylval.boolean=0;
				  return BOOL_CONST;
 				}

 /* 
  * single line comments
  */
--[^\n]*		{ 
			/*printf("singlelinecomment:%s",yytext);*/
			BEGIN(SINGLECOMMENT);
			}

<SINGLECOMMENT><<>EOF>>	{ cool_yylval.error_msg="EOF IN COMMENT\n";
		          BEGIN(INITIAL);
	 		  return ERROR;
                        }
<SINGLECOMMENT>\n	{
                         curr_lineno++;
			 BEGIN (INITIAL);
                        }


[0-9]*		{ cool_yylval.symbol=inttable.add_string(yytext);
                  return INT_CONST;
           	}


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\"	  	{
                  BEGIN(STRING);                 	   	  
		  printf("begin string \n");
                }
<STRING>\\\n	{printf("asdf\n");}
<STRING>\n   	{ 	  
		printf("string newline detected\n");
		cool_yylval.error_msg="Unterminated string constant";
		BEGIN(INITIAL);
 		curr_lineno++;
		return ERROR;
		}

<STRING>[^"\\\n\t\b\f]*	{ 
                  printf("string match slash not \\t\\f\\b\\n \n:%s \n",yytext);
	          strBuf<<yytext;
                  /*std::cout<<"strBuf:"<<strBuf.str()<<"\n";*/
                }
<STRING>[.]*	{printf("match rest\n");}
<STRING>\\0	{
		  printf("null detected in string const");
		  cool_yylval.error_msg="null in string constant\n";
 		  BEGIN(INITIAL);
		  return ERROR;
		}		
<STRING><<EOF>>	{ printf("EOF unterminated string\n");
                  cool_yylval.error_msg="Unterminatd string from EOF\n";
		  BEGIN(INITIAL);
		  return ERROR;
                }
<STRING>\"       {
                  /* test for empty string*/
	    	  printf("detect eos\n");
		  if(strlen(strBuf.str().c_str())==0){
                    cool_yylval.symbol=stringtable.add_string("");
		    BEGIN(INITIAL);
		    return STR_CONST;
                  }                  
		  BEGIN(INITIAL);
 		  cout<<"detected eos, strBuf:"<<strBuf.str()<<"\n";
                  /*printf("strBuf length:%d\n",strlen(strBuf.str().c_str()));*/
		  char *foo = new char[strlen(strBuf.str().c_str())];
		  strcpy(foo,strBuf.str().c_str());
		  /*printf("foo:%s\n",foo);*/
		  cool_yylval.symbol=stringtable.add_string(foo);
	          strBuf.str("");
		  return STR_CONST;
		 }


[a-z][a-zA-Z0-9_]*	{ /*printf("objectid:%s\n",yytext);*/
		          cool_yylval.symbol=idtable.add_string(yytext);
 		          return OBJECTID;
			}


[A-Z][a-zA-Z0-9_]*	{ /*printf("typeid:%s\n",yytext);*/
 			  cool_yylval.symbol=idtable.add_string(yytext);
                          return TYPEID;
			}




 /* 
  * remove spaces
  */
[ \t\r\v\f]   {}

 /* 
  * increment line numbers on each newline
  */ 
[\n]	{printf("newline\n");curr_lineno++;}

.			{
 			  cool_yylval.error_msg=yytext;
			  return ERROR;
			}


%%
