%{
	#include "scanner.h"
	#include "parser.h"

	#include "doc.h"

	void strtolower(char *str){
		int i = 0;
		while (str[i]) { 
			str[i] = tolower(str[i]);
			i++;
		}
	}

%}

%code requires {
	#include "doc.h"
}

%define api.token.prefix {DOC_}
%parse-param { zval* context } 

%union {
	int ival;
	float fval;
	char* sval;

	Option option;
	zval options;
}

/*********************************
 ** Token Definition
 *********************************/
%token <ival> INT
%token <fval> FLOAT
%token <sval> IDENTIFIER STRING

%type <option> option
%type <options> options

/* Keywords */
%token SCOPE_RESOLUTION ASSIGN AT

%%
input:
	AT IDENTIFIER SCOPE_RESOLUTION IDENTIFIER '(' options ')' {

		zval *parameter;
		if ((parameter = zend_hash_str_find(Z_ARRVAL_P(context), $2, strlen($2))) == NULL) {

			parameter = (zval *) safe_emalloc(sizeof(zval), 1, 0);
			array_init(parameter);

			zend_hash_str_update(
				Z_ARRVAL_P(context),
				$2,
				strlen($2),
				parameter);
		}
/*
		zval *options;
		if ((options = zend_hash_str_find(Z_ARRVAL_P(parameter), $4, strlen($4))) != NULL) {
 			zend_hash_merge(
				Z_ARRVAL_P(options), 
				Z_ARRVAL_P(&$6), 
				zval_add_ref, 
				1); 
		}else{
			options = &$6;
		}
*/

		zend_hash_str_update(
			Z_ARRVAL_P(parameter),
			$4,
			strlen($4),
			&$6);

	}
	| error input{
		yyerrok;
		yyclearin;
	}
	;

options:
	/* empty */ {
		array_init(&$$);
	}
	| option {
		array_init(&$$);
		//add_next_index_zval(&$$, &$1);

		switch($1.type){
			case 0:
				add_assoc_string(&$$, $1.name, (char*) $1.value);
			break;
			case 1:
				add_assoc_long(&$$, $1.name, *((int*) $1.value));
			break;
			case 2:
				add_assoc_double(&$$, $1.name, *((float*) $1.value));
			break;
		}

		free($1.name);
		free($1.value);
	}
	| options ',' option{
		$$ = $1;

		switch($3.type){
			case 0:
				add_assoc_string(&$$, $3.name, (char*) $3.value);
			break;
			case 1:
				add_assoc_long(&$$, $3.name, *((int*) $3.value));
			break;
			case 2:
				add_assoc_double(&$$, $3.name, *((float*) $3.value));
			break;
		}

		free($3.name);
		free($3.value);

	}
	;

option:
	IDENTIFIER ASSIGN IDENTIFIER{
		$$.type  = 0;
		$$.name = malloc(strlen($1)+1);
		memcpy($$.name, $1, strlen($1)+1);
		//strtolower($$.name);

		$$.value = malloc(strlen($3)+1);
		memcpy($$.value, $3, strlen($3)+1);
	}
	| IDENTIFIER ASSIGN STRING{
		$$.type  = 0;
		$$.name = malloc(strlen($1)+1);
		memcpy($$.name, $1, strlen($1)+1);
		//strtolower($$.name);

		$$.value = malloc(strlen($3)+1);
		memcpy($$.value, $3, strlen($3)+1);
	}
	| IDENTIFIER ASSIGN FLOAT{
		$$.type  = 2;
		$$.name = malloc(strlen($1)+1);
		memcpy($$.name, $1, strlen($1)+1);
		//strtolower($$.name);

		$$.value = malloc(sizeof(float));
		memcpy($$.value, &$3, sizeof(float));
	}
	| IDENTIFIER ASSIGN INT{
		$$.type  = 1;
		$$.name = malloc(strlen($1)+1);
		memcpy($$.name, $1, strlen($1)+1);
		//strtolower($$.name);

		$$.value = malloc(sizeof(int));
		memcpy($$.value, &$3, sizeof(int));
	}
	;
%%
