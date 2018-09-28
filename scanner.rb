#!/usr/bin/ruby

chmod u+x Parser.rb
//26, 2, 101
# Written by Brandon Allard of University of Rochester for CSC 254 

require 'set'

class Token 
    attr_accessor :type, :value

    def initialize(type, value)
        @type = type
        @value = value
    end

    def to_s
        "< "+@type.to_s+" , "+@value.to_s+" >"
    end
end

class DFA
    def initialize(dfa)
        # A few correctness checks could be implemented here..
        @alphabet = dfa[:alphabet]
        @states = dfa[:states]
        @start_state = dfa[:start_state]
        @end_state = dfa[:end_state]
        @transitions = dfa[:transitions]
    end

    # Returns a value or nil
    def next(char_stream)
        # Set starting conditions
        state = @start_state
        output = ""
        
        # Loop until endstate is reached
        while current_char = char_stream.peek
            idx = @transitions[state].index { |x|
               x[0] == :all ||x[0].include?(current_char)
            }
            if idx == nil
                break
            else
                output << char_stream.next
                state = @transitions[state][idx][1]
            end
        end

        # Return a called function or nil
        return (@end_state[state] != nil) ? @end_state[state].call(output) : nil
    end
end

class Scanner
    def initialize(file_path)
        # Attempt to open file
        @file = File.open(file_path, "r")
        @chars = @file.each_char

        # Define subsets in the alphabet the DFA accepts
        letter_chars = %w(a b c d e f g h i j k l m n o p q r s t u 
                           v w x y z A B C D E F G H I J K L M N O P 
                           Q R S T U V W X Y Z _).to_set
        number_chars = %w(1 2 3 4 5 6 7 8 9 0).to_set
        symbol_chars = %w(( ) { } , ; + - * / = < > ! & | # [ ]).to_set
        space = [" ", "\v", "\t"].to_set
        eol = ["\n", "\r"].to_set
        quote = ['"'].to_set
        reserved = %w(read write int void if while return continue break scanf printf).to_set

        # Define the DFA that's used to tokenize language
        @dfa = DFA.new({
            :alphabet => letter_chars | number_chars | symbol_chars | 
                         space | eol | quote,
            :states => [:start, :ident, :comment, :symbol, :number, :quote,
                        :equal, :forward_slash, :or, :and, :symbol_end, :error,
                        :quote_end],
            :start_state => :start,
            :end_state => {
                :number        => lambda { |n| Token.new(:number, n.strip) },
                :ident         => lambda { |n| Token.new(
                                    (reserved.member? n.strip) ? :reserved : :ident, n.strip) },
                :comment_end   => lambda { |n| Token.new(:comment, n.strip) },
                :symbol        => lambda { |n| Token.new(:symbol, n.strip) },
                :symbol_end    => lambda { |n| Token.new(:symbol, n.strip) },
                :equal         => lambda { |n| Token.new(:symbol, n.strip) },
                :or            => lambda { |n| Token.new(:symbol, n.strip) },
                :and           => lambda { |n| Token.new(:symbol, n.strip) },
                :forward_slash => lambda { |n| Token.new(:symbol, n.strip) },
                :quote_end     => lambda { |n| Token.new(:quote, n) },
                :error         => lambda { |n| Token.new(:comment,  "Invalid token: "+n) } },
            :transitions => {
                :start => [
                    [number_chars, :number],
                    [letter_chars, :ident],
                    ["#", :comment],
                    ["/", :forward_slash],
                    [%w(= < > !).to_set, :equal],
                    ["&", :and],
                    ["|", :or],
                    [symbol_chars, :symbol],
                    [quote, :quote],
                    [space | eol, :start],
                    [:all, :error] ],
                :number => [
                    [number_chars, :number],
                    [letter_chars | quote, :error] ],
                :symbol => [],
                :ident => [
                    [letter_chars | number_chars, :ident],
                    [quote, :error] ],
                :comment => [
                    [eol, :comment_end],
                    [:all, :comment] ],
                :quote => [
                    [quote, :quote_end],
                    [:all, :quote] ],
                :equal => [
                    ["=", :symbol_end] ],
                :or => [
                    ["|", :symbol_end] ],
                :and => [
                    [["&"].to_set, :symbol_end] ],
                :forward_slash => [
                    ["/", :comment] ],
                :symbol_end => [],
                :quote_end => [],
                :comment_end => [],
                :error => []
            }
        })
        @current_token = nil
    end

    def next
        unless @current_token != nil
            begin
                return @dfa.next(@chars)
            rescue StopIteration
                return Token.new(:end, "")
            else
                exit
            end
        else
            current = @current_token.clone
            @current_token = nil
            return current
        end
    end

    def peek

        if @current_token == nil
            @current_token = self.next
        end

        return @current_token
    end

end


class Parser
    def match( tok )
        raise "reject: #{tok} expected but seeing #{@s.peek.value}" unless tok == @s.peek.value
        puts @s.peek.value + " matches!"
        @s.next
    end

    # Start Production
    def nt_program
        puts "-> Program"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"

        # if peek is comments -> skip (epsilon production)
        if @s.peek.type == :comment
            puts "skip comment"
            @s.next
            nt_program
        else
            if @s.peek.type == :reserved
                nt_type
            end

            if @s.peek.value == '('
                func_decl
                func_list
            end
            puts "$$"
        end
    end


    def func_decl
        puts "-> func_decl"
        match('(')
        nt_parameter
        match(')')

        if @s.peek.value == '{'
            match('{')
            data_decls
            nt_statements
            match('}')
            nt_program
        else 
            match(';')
            nt_program
        end
    end



    def nt_statements
        puts "-> nt_statements"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"

        statement
        if @s.peek.value != "}"
            nt_statements 
        end
    end

    def statement
        puts "->statement"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"

        if @s.peek.value == 'if'
            nt_if_statement
        end
        if @s.peek.value == 'return'
            match('return')
            if @s.peek.value != ';'
                nt_expression
            end
            match(';')
        end
        if @s.peek.type == :ident
            nt_assignment
        end

        if @s.peek.value == 'while' 
            nt_while_statement
        end

        if @s.peek.value == 'printf'
            nt_prinf_func_call
        end

        if @s.peek.value == 'read'
            nt_read_func_call
        end

        if @s.peek.value == 'write'
            nt_write_func_call
        end

        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
    end

    def nt_read_func_call
        match('read')
        match('(')
        @s.next
        match(')')
        match(';')
    end

    def nt_write_func_call
        match('write')
        match('(')
        @s.next
        match(')')
        match(';')
    end

    def nt_prinf_func_call
        puts "-> printf_call"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
        match('printf')
        match('(')
        if @s.peek.type == :quote
            @s.next
        end
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
        if @s.peek.value == ','
            match(',')
            nt_expression
        end
        match(')')
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
        match(';')
    end

    def nt_while_statement
        puts "-> while statement"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"

        match('while')
        match('(')
        nt_condition_expression
        match(')')
        block_statements
    end

    def nt_assignment
        puts "-> nt_assignment"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"

        @s.next
        match('=')
        nt_expression
        match(';')
    end




    def nt_if_statement
        puts "-> if statement"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
        match('if')
        match('(')
        nt_condition_expression
        match(')')
        block_statements
        if @s.peek.value == 'else'
            puts "else is called"
            match('else')
            block_statements
        end
    end

    def block_statements
        puts "-> block_statements"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"

        match('{')
        nt_statements
        match('}')
    end








    def nt_condition_expression
        puts "-> condition expression"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"   
        nt_condition

        if @s.peek.value == '+' or @s.peek.value == '-'
            if @s.peek.value == '+'
                match('+')
            else
                match ('-')
            end
            nt_condition
            nt_condition_expression
        end

        if @s.peek.value == '=' or @s.peek.value == '!' or @s.peek.value == '>' or @s.peek.value == '<'
            nt_comparison_op
            nt_condition_expression
        end

        if @s.peek.value == '&&' or @s.peek.value == '||'
            nt_condition_op
            nt_condition_expression
        end
    end

    def nt_condition
        puts "-> nt_condition"
        if @s.peek.type == :ident or @s.peek.type == :number
            puts @s.next.value + " matched!"
        end
        @op = @s.peek.value
        puts @op + " is the operator"
        if @op == '==' or @op == '!=' or @op == '>' or @op == '<' or @op == '>=' or @op == '<='
            nt_comparison_op
        end
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"  

        if @s.peek.type == :ident or @s.peek.type == :number
            puts @s.next.value + " matched!"
        end
       
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"  
        
        if @s.peek.value == '('
            match('(')
            nt_expression
            
            puts "here4"

            match(')')
        end
    end


    def nt_comparison_op
        puts "-> comparison_op"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"  
        @op = @s.peek.value
        if @op == '==' 
            match('==')
            
        elsif @op == '!=' 
            match('!=')

        elsif @op == '>' 
            match('>')

        elsif @op == '<'
            match('<')

        elsif @op == '>=' 
            match('>=')
            
        else 
            match('<=')
        end
    end


    def nt_condition_op
        puts "-> condition_op"
        if @s.peek.value == '&' 
            match('&&')
        else 
            match('||')
        end
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
    end







    def nt_expression
        puts "-> expression"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
        
        if @s.peek.value == ';'
            return
        end
        if @s.peek.type == :symbol
            if @s.peek.value != ')'
                puts "here7"
                nt_term
                nt_operation
            end
        end

        if @s.peek.type == :ident
            puts "matched: " + @s.peek.value
            @s.next
            puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"


            if @s.peek.value == ','
                match(',')
                nt_expression
            end



            if @s.peek.value == ';'
                return
            end
            if @s.peek.value == '('
                match('(')
                puts "ident: " + @s.peek.value
                puts "here6"
                nt_expression
                match(')')
                if @s.peek.value == ';'
                    return
                end
            end

            nt_operation
            nt_expression

        elsif @s.peek.type == :number
            puts @s.peek.value + " is matched!"
            @s.next
            if @s.peek.value == ','
                match(',')
                nt_expression
            end

            if @s.peek.value == ';'
                return
            end
            nt_expression
        end
    end

    def nt_operation
        puts "-> operations"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"

        
        if @s.peek.value == ')'
            puts "here2"
            return
        elsif @s.peek.value == '*'
            match('*')
        elsif @s.peek.value == '/'
            match('/')
        elsif @s.peek.value == '+'
            match('+')
        else
            match('-')
        end    
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
    end


    def nt_term
        puts "-> term"
        if @s.peek.value == '('
            match('(')
            nt_expression
            match(')')
        end
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"

    end









    def nt_parameter
        puts "-> nt_parameter"
        if @s.peek.value != ')'
            #non-empty
            nt_type
            nt_ident
        end
    end

    def data_decls
        puts "-> data_decls"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
        if @s.peek.value == 'int' or @s.peek.value == 'void'
            nt_type
        end
    end

    def nt_type
        puts "-> type_name"
        if @s.peek.value == 'int'
            match( 'int' )
        else
            match( 'void' )
        end
        nt_ident
        puts "end of type"
    end

    # implement id[expression]
    def nt_ident 
        puts "-> identifier"
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
        if @s.peek.type == :reserved
            match('int')
        end

        if @s.peek.type == :ident
            @s.next
            if @s.peek.value == ','
                puts ", matched"
                @s.next
                nt_ident
            end

        end

        if @s.peek.value == ';'
            match(';')
        end
        puts @s.peek.value + " is (" + @s.peek.type.inspect + ")"
        puts "end of ident"
    end


    # Main Function
    def parse( input )
        @s = Scanner.new( input )
        nt_program
    end
end

Parser.new.parse( "tax.c" )

