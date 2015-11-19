# Handles any constant assignment
class YARD::Handlers::Ruby::ConstantAssignmentHandler < YARD::Handlers::Ruby::Base
  handles :casgn
  namespace_only

  process do
    if statement.type == :casgn
      register ConstantObject.new(namespace, statement[1]) {|o| o.source = statement.source; o.value = statement[2].source}
      return
    end
  end
end
