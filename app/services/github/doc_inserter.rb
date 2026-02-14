class Github::DocInserter
    MethodNotFound = Class.new(StandardError)

    def initialize(file_content, method_signature, documentation)
      @file_content = file_content
      @method_signature = method_signature
      @documentation = documentation
    end

    def call
      lines = @file_content.lines
      def_line_index = find_method_line(lines)
      raise MethodNotFound, "Method #{@method_signature} not found in source file" unless def_line_index

      indent = lines[def_line_index][/\A\s*/]
      comment_block = format_rdoc(indent)

      insert_index = find_insert_position(lines, def_line_index)

      need_blank_before = insert_index > 0 &&
        lines[insert_index - 1] &&
        !lines[insert_index - 1].strip.empty? &&
        !lines[insert_index - 1].strip.start_with?("#")

      result = lines.dup
      insertion = ""
      insertion += "\n" if need_blank_before
      insertion += comment_block
      result.insert(insert_index, insertion)
      result.join
    end

    private

    def find_method_line(lines)
      result = Prism.parse(@file_content)
      return nil unless result.success?

      visitor = MethodFinder.new(@method_signature, @file_content)
      result.value.accept(visitor)
      visitor.target_line
    end

    def find_insert_position(lines, def_line_index)
      index = def_line_index - 1
      while index >= 0
        stripped = lines[index].strip
        break if stripped.empty?
        break unless stripped.start_with?("#")
        index -= 1
      end
      index + 1
    end

    def format_rdoc(indent)
      @documentation.lines.map { |line|
        content = line.chomp
        if content.empty?
          "#{indent}#\n"
        else
          "#{indent}# #{content}\n"
        end
      }.join
    end

    class MethodFinder < Prism::Visitor
      include Discovery::NamespaceTracking

      attr_reader :target_line

      def initialize(method_signature, source)
        @method_signature = method_signature
        @source = source
        @target_line = nil
        initialize_namespace_tracking
      end

      def visit_def_node(node)
        signature = build_signature(node)
        if signature == @method_signature
          @target_line = node.location.start_line - 1
        end
      end
    end
end
