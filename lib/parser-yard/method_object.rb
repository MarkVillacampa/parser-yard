class YARD::CodeObjects::MethodObject
  def name(prefix = false)
    name = @name.to_s.split(':').first
    prefix ? name : name.to_sym
  end

  def super_path
    if parent && !parent.root?
      [parent.path, @name].join(sep)
    else
      @name.to_s
    end
  end

  def path
    if !namespace || namespace.path == ""
      sep + super_path
    else
      super_path
    end
  end
  alias_method :to_s, :path
end
