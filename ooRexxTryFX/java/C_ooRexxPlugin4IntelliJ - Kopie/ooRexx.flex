package org.oorexx.ide.lexer;

import com.intellij.lexer.*;
import com.intellij.psi.tree.IElementType;

import static org.oorexx.ide.lang.OoRexxTypes.*;
import static com.intellij.psi.TokenType.*;

%%

%{
  public OoRexxLexer(org.oorexx.ide.intellij.setting.OoRexxLanguageSettings settings) {
    this((java.io.Reader)null);
     this.allowSpecialChars = allowSpecialChars = settings.isAllowSpecialChars();;
  }

  public OoRexxLexer(){
    this((java.io.Reader)null);
    this.allowSpecialChars = false;
  }
%}

%{}
//  /**
//    * '#+' stride demarking start/end of raw string/byte literal
//    */
//  private int zzShaStride = -1;

  /**
    * Dedicated storage for starting position of some previously successful
    * match
    */
  private int zzPostponedMarkedPos = -1;

  /**
    * Dedicated nested-comment level counter
    */
    private int zzNestedCommentLevel = 0;

    private int doubleQuoteStringLiteralStart = 0;
    private int singleQuoteStringLiteralStart = 0;

    private int concatinationOffset = -1;
    private int commentLevel = 0;
    private boolean commentStart = false;
    private boolean isMinus;
    private boolean isConcatinationWhiteSpace = false;
    private int yychar;
    private boolean allowSpecialChars = false;
    private static java.util.regex.Pattern pattern = java.util.regex.Pattern.compile(".*(\\u0040|\\u0023|\\u00A2|\\u0024).*", java.util.regex.Pattern.CASE_INSENSITIVE);

    public IElementType getIdentifier(IElementType identifier){
        if(allowSpecialChars){
            return identifier;
        } else {
            String text = yytext().toString();
            java.util.regex.Matcher matcher = pattern.matcher(text);

            if(matcher.matches()){
                return BAD_CHARACTER;
            } else {
                return identifier;
            }
        }
    }
%}

%{
  IElementType imbueBlockComment() {
      assert(zzNestedCommentLevel == 0);
      yybegin(INITIAL);

      zzStartRead = zzPostponedMarkedPos;
      zzPostponedMarkedPos = -1;

      if (yylength() >= 3) {
          if (yycharat(2) == '*' && (yylength() == 3 || yycharat(3) != '*' && yycharat(3) != '/')) {
              return DOC_COMMENT;
          }
      }

      return BLOCK_COMMENT;
  }

  IElementType imbueConcat(IElementType e, boolean isWhiteSpace){

    yybegin(INITIAL);

    isConcatinationWhiteSpace = isWhiteSpace;

    commentStart = false;

    if(zzStartRead != zzEndRead){
        zzStartRead = concatinationOffset;
        zzMarkedPos = zzStartRead + 1;
    }
    concatinationOffset = -1;
    if(!isWhiteSpace){
        if(isMinus)
            return MINUS;
        else
            return COMMA;
    } else return e;


  }

%}

%public
%class OoRexxLexer
%implements FlexLexer
%function advance
%caseless
%char

%type IElementType
%s INITIAL

%s IN_BLOCK_COMMENT
%s IN_EOL_COMMENT
%s IN_STRING_LITERAL
%s IN_LIFETIME_OR_CHAR
%s IN_CONCATINATION
%s IN_EOL
%s IN_IDENTIFIER

%unicode

///////////////////////////////////////////////////////////////////////////////////////////////////
// Environment Symbols
///////////////////////////////////////////////////////////////////////////////////////////////////

ENVIRONMENT_SYMBOL_START = \.

///////////////////////////////////////////////////////////////////////////////////////////////////
// Directives
///////////////////////////////////////////////////////////////////////////////////////////////////

DIRECTIVE_START = ""

