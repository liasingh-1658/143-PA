/*
 * The scanner definition for COOL.
 */
%option noyywrap
/*
 * Stuff enclosed in %{ %} in the first section is copied verbatim to the
 * output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include "cool-parse.h"

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#include <string>

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

 int string_len = 0;

%}

/*
 * Define names for regular expressions here.
 */


DARROW =>
LE <=
ASSIGN <-

START_STRING \"
%x string
%x error_string
%x type_id_started

%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */

{DARROW}		{ return (DARROW); }
{LE}            { return (LE); }
{ASSIGN}        { return (ASSIGN);}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

(?i:if)            { return (IF); }
(?i:else)         { return (ELSE); }
(?i:fi)            { return (FI); }
(?i:in)            { return (IN); }
(?i:let)           { return (LET); }
(?i:loop)          { return (LOOP); }
(?i:pool)          { return (POOL); }
(?i:class)         { return (CLASS);}
(?i:inherits)      { return (INHERITS); }
(?i:then)          { return (THEN); }
(?i:while)         { return (WHILE); }
(?i:case)          { return (CASE); }
(?i:esac)          { return (ESAC); }
(?i:of)            { return (OF); }
(?i:new)           { return (NEW); }
(?:isvoid)       { return (ISVOID); }


  [.@~*/+-{}();,:] { return (yytext[0]);} 

 /* does not work */
 /* \n {curr_lineno++;} */

 [ \f\r\t\v]+ /* eat whitespace */ 

 /*t(?i:rue) {
  *  cool_yylval.boolean = true;
  *  return(BOOL_CONST);
 /*}

 /*f(?i:alse) { *  cool_yylval.boolean = false;
  *  return(BOOL_CONST);
  *}
 */

 /*type identifiers: capital letter followed by leter or digit */
 /* [A-Z][a-z|A-Z|0-9|_]* {
  *   cout << "in ob identifier" << endl;
  *   cool_yylval.symbol = idtable.add_string(yytext, yyleng);
  *   return(TYPEID);
  *}
  */

 /*object identifiers */
 /*[a-z][A-z|a-z|0-9|_]* {
 *   cout << "in obj" << endl;
 *   cool_yylval.symbol = idtable.add_string(yytext, yyleng);
 *   return(OBJECTID);
 *}
 */

 /* class identifiers */

 /* ints which are digits, store int table entry in symbol table */
[0-9]+ {
    cout << "in digit" << endl;
    cout << *yytext << endl;
    cool_yylval.symbol = inttable.add_int(std::stoi(yytext));
    return(INT_CONST);
 }

 /*
 * Start string.
 */

\"  { 
    string_buf_ptr = string_buf;
    BEGIN(string); 
}

 /* deal with string errors */

<string>\n {
    cool_yylval.error_msg = "Unterminated string constant";
    BEGIN(error_string);
    return(ERROR);
}

<string>\0 {
    cool_yylval.error_msg = "String contains null character";
    BEGIN(error_string);
    return(ERROR);
}

<string><<EOF>> {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(error_string);
    return(ERROR);
}

 /* deal with newline and blank space stuff in strings */

<string>\\n  {
    if (string_len < MAX_STR_CONST) {
        *string_buf_ptr++ = '\n';
        string_len++;
    } else {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(error_string);
        return(ERROR);
    }

}

<string>\\t  {
    if (string_len < MAX_STR_CONST) {
        *string_buf_ptr++ = '\t';
        string_len++;
    } else {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(error_string);
        return(ERROR);
  }
}

<string>\\b  {
    if (string_len < MAX_STR_CONST) {
        *string_buf_ptr++ = '\b';
        string_len++;
    } else {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(error_string);
        return(ERROR);
    }
}

<string>\\f  {
    if (string_len < MAX_STR_CONST) {
        *string_buf_ptr++ = '\f';
        string_len++;
    } else {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(error_string);
        return(ERROR);
    }
}

 /* convert dash then zero to just zero */
<string>\\0 {
    if (string_len < MAX_STR_CONST) {
        *string_buf_ptr++ = '0';
        string_len++;
    } else {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(error_string);
        return(ERROR);
    }
}

 /* take in all non error characters */
<string>[^\n\0\"<<EOF>>] {
    // before updating char buffer check size
    if (string_len < MAX_STR_CONST) {
       *string_buf_ptr = yytext[0];
       string_buf_ptr++;
       string_len++;;
    } else {
        cool_yylval.error_msg = "String constant too long";
        BEGIN(error_string);
        return(ERROR);
    }
}

 /* end string */
<string>\" {
    BEGIN(INITIAL);
    string_buf_ptr = string_buf;
    cool_yylval.symbol = stringtable.add_string(string_buf_ptr);
    *string_buf_ptr = '\0';
    return (STR_CONST);
}

<error_string>[^\"] {}

<error_string>[\"] {BEGIN(INITIAL);}
%%
