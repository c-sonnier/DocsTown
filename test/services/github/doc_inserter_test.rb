require "test_helper"

class Github::DocInserterTest < ActiveSupport::TestCase
  test "inserts documentation before a simple method" do
    source = <<~RUBY
      class Foo
        def bar
          42
        end
      end
    RUBY

    doc = "Returns the answer.\n"
    result = Github::DocInserter.new(source, "Foo#bar", doc).call

    assert_includes result, "  # Returns the answer.\n  def bar"
  end

  test "inserts documentation with correct indentation for nested class" do
    source = <<~RUBY
      module Outer
        class Inner
          def deep_method
            true
          end
        end
      end
    RUBY

    doc = "A deeply nested method.\n"
    result = Github::DocInserter.new(source, "Outer::Inner#deep_method", doc).call

    assert_includes result, "    # A deeply nested method.\n    def deep_method"
  end

  test "inserts documentation for a class method (def self.foo)" do
    source = <<~RUBY
      class MyClass
        def self.class_method
          :hello
        end
      end
    RUBY

    doc = "A class method.\n"
    result = Github::DocInserter.new(source, "MyClass.class_method", doc).call

    assert_includes result, "  # A class method.\n  def self.class_method"
  end

  test "handles multi-line documentation" do
    source = <<~RUBY
      class Foo
        def bar(x, y)
          x + y
        end
      end
    RUBY

    doc = "Adds two numbers.\n\nParameters:\n  x - first number\n  y - second number\n"
    result = Github::DocInserter.new(source, "Foo#bar", doc).call

    lines = result.lines
    def_index = lines.index { |l| l.include?("def bar") }
    assert def_index > 4
    assert_includes result, "  # Adds two numbers."
    assert_includes result, "  # Parameters:"
    assert_includes result, "  #   x - first number"
  end

  test "raises MethodNotFound when method does not exist" do
    source = <<~RUBY
      class Foo
        def bar
          42
        end
      end
    RUBY

    assert_raises(Github::DocInserter::MethodNotFound) do
      Github::DocInserter.new(source, "Foo#nonexistent", "docs").call
    end
  end

  test "inserts before existing comment block" do
    source = <<~RUBY
      class Foo
        # :call-seq:
        #   bar -> Integer
        def bar
          42
        end
      end
    RUBY

    doc = "Returns the answer.\n"
    result = Github::DocInserter.new(source, "Foo#bar", doc).call

    lines = result.lines
    doc_line = lines.index { |l| l.include?("# Returns the answer.") }
    callseq_line = lines.index { |l| l.include?("# :call-seq:") }

    assert doc_line < callseq_line, "New doc should be inserted before existing comments"
  end

  test "adds blank line before doc when preceded by code" do
    source = <<~RUBY
      class Foo
        CONSTANT = 42
        def bar
          CONSTANT
        end
      end
    RUBY

    doc = "Returns the constant.\n"
    result = Github::DocInserter.new(source, "Foo#bar", doc).call

    lines = result.lines
    const_index = lines.index { |l| l.include?("CONSTANT = 42") }
    doc_index = lines.index { |l| l.include?("# Returns the constant.") }
    blank_between = lines[(const_index + 1)...doc_index].any? { |l| l.strip.empty? }
    assert blank_between, "Should have blank line between code and new doc"
  end

  test "handles method with parameters" do
    source = <<~RUBY
      class Calculator
        def add(a, b)
          a + b
        end
      end
    RUBY

    doc = "Adds a and b.\n"
    result = Github::DocInserter.new(source, "Calculator#add", doc).call

    assert_includes result, "  # Adds a and b.\n  def add(a, b)"
  end

  test "handles file with no trailing newline" do
    source = "class Foo\n  def bar\n    42\n  end\nend"

    doc = "Returns 42.\n"
    result = Github::DocInserter.new(source, "Foo#bar", doc).call

    assert_includes result, "# Returns 42."
    assert_includes result, "def bar"
  end

  test "handles empty lines in documentation" do
    source = <<~RUBY
      class Foo
        def bar
          42
        end
      end
    RUBY

    doc = "First paragraph.\n\nSecond paragraph.\n"
    result = Github::DocInserter.new(source, "Foo#bar", doc).call

    assert_includes result, "  # First paragraph.\n  #\n  # Second paragraph."
  end
end
