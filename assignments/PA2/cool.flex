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

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define MAX_STR_LEN   1024
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
int string_buf_len;
char *string_buf_ptr;

#define STR_TOOLONG 1
#define STR_NULLCH  2

int string_errortype;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

int comment_layer = 0;

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
LE              <=
ASSIGN          <-

%x  COMMENT INLINE_COMMENT STRING STR_ERROR

%%

 /*  ================================
  *   Block comments
  *   
  *   Nested comments are supported.
  *  ================================
  */

<INITIAL,COMMENT>"(*"    {
    comment_layer++;
    BEGIN(COMMENT);
}

<COMMENT>"*)"    {
    comment_layer--;
    if (comment_layer == 0) BEGIN(INITIAL);
}

<COMMENT>.       {}
<COMMENT>"\n"    { curr_lineno++; }

<COMMENT><<EOF>>    {
    cool_yylval.error_msg = "EOF in comment";
    BEGIN(INITIAL);
    return ERROR;
}

"*)"    {
    cool_yylval.error_msg = "Unmatched *)";
    BEGIN(INITIAL);
    return ERROR;
}


 /*  =================
  *   Inline comments 
  *  =================
  */

"--"    { BEGIN(INLINE_COMMENT); }

<INLINE_COMMENT><<EOF>>    { BEGIN(INITIAL); }
<INLINE_COMMENT>"\n"    {
    curr_lineno++;
    BEGIN(INITIAL);
}

<INLINE_COMMENT>.    { }


 /*  ==================================
  *   The multiple-character operators 
  *  ==================================
  */

{DARROW}    { return DARROW; }
{LE}        { return LE;     }
{ASSIGN}    { return ASSIGN; }


 /*  ===========
  *   Operators
  *  ===========
  */

"{"    { return int('{'); }
"}"    { return int('}'); }
"("    { return int('('); }
")"    { return int(')'); }
"+"    { return int('+'); }
"-"    { return int('-'); }
"*"    { return int('*'); }
"/"    { return int('/'); }
"~"    { return int('~'); }
"<"    { return int('<'); }
"="    { return int('='); }
";"    { return int(';'); }
"."    { return int('.'); }
":"    { return int(':'); }
","    { return int(','); }
"@"    { return int('@'); }


 /*  =====================================================================
  *   Keywords
  *   
  *   Keywords are case-insensitive except for the values true and false,
  *   which must begin with a lower-case letter.
  *  =====================================================================
  */

(?i:class)       { return CLASS;    }
(?i:else)        { return ELSE;     }
(?i:fi)          { return FI;       }
(?i:if)          { return IF;       }
(?i:in)          { return IN;       }
(?i:inherits)    { return INHERITS; }
(?i:isvoid)      { return ISVOID;   }
(?i:let)         { return LET;      }
(?i:loop)        { return LOOP;     }
(?i:pool)        { return POOL;     }
(?i:then)        { return THEN;     }
(?i:while)       { return WHILE;    }
(?i:case)        { return CASE;     }
(?i:esac)        { return ESAC;     }
(?i:new)         { return NEW;      }
(?i:of)          { return OF;       }
(?i:not)         { return NOT;      }

t(?i:rue)        { cool_yylval.boolean = 1; return BOOL_CONST; }
f(?i:alse)       { cool_yylval.boolean = 0; return BOOL_CONST; }


 /*  =============
  *   White Space
  *  =============
  */

"\n"            { curr_lineno++; }
[ \r\v\f\t]+    { }


 /*  ==========
  *   Integers
  *  ==========
  */

[0-9]+    {
    cool_yylval.symbol = inttable.add_string(yytext);
    return INT_CONST;
}


 /*  ==================
  *   Type Identifiers
  *  ==================
  */

[A-Z][a-zA-Z0-9_]*    {
    cool_yylval.symbol = idtable.add_string(yytext);
    return TYPEID;
}


 /*  ====================
  *   Object Identifiers
  *  ====================
  */

[a-z][a-zA-Z0-9_]*    {
    cool_yylval.symbol = idtable.add_string(yytext);
    return OBJECTID;
}


 /*  =================================================================
  *   String constants (C syntax)
  *   
  *   Escape sequence \c is accepted for all characters c. Except for 
  *   \n \t \b \f, the result is c.
  *  =================================================================
  */

\"    {
    string_buf_len = 0;
    string_errortype = 0;
    BEGIN(STRING);
}
<STRING>\"    {
    string_buf[string_buf_len] = '\0';
    cool_yylval.symbol = stringtable.add_string(string_buf);
    BEGIN(INITIAL);
    return STR_CONST;
}

<STRING>\\\n    {
    curr_lineno++;
    if (string_buf_len >= MAX_STR_LEN)
    {
        string_errortype = STR_TOOLONG;
        BEGIN(STR_ERROR);
    }
    else
    {
        string_buf[string_buf_len++] = '\n';
    }
}

<STRING><<EOF>>    {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(INITIAL);
    return ERROR;
}
<STRING>"\n"    {
    cool_yylval.error_msg = "Unterminated string constant";
    BEGIN(INITIAL);
    yyless(0);
    return ERROR;
}
<STRING>"\0"    {
    string_errortype = STR_NULLCH;
    BEGIN(STR_ERROR);
}

<STRING>\\.    {
    if (string_buf_len >= MAX_STR_LEN)
    {
        string_errortype = STR_TOOLONG;
        BEGIN(STR_ERROR);
    }
    else
    {
        switch (yytext[1])
        {
            case 'b': string_buf[string_buf_len++] = '\b'; break;
            case 't': string_buf[string_buf_len++] = '\t'; break;
            case 'n': string_buf[string_buf_len++] = '\n'; break;
            case 'f': string_buf[string_buf_len++] = '\f'; break;
            case '\0':
                string_errortype = STR_NULLCH;
                BEGIN(STR_ERROR);
                break;
            default: string_buf[string_buf_len++] = yytext[1]; break;
        }
    }
}

<STRING>. {
    if (string_buf_len >= MAX_STR_LEN)
    {
        string_errortype = STR_TOOLONG;
        BEGIN(STR_ERROR);
    }
    else
    {
        string_buf[string_buf_len++] = yytext[0];
    }
}

<STR_ERROR>\\\n    { curr_lineno++; }
<STR_ERROR><<EOF>>    {
    cool_yylval.error_msg = "EOF in string constant";
    BEGIN(INITIAL);
    return ERROR;
}
<STR_ERROR>"\n"|\"    {
    if (yytext[0] == '\n') yyless(0);
    switch (string_errortype)
    {
        case STR_TOOLONG:
            cool_yylval.error_msg = "String constant too long";
            break;
        case STR_NULLCH:
            cool_yylval.error_msg = "String contains null character";
            break;
    }
    BEGIN(INITIAL);
    return ERROR;
}
<STR_ERROR>.       { }

 /*  ========
  *   Errors
  *  ========
  */
.    {
    cool_yylval.error_msg = yytext;
    return ERROR;
}

%%
