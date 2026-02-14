module Discovery
  module NamespaceTracking
    def initialize_namespace_tracking
      @namespace_stack = []
    end

    def visit_class_node(node)
      @namespace_stack.push(node_name(node))
      super
      @namespace_stack.pop
    end

    def visit_module_node(node)
      @namespace_stack.push(node_name(node))
      super
      @namespace_stack.pop
    end

    private

    def node_name(node)
      case node
      when Prism::ClassNode
        node.constant_path.slice
      when Prism::ModuleNode
        node.constant_path.slice
      end
    end

    def build_signature(node)
      prefix = current_namespace
      separator = node.receiver ? "." : "#"
      name = node.name.to_s
      prefix.empty? ? name : "#{prefix}#{separator}#{name}"
    end

    def current_namespace
      @namespace_stack.join("::")
    end
  end
end
