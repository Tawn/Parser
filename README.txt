Thanh Kha
Assignment 3
Prof. Chen

README

This program takes in sequence of tokens and semantically parses them. The parser is recursive decent parsing with LL(1) grammar, which looks ahead one step and predicts the outcome based on it. The grammar I used eliminates the ambiguity and checks to see if the language is semantically correct, then outputs the numbers of variables, functions and statements. 

RUN:
change the c file in the parser.rb at the bottom to test whichever you input (ex. "tax.c")


nt_program → nt_type func_decl | {$}
nt_type → {int, void, ε}
func_decl → ( nt_parameter ) | ( nt_parameter ) { data_decls nt_statements } nt_program | ; nt_program
data_decls → nt_type
nt_parameter → nt_type nt_ident
nt_statements → statement
statement → nt_if_statement | return nt_expression | return ; | nt_ident nt_assignment | nt_while_statement | nt_printf_func_call | nt_read_func_call | nt_write_func_call
nt_if_statement → if ( nt_condition_expression ) block_statements | if ( nt_condition_expression ) block_statements else block_statements 
nt_condition_expression → + nt_condition nt_condition_expression | - nt_condition nt_condition_expression
nt_expression → ε | nt_term nt_operation , nt_operation nt_expression
nt_ident → int ident | int ident , nt_ident ; 
nt_assignment → ident = nt_expression ;
nt_while_statement → while ( nt_condition_expression ) block_statements
nt_printf_func_call → printf ( STRING ) ; | printf ( STRING , nt_expression )
nt_read_func_call → read ( STRING ) ;
nt_write_func_call → write ( STRING ) ;
nt_condition_expression → nt_condition nt_condition_expression nt_comparison_op nt_condition_expression | - nt_condition nt_condition_expression nt_comparison_op nt_condition_expression
nt_condition → ident nt_comparison_op ident | ident nt_comparison nt_expression
nt_comparison_op → == | != | > | < | >= | <=
nt_condition_op → && | || 
nt_term → ( nt_expression )
nt_operation → * | / | + | -
nt_parameter → nt_type nt_ident
