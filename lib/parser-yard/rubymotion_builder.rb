# List of all known keywords
# @return [Hash]
KEYWORDS = { :class => true, :alias => true, :lambda => true, :do_block => true,
  :def => true, :defs => true, :begin => true, :rescue => true, :rescue_mod => true,
  :if => true, :if_mod => true, :else => true, :elsif => true, :case => true,
  :when => true, :next => true, :break => true, :retry => true, :redo => true,
  :return => true, :throw => true, :catch => true, :until => true, :until_mod => true,
  :while => true, :while_mod => true, :yield => true, :yield0 => true, :zsuper => true,
  :unless => true, :unless_mod => true, :for => true, :super => true, :return0 => true }


class Parser::Builders::RubyMotionBuilder < Parser::Builders::Default
  def n(type, children, location)
    klass = node_class_for(type)
    line = nil
    char = nil

    fchildren = children.select {|e| ::Parser::AST::Node === e }
    f, l = fchildren.first, fchildren.last
    if f && l
      f = f.location.expression
      l = l.location.expression
      self.line_range = Range.new(f.first_line, l.last_line)
      self.source_range = Range.new(f.begin_pos, l.end_pos)
      line = Range.new(f.first_line, l.last_line)
      char = Range.new(f.begin_pos, l.end_pos)
    else
      line = 0...0
      char = 0...0
    end

    if type == :args
      children = process_args_children(children)
    end

    if type == :def
      children = process_def_children(children)
    end

    if type == :optarg
      location = Parser::Source::Map.new(location.name)
      children[0] = YARD::Parser::Ruby::AstNode.new(:ident, [children[0]], :loc => location)
    end

    if type == :blockarg || type == :restarg
      begin_pos = location.expression.begin_pos + 1
      end_pos = location.expression.end_pos
      expression = Parser::Source::Range.new(location.expression.source_buffer, begin_pos, end_pos)
      location = Parser::Source::Map.new(expression)
    end

    if type == :objc_kwarg
      begin_pos = location.keyword.begin_pos
      end_pos = location.operator.end_pos
      expression = Parser::Source::Range.new(location.expression.source_buffer, begin_pos, end_pos)
      loc = Parser::Source::Map.new(expression)
      children[0] = YARD::Parser::Ruby::AstNode.new(:ident, [children[0]], :loc => loc)
      loc = Parser::Source::Map.new(location.argument)
      children[1] = YARD::Parser::Ruby::AstNode.new(:ident, [children[1]], :loc => loc)
      type = :named_arg
    end

    if type == :begin
      type = :list
    end

    if (type == :module || type == :class) && children.last.nil?
      children[-1] = YARD::Parser::Ruby::AstNode.new(:void_stmt, [])
    end

    if type == :defs
      children[0] = YARD::Parser::Ruby::AstNode.new(:period, ['.'])
      self_node = YARD::Parser::Ruby::AstNode.new(:kw, ['self'])
      children.unshift(YARD::Parser::Ruby::AstNode.new(:var_ref, [self_node]))
      children[2] = YARD::Parser::Ruby::AstNode.new(:ident, [children[2]])
      children[-1] = YARD::Parser::Ruby::AstNode.new(:void_stmt, []) if children.last.nil?
    end

    return klass.new(type, children, :line => line, :char => char, :loc => location)
  end

  def process_def_children(children)
    name = YARD::Parser::Ruby::AstNode.new(:ident, [children[0]])
    params = children[1]
    new_children = [name, params]
  end

  def process_args_children(children)
    new_children = [nil, nil, nil, nil, nil, nil, nil]

    new_children[0] = children.select { |c| c.type == :arg }
    new_children[1] = children.select { |c| c.type == :optarg }
    new_children[2] = children.select { |c| c.type == :restarg }
    new_children[3] = []
    new_children[4] = children.select { |c| c.type == :named_arg }
    new_children[5] = []
    new_children[6] = children.select { |c| c.type == :blockarg }

    new_children
  end

  def node_class_for(type)
    case type
    when :args
      YARD::Parser::Ruby::ParameterNode
    when :send, :block
      YARD::Parser::Ruby::MethodCallNode
    when :if, :elsif, :if_mod, :unless, :unless_mod
      YARD::Parser::Ruby::ConditionalNode
    when :for, :while, :while_mod, :until, :until_mod
      YARD::Parser::Ruby::LoopNode
    when :def, :defs
      YARD::Parser::Ruby::MethodDefinitionNode
    when :class
      YARD::Parser::Ruby::ClassNode
    when :module
      YARD::Parser::Ruby::ModuleNode
    else
      if type.to_s =~ /_ref\Z/
        YARD::Parser::Ruby::ReferenceNode
      elsif type.to_s =~ /_literal\Z/
        YARD::Parser::Ruby::LiteralNode
      elsif KEYWORDS.has_key?(type)
        YARD::Parser::Ruby::KeywordNode
      else
        YARD::Parser::Ruby::AstNode
      end
    end
  end
end
