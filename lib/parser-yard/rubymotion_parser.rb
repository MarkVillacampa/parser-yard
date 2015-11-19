module Parser
  module Source
    class Comment::EmbeddedAssociator < Comment::Associator
      def associate_and_advance_comment(node)
        key = @map_using_locations ? node.location : node
        key.comments_array << @current_comment
        advance_comment
      end

      def visit(node)
        process_leading_comments(node)

        node.children.each do |child|
          next unless child.is_a?(YARD::Parser::Ruby::AstNode) && child.loc && child.loc.expression
          visit(child)
        end

        process_trailing_comments(node)
      end
    end
  end
end

class RubyMotionParser < YARD::Parser::Base

  attr_reader :ast

  def self.parse(source, filename = nil)
    new(source, filename).parse
  end

  def initialize(source, filename)
    @source = source
    @filename = filename
  end

  def parse
    parser = Parser::RubyMotion.new(Parser::Builders::RubyMotionBuilder.new)
    source_buffer = Parser::Source::Buffer.new(@filename, 1)
    source_buffer.source = @source
    @ast, comments = parser.parse_with_comments(source_buffer)
    Parser::Source::Comment::EmbeddedAssociator.new(@ast, comments).associate
    if @ast && @ast.type != :list
      @ast = [@ast]
    end
    self
  end

  def tokenize
    raise NotImplementedError, "#{self.class} does not support tokenization"
  end

  def enumerator
    if @ast.is_a? Array
      @ast
    else
      [@ast].compact
    end
  end

end
