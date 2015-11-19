class YARD::Parser::Ruby::AstNode
  attr_accessor :comments_array, :loc
  alias location loc

  def initialize(type, arr, opts = {})
    super(arr)
    self.loc = opts[:loc]
    self.type = type
    self.line_range = opts[:line]
    self.source_range = opts[:char]
    @fallback_line = opts[:listline]
    @fallback_source = opts[:listchar]
    @token = true if opts[:token]
    @comments_array = []
  end

  def updated(type=nil, children=nil, properties=nil)
    new_type       = type       || @type
    new_children   = children   || @children || []
    new_properties = properties || {}

    if @type == new_type &&
        @children == new_children &&
        properties.nil?
      self
    else
      dup.send :initialize, new_type, new_children, new_properties
      @type = new_type
      self
    end
  end

  def full_source
    if location && location.expression
      location.expression.source
    else
      ''
    end
  end

  def docstring
    sanitized_comments
  end
  alias comments docstring

  protected
  def sanitized_comments
    @comments_array.map do |c|
      c.text.gsub(/^(\#+)\s{0,1}/, '').chomp
    end.join("\n")
  end
end

class YARD::Parser::Ruby::MethodDefinitionNode

  def method_name(name_only = false)
    name = self[index_adjust]
    if name.is_a? Symbol
      name = YARD::Parser::Ruby::AstNode.new(:ident, [name])
    end

    if parameters.named_params
      params = parameters.named_params.map(&:first).map(&:first).join(':')
      name = [name.jump(:ident).first.to_sym, params].join(':')
      name = YARD::Parser::Ruby::AstNode.new(:ident, [name + ':'])
    end
    name_only ? name.jump(:ident).first.to_sym : name
  end
end
