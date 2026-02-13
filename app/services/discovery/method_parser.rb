module Discovery
  class MethodParser
    UndocumentedMethod = Data.define(:signature, :source_file_path, :source_code, :class_context)

    DSL_METHOD_NAMES = %w[
      has_many has_one belongs_to has_and_belongs_to_many
      scope default_scope
      delegate delegate_missing_to
      attr_accessor attr_reader attr_writer
      alias_method alias_attribute
      class_attribute mattr_accessor mattr_reader mattr_writer
      cattr_accessor cattr_reader cattr_writer
      serialize store
      enum
      validates validates_presence_of validates_uniqueness_of validates_inclusion_of
      validate
      before_action after_action around_action
      before_validation after_validation
      before_save after_save before_create after_create
      before_update after_update before_destroy after_destroy
      after_commit after_create_commit after_update_commit after_destroy_commit
      rescue_from
      helper_method
    ].freeze

    def initialize(repo_path)
      @repo_path = repo_path
    end

    def find_undocumented_methods
      ruby_files.flat_map { |file| parse_file(file) }
    end

    private

    def ruby_files
      Dir.glob(File.join(@repo_path, "**", "*.rb")).reject do |f|
        relative = f.sub("#{@repo_path}/", "")
        relative.start_with?("test/", "spec/", "vendor/")
      end
    end

    def parse_file(file_path)
      source = File.read(file_path)
      result = Prism.parse(source)
      return [] unless result.success?

      relative_path = file_path.sub("#{@repo_path}/", "")
      visitor = MethodVisitor.new(source, relative_path)
      result.value.accept(visitor)
      visitor.undocumented_methods
    rescue => e
      Rails.logger.warn("MethodParser: failed to parse #{file_path}: #{e.message}")
      []
    end

    class MethodVisitor < Prism::Visitor
      attr_reader :undocumented_methods

      def initialize(source, file_path)
        @source = source
        @source_lines = source.lines
        @file_path = file_path
        @undocumented_methods = []
        @namespace_stack = []
        @visibility = :public
        @visibility_stack = []
      end

      def visit_class_node(node)
        @namespace_stack.push(node_name(node))
        @visibility_stack.push(@visibility)
        @visibility = :public
        super
        @visibility = @visibility_stack.pop
        @namespace_stack.pop
      end

      def visit_module_node(node)
        @namespace_stack.push(node_name(node))
        @visibility_stack.push(@visibility)
        @visibility = :public
        super
        @visibility = @visibility_stack.pop
        @namespace_stack.pop
      end

      def visit_def_node(node)
        return unless @visibility == :public
        return if nodoc?(node)
        return if documented?(node)
        return if dsl_method?(node)

        signature = build_signature(node)
        source_code = extract_source(node)
        class_context = current_namespace

        @undocumented_methods << UndocumentedMethod.new(
          signature: signature,
          source_file_path: @file_path,
          source_code: source_code,
          class_context: class_context
        )
      end

      def visit_call_node(node)
        case node.name.to_s
        when "private"
          if node.arguments.nil?
            @visibility = :private
          end
        when "protected"
          if node.arguments.nil?
            @visibility = :protected
          end
        when "public"
          if node.arguments.nil?
            @visibility = :public
          end
        end
        super
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

      def documented?(node)
        start_line = node.location.start_line - 1
        return false if start_line == 0

        line_above = start_line - 1
        while line_above >= 0
          line = @source_lines[line_above]
          break if line.nil?
          stripped = line.strip
          break if stripped.empty?

          return true if stripped.start_with?("#")
          break
        end

        false
      end

      def nodoc?(node)
        start_line = node.location.start_line - 1
        return false if start_line == 0

        line_above = start_line - 1
        while line_above >= 0
          line = @source_lines[line_above]
          break if line.nil?
          stripped = line.strip
          break if stripped.empty?

          return true if stripped.include?(":nodoc:")
          return false unless stripped.start_with?("#")
          line_above -= 1
        end

        false
      end

      def dsl_method?(node)
        name = node.name.to_s
        DSL_METHOD_NAMES.include?(name)
      end

      def extract_source(node)
        start_line = node.location.start_line - 1
        end_line = node.location.end_line - 1
        @source_lines[start_line..end_line].join
      end
    end
  end
end