///////////////////////////////////////////////////////////////////////////////////////////////////
// Whitespaces
///////////////////////////////////////////////////////////////////////////////////////////////////

SINGLE_EOL           = \n | \r | \r\n
WHITE_SPACE = [\ \t]+
EOL = ([\ \t]* {SINGLE_EOL}+ [\ \t]*)+


///////////////////////////////////////////////////////////////////////////////////////////////////
// Identifier
///////////////////////////////////////////////////////////////////////////////////////////////////

IDENTIFIER_WITHOUT_SPECIAL_CHARS = [a-zA-Z\_\?\!\.]+[0-9a-zA-Z\_\?\!\.]* // No "special" chars
IDENTIFIER_WITH_SPECIAL_CHARS = [a-zA-Z\_\?\!\.\#\$\@\¢]+[0-9a-zA-Z\_\?\!\.\#\$\@\¢]*

IDENTIFIER = {IDENTIFIER_WITH_SPECIAL_CHARS}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Literals
///////////////////////////////////////////////////////////////////////////////////////////////////

EXPONENT      = [eE] [-+]? [0-9_]+

FLT_LITERAL   =  ( {DEC_LITERAL} \. {DEC_LITERAL} {EXPONENT}?)
              | ( {DEC_LITERAL} {EXPONENT}) | ({DEC_LITERAL} \.)

INT_LITERAL =  {DEC_LITERAL}+

DEC_LITERAL = [0-9] [0-9_]*



%%

<YYINITIAL> {
  "#!" [\r\n]                     { yybegin(INITIAL); yypushback(1); return SHEBANG_LINE; }
  "#!" [^\[\r\n] [^\r\n]*         { yybegin(INITIAL); return SHEBANG_LINE; }
  [^]                             { yybegin(INITIAL); yypushback(1); }
}

//<INITIAL> \'                    { yybegin(IN_LIFETIME_OR_CHAR); yypushback(1); }

<INITIAL>                       {

  "["                             { return LBRACK; }
  "]"                             { return RBRACK; }
  "("                             { return LPAREN; }
  ")"                             { return RPAREN; }

  ":"                             { return COLON; }
  ";"                             { return SEMICOLON; }
//  ","                             { return COMMA; }
  "."                             { return DOT; }


// Operators


  "+"                             { return PLUS; }
//  "-"                             { return MINUS; }
  "\\" | "\u00AC"                 { return NEGATION; }

  "*"                             { return MUL; }
  "/"                             { return DIV; }
  "%"                             { return INTDIV; }

  "="                             { return EQ; }
  "<"                             { return LT; }
  ">"                             { return GT; }

  "&"                             { return AND; }

  "|"                             { return PIPE; }


    // Directives

  {DIRECTIVE_START} "ATTRIBUTE"   { return ATTRIBUTE; }
  {DIRECTIVE_START} "CLASS"   { return CLASS; }
  {DIRECTIVE_START} "CONSTANT"   { return CONSTANT; }
  {DIRECTIVE_START} "METHOD"   { return METHOD; }
  {DIRECTIVE_START} "OPTIONS"   { return OPTIONS; }
  {DIRECTIVE_START} "REQUIRES"   { return REQUIRES; }
  {DIRECTIVE_START} "ROUTINE"   { return ROUTINE; }
//  {DIRECTIVE_START} "RESOURCE"   { yybegin(IN_RESOURCE); yypushback(1);}

  "ABBREV" / "(" {return BIF_ABBREV;}
  "ABS" / "(" {return BIF_ABS;}
  "ADDRESS" / "(" {return BIF_ADDRESS;}
  "ARG" / "(" {return BIF_ARG;}
  "B2X" / "(" {return BIF_B2X;}
  "BEEP" / "(" {return BIF_BEEP;}
  "BITAND" / "(" {return BIF_BITAND;}
  "BITOR" / "(" {return BIF_BITOR;}
  "BITXOR" / "(" {return BIF_BITXOR;}
  "C2D" / "(" {return BIF_C2D;}
  "C2X" / "(" {return BIF_C2X;}
  "CENTER" / "(" {return BIF_CENTER;}
  "CENTRE" / "(" {return BIF_CENTRE;}
  "CHANGESTR" / "(" {return BIF_CHANGESTR;}
  "CHARIN" / "(" {return BIF_CHARIN;}
  "CHAROUT" / "(" {return BIF_CHAROUT;}
  "CHARS" / "(" {return BIF_CHARS;}
  "COMPARE" / "(" {return BIF_COMPARE;}
  "CONDITION" / "(" {return BIF_CONDITION;}
  "COPIES" / "(" {return BIF_COPIES;}
  "COUNTSTR" / "(" {return BIF_COUNTSTR;}
  "D2C" / "(" {return BIF_D2C;}
  "D2X" / "(" {return BIF_D2X;}
  "DATATYPE" / "(" {return BIF_DATATYPE;}
  "DATE" / "(" {return BIF_DATE;}
  "DELSTR" / "(" {return BIF_DELSTR;}
  "DELWORD" / "(" {return BIF_DELWORD;}
  "DIGITS" / "(" {return BIF_DIGITS;}
  "DIRECTORY" / "(" {return BIF_DIRECTORY;}
  "ENDLOCAL" / "(" {return BIF_ENDLOCAL;}
  "ERRORTEXT" / "(" {return BIF_ERRORTEXT;}
  "FILESPEC" / "(" {return BIF_FILESPEC;}
  "FORM" / "(" {return BIF_FORM;}
  "FORMAT" / "(" {return BIF_FORMAT;}
  "FUZZ" / "(" {return BIF_FUZZ;}
  "INSERT" / "(" {return BIF_INSERT;}
  "LASTPOS" / "(" {return BIF_LASTPOS;}
  "LEFT" / "(" {return BIF_LEFT;}
  "LENGTH" / "(" {return BIF_LENGTH;}
  "LINEIN" / "(" {return BIF_LINEIN;}
  "LINEOUT" / "(" {return BIF_LINEOUT;}
  "LINES" / "(" {return BIF_LINES;}
  "LOWER" / "(" {return BIF_LOWER;}
  "MAX" / "(" {return BIF_MAX;}
  "MIN" / "(" {return BIF_MIN;}
  "OVERLAY" / "(" {return BIF_OVERLAY;}
  "POS" / "(" {return BIF_POS;}
  "QUALIFY" / "(" {return BIF_QUALIFY;}
  "QUEUED" / "(" {return BIF_QUEUED;}
  "RANDOM" / "(" {return BIF_RANDOM;}
  "REVERSE" / "(" {return BIF_REVERSE;}
  "RIGHT" / "(" {return BIF_RIGHT;}
  "RXFUNCADD" / "(" {return BIF_RXFUNCADD;}
  "RXFUNCDROP" / "(" {return BIF_RXFUNCDROP;}
  "RXFUNCQUERY" / "(" {return BIF_RXFUNCQUERY;}
  "RXQUEUE" / "(" {return BIF_RXQUEUE;}
  "SETLOCAL" / "(" {return BIF_SETLOCAL;}
  "SIGN" / "(" {return BIF_SIGN;}
  "SOURCELINE" / "(" {return BIF_SOURCELINE;}
  "SPACE" / "(" {return BIF_SPACE;}
  "STREAM" / "(" {return BIF_STREAM;}
  "STRIP" / "(" {return BIF_STRIP;}
  "SUBSTR" / "(" {return BIF_SUBSTR;}
  "SUBWORD" / "(" {return BIF_SUBWORD;}
  "SYMBOL" / "(" {return BIF_SYMBOL;}
  "TIME" / "(" {return BIF_TIME;}
  "TRACE" / "(" {return BIF_TRACE;}
  "TRANSLATE" / "(" {return BIF_TRANSLATE;}
  "TRUNC" / "(" {return BIF_TRUNC;}
  "UPPER" / "(" {return BIF_UPPER;}
  "USERID" / "(" {return BIF_USERID;}
  "VALUE" / "(" {return BIF_VALUE;}
  "VAR" / "(" {return BIF_VAR;}
  "VERIFY" / "(" {return BIF_VERIFY;}
  "WORD" / "(" {return BIF_WORD;}
  "WORDINDEX" / "(" {return BIF_WORDINDEX;}
  "WORDLENGTH" / "(" {return BIF_WORDLENGTH;}
  "WORDPOS" / "(" {return BIF_WORDPOS;}
  "WORDS" / "(" {return BIF_WORDS;}
  "X2B" / "(" {return BIF_X2B;}
  "X2C" / "(" {return BIF_X2C;}
  "X2D" / "(" {return BIF_X2D;}
  "XRANGE" / "(" {return BIF_XRANGE;}





  "~"                             { return TILDE; }
"IF"   / "("                   { return IF; }
  {IDENTIFIER}  / "("             {return getIdentifier(FUNC_IDENTIFIER);}


    "PACKAGE" {return PACKAGE;}

    // Directive Options
"STATE"                      { return STATE; }
"COMMAND"                      { return COMMAND; }
"DESCRIPTION"                      { return DESCRIPTION; }
"CREATE"                      { return CREATE; }
"DELETE"                      { return DELETE; }
"EXIST"                      { return EXIST; }
"OPEN"                      { return OPEN; }
"COUNT"                      { return COUNT; }
    "ABSTRACT"                      { return ABSTRACT; }
    "ANNOTATE"                      {return ANNOTATE;}
    "ATTRIBUTE"                      { return ATTRIBUTE; }
    "CLASS"                      { return CLASS; }
    "CONDITION"                 {return CONDITION;}
    "DIGITS"                      { return DIGITS; }
    "EXTERNAL"                      { return EXTERNAL; }
    "FORM"                      { return FORM; }
    "FUZZ"                      { return FUZZ; }
    "GET"                      { return GET; }
    "GUARDED"                      { return GUARDED; }
    "INHERIT"                      { return INHERIT; }
    "LIBRARY"                      { return LIBRARY; }
    "METACLASS"                      { return METACLASS; }
    "MIXINCLASS"                      { return MIXINCLASS; }
    "NAMESPACE"                     {return NAMESPACE;}
    "NOPROLOG"                  {return NOPROLOG;}
    "PRIVATE"                      { return PRIVATE; }
    "PROLOG"                        {return PROLOG;}
    "PROTECTED"                      { return PROTECTED; }

    "PUBLIC"                      { return PUBLIC; }
    "RESOURCE"                  {return RESOURCE;}
    "SET"                      { return SET; }
    "SUBCLASS"                      { return SUBCLASS; }
    "TRACE"                      { return TRACE; }
    "UNGUARDED"                      { return UNGUARDED; }
    "UNPROTECTED"                      { return UNPROTECTED; }
    "DELEGATE"          {return DELEGATE;}

//Keywords

    "ADDRESS"                      { return ADDRESS; }
    "ARG"                      { return ARG; }
    "CALL"                      { return CALL; }
    "DO"                      { return DO; }
    "DROP"                      { return DROP; }
    "EXIT"                      { return EXIT; }
    "EXPOSE"                      { return EXPOSE; }
    "FORWARD"                      { return FORWARD; }
    "GUARD"                      { return GUARD; }

    "IF"                    { return IF; }
    "INTERPRET"                      { return INTERPRET; }
    "ITERATE"                      { return ITERATE; }
    "INDEX" {return INDEX;}
    "ITEM" {return ITEM;}
    "LEAVE"                      { return LEAVE; }
    "LOOP"                      { return LOOP; }
    "NOP"                      { return NOP; }
    "NUMERIC"                      { return NUMERIC; }
    "OPTIONS"                      { return OPTIONS; }
    "PARSE"                      { return PARSE; }
    "PROCEDURE"                      { return PROCEDURE; }
    "PULL"                      { return PULL; }
    "PUSH"                      { return PUSH; }
    "QUEUE"                      { return QUEUE; }
    "RAISE"                      { return RAISE; }
    "REPLY"                      { return REPLY; }
    "RETURN"                      { return RETURN; }
    "SAY"                      { return SAY; }
    "SELECT"                      { return SELECT; }
    "SIGNAL"                      { return SIGNAL; }
    "TRACE"                      { return TRACE; }
    "USE"                      { return USE; }

    "SUPER" {return SUPER;}
    "SELF" {return SELF;}

    //Keyword options
    "ADDITIONAL"                      { return ADDITIONAL; }
    "ANY"                      { return ANY; }
    "ARG"                      { return ARG; }
    "ARGUMENTS"                      { return ARGUMENTS; }
    "ARRAY"                      { return ARRAY; }
    "BY"                      { return BY; }
    "CASELESS"                      { return CASELESS; }
    "CLASS"                      { return CLASS; }
    "COMMANDS"                      { return COMMANDS; }
    "CONTINUE"                      { return CONTINUE; }
    "DESCRIPTION"                      { return DESCRIPTION; }
    "DIGIT"                      { return DIGIT; }
    "DROP"                      { return DROP; }
    "ELSE"                      { return ELSE; }
    "END"                      { return END; }
    "ENGINEERING"                      { return ENGINEERING; }
    "ERROR"                      { return ERROR; }
    "EXIT"                      { return EXIT; }
    "EXPOSE"                      { return EXPOSE; }
    "FAILURE"                      { return FAILURE; }
    "FOR"                      { return FOR; }
    "FOREVER"                      { return FOREVER; }
    "FORM"                      { return FORM; }
    "FUZZ"                      { return FUZZ; }
    "HALT"                      { return HALT; }
    "INTERMEDIATES"                      { return INTERMEDIATES; }
    "LABEL"                      { return LABEL; }
    "LABELS"                      { return LABELS; }
    "LINEIN"                      { return LINEIN; }
    "LINEOUT"                      { return LINEOUT; }
    "LOSTDIGITS"                      { return LOSTDIGITS; }
    "LOWER"                      { return LOWER; }
    "MESSAGE"                      { return MESSAGE; }
    "NAME"                      { return NAME; }
    "NOMETHOD"                      { return NOMETHOD; }
    "NORMAL"                      { return NORMAL; }
    "NOSTRING"                      { return NOSTRING; }
    "NOTREADY"                      { return NOTREADY; }
    "NOVALUE"                      { return NOVALUE; }
    "VALUE"                      { return VALUE; }
    "OFF"                      { return OFF; }
    "ON"                      { return ON; }
    "OTHERWISE"                      { return OTHERWISE; }
    "OVER"                      { return OVER; }
    "PROPAGATE"                      { return PROPAGATE; }
    "PULL"                      { return PULL; }
    "RESULTS"                      { return RESULTS; }
    "RETURN"                      { return RETURN; }
    "SCIENTIFIC"                      { return SCIENTIFIC; }
    "SOURCE"                      { return SOURCE; }
    "STRICT"                      { return STRICT; }
    "SYNTAX"                      { return SYNTAX; }
    "THEN"                      { return THEN; }
    "TO"                      { return TO; }
    "UNTIL"                      { return UNTIL; }
    "UPPER"                      { return UPPER; }
    "USER"                      { return USER; }
    "VAR"                      { return VAR; }
    "VERSION"                      { return VERSION; }
    "WHEN"                      { return WHEN; }
    "WHILE"                      { return WHILE; }
    "WITH"                      { return WITH; }

  // Environment Symbols


  {ENVIRONMENT_SYMBOL_START} "FALSE" { return FALSE; }
  {ENVIRONMENT_SYMBOL_START} "NIL" { return NIL; }
  {ENVIRONMENT_SYMBOL_START} "TRUE" { return TRUE; }
  {ENVIRONMENT_SYMBOL_START} "LOCAL" { return ENV_LOCAL; }
  {ENVIRONMENT_SYMBOL_START} "ENVIRONMENT" { return ENV_ENVIRONMENT; }

  "\"" {yybegin(IN_STRING_LITERAL); yypushback(1);}
  "\'" {yybegin(IN_STRING_LITERAL); yypushback(1);}

  // Comments

  "/*"                            { yybegin(IN_BLOCK_COMMENT); yypushback(2); }
  "--" ([^\n | \r | \r\n]) {return EOL_COMMENT;}
  "--" .* ([^\n | \r | \r\n])                        { return EOL_COMMENT; }
  "--" {return EOL_COMMENT;}

  "." {IDENTIFIER}                    { return getIdentifier(ENV_IDENTIFIER); }
  {IDENTIFIER}                    { return getIdentifier(IDENTIFIER);
  }


  /* LITERALS */

  // Floats must come first, to parse 1e1 as a float and not as an integer with a suffix
  {FLT_LITERAL}                   { return FLOAT_LITERAL; }

  {INT_LITERAL}                   { return INTEGER_LITERAL; }

  {SINGLE_EOL}                 {yybegin(IN_EOL); yypushback(1);}
  {WHITE_SPACE}             { return WHITE_SPACE;}


  ","  {  isMinus = false; yybegin(IN_CONCATINATION);  yypushback(1);}
  "-"  {  isMinus = true; yybegin(IN_CONCATINATION);  yypushback(1);}
}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Comments
///////////////////////////////////////////////////////////////////////////////////////////////////

<IN_EOL>{

    {SINGLE_EOL} {

        if(isConcatinationWhiteSpace){
            isConcatinationWhiteSpace = false;
            yybegin(INITIAL);
            return EOL_WHITE_SPACE;
        } else {
            isConcatinationWhiteSpace = false;
            yybegin(INITIAL);
            return EOL;
        }
    }


}


<IN_CONCATINATION> {

    ","  {

            if(!commentStart){
                if(concatinationOffset != -1){
                    return imbueConcat(COMMA, false);
                }
                concatinationOffset = zzStartRead;

            }
        }
    ("--") {
        if(!commentStart){

            return imbueConcat(CONCATINATION_WHITE_SPACE, true);
        }
    }


    "-" {
            if(!commentStart){

                if(concatinationOffset != -1){
                    return imbueConcat(MINUS, false);
                }
                concatinationOffset = zzStartRead;

            }
    }

    "/*" {
        if (commentLevel++ == 0){
                commentStart = true;
        }
    }

    "*/" {
        if (--commentLevel == 0){
                 commentStart = false;
                 commentLevel = 0;
        }
    }
    <<EOF>> {

    commentLevel = 0; commentStart = false; concatinationOffset = -1; return imbueConcat(CONCATINATION_WHITE_SPACE, true); }

    {SINGLE_EOL} {
            return imbueConcat(CONCATINATION_WHITE_SPACE, true);
        }

     {WHITE_SPACE} {

        }
    [^] {

        if(!commentStart){
            if(isMinus){
                return imbueConcat(MINUS, false);
            } else {
                return imbueConcat(COMMA, false);
            }
        }
    }




}

///////////////////////////////////////////////////////////////////////////////////////////////////
// Comments
///////////////////////////////////////////////////////////////////////////////////////////////////

<IN_BLOCK_COMMENT> {
  "/*"    { if (zzNestedCommentLevel++ == 0)
              zzPostponedMarkedPos = zzStartRead;
          }

  "*/"    { if (--zzNestedCommentLevel == 0)
              return imbueBlockComment();
          }

  <<EOF>> { zzNestedCommentLevel = 0; return imbueBlockComment(); }

  [^]     { }
}


<IN_STRING_LITERAL>{

    "'" / "(" {
    if(doubleQuoteStringLiteralStart == 0){
                    singleQuoteStringLiteralStart++;

                    if(singleQuoteStringLiteralStart%2 == 0 && (yylength() == 1 || yycharat(1) != '\"')){
                        singleQuoteStringLiteralStart = 0;
                        yybegin(INITIAL);

                        return FUNC_IDENTIFIER;
                     }
        }

     }

    "\'X" {
        if(doubleQuoteStringLiteralStart == 0){
                    singleQuoteStringLiteralStart++;

                    if(singleQuoteStringLiteralStart%2 == 0 && (yylength() == 1 || yycharat(1) != '\"')){
                        singleQuoteStringLiteralStart = 0;
                        yybegin(INITIAL);

                        return HEX_STRING_LITERAL;
                     }
        }
    }

    "\'B" {
    if(doubleQuoteStringLiteralStart == 0){
                singleQuoteStringLiteralStart++;

                if(singleQuoteStringLiteralStart%2 == 0 && (yylength() == 1 || yycharat(1) != '\"')){
                    singleQuoteStringLiteralStart = 0;
                    yybegin(INITIAL);

                    return BINARY_STRING_LITERAL;
                 }
       }
    }

    "\'" {

        if(doubleQuoteStringLiteralStart == 0){
            singleQuoteStringLiteralStart++;

            if(singleQuoteStringLiteralStart%2 == 0 && (yylength() == 1 || yycharat(1) != '\"')){
                singleQuoteStringLiteralStart = 0;
                yybegin(INITIAL);

                return STRING_LITERAL;
            }
        }
    }

    "\""  / "(" {
    if(singleQuoteStringLiteralStart == 0){
                    doubleQuoteStringLiteralStart++;

                    if(doubleQuoteStringLiteralStart%2 == 0 && (yylength() == 1 || yycharat(1) != '\"')){
                        doubleQuoteStringLiteralStart = 0;
                        yybegin(INITIAL);

                        return FUNC_IDENTIFIER;
                     }
        }
        }

    "\"X" {
    if(singleQuoteStringLiteralStart == 0){
                doubleQuoteStringLiteralStart++;

                if(doubleQuoteStringLiteralStart%2 == 0 && (yylength() == 1 || yycharat(1) != '\"')){
                    doubleQuoteStringLiteralStart = 0;
                    yybegin(INITIAL);

                    return HEX_STRING_LITERAL;
                 }
                 }
    }

    "\"B" {
    if(singleQuoteStringLiteralStart == 0){
                doubleQuoteStringLiteralStart++;

                if(doubleQuoteStringLiteralStart%2 == 0 && (yylength() == 1 || yycharat(1) != '\"')){
                    doubleQuoteStringLiteralStart = 0;
                    yybegin(INITIAL);

                    return BINARY_STRING_LITERAL;
                 }
                 }
    }

    "\"" {
    if(singleQuoteStringLiteralStart == 0){
        doubleQuoteStringLiteralStart++;

            if(doubleQuoteStringLiteralStart%2 == 0 && (yylength() == 1 || yycharat(1) != '\"')){
                doubleQuoteStringLiteralStart = 0;
                yybegin(INITIAL);

                return STRING_LITERAL;
            }
        }
    }

    <<EOF>> {singleQuoteStringLiteralStart = 0; doubleQuoteStringLiteralStart = 0; yybegin(INITIAL); return STRING_LITERAL; }

    [^]     { }

}



///////////////////////////////////////////////////////////////////////////////////////////////////
// Lifetimes & Literals
///////////////////////////////////////////////////////////////////////////////////////////////////

<IN_LIFETIME_OR_CHAR> {
  <<EOF>>                               { yybegin(INITIAL); return BAD_CHARACTER; }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
// Catch All
///////////////////////////////////////////////////////////////////////////////////////////////////

[^] { return BAD_CHARACTER; }
