# tirivial grammar for CS 254, University of Rochester
# E -> x + T 
# T -> ( E ) | x

class Scanner
  def initialize( str )
    @input = StringIO.new( str )
    @cur_tok = @input.getc
    puts @input
  end

  def match( tok )
    raise "reject: #{tok} expected but seeing #{@cur_tok}" unless tok == @cur_tok
    @cur_tok = @input.getc
  end

  def peek
    return @cur_tok
  end

  def end?
    return @input.eof?
  end
end

class Parser
  def nt_e
    @s.match( 'x' )
    @s.match( '+' )
    nt_t
  end

  def nt_t
    if @s.peek == '('
      @s.match( '(' )
      nt_e
      @s.match( ')' )
    else
      @s.match( 'x' )
    end
  end

  def parse( input )
    @s = Scanner.new( input )
      nt_e
      if @s.end?
        puts 'accept!'
      else
        puts 'reject: extra tokens'
      end
  end
end

# Examples:
Parser.new.parse( "x+x" )
# Parser.new.parse( "x+(x)" )
# Parser.new.parse( "x+(x+x)" )
# Parser.new.parse( "x+(x+x)+x" )





