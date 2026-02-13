require "test_helper"

class Discovery::MethodParserTest < ActiveSupport::TestCase
  setup do
    @fixture_path = Rails.root.join("test", "fixtures", "files", "discovery")
  end

  test "finds undocumented public methods" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods

    signatures = methods.map(&:signature)

    assert_includes signatures, "SampleModule::SampleClass#undocumented_method"
    assert_includes signatures, "SampleModule::SampleClass#public_after_private"
    assert_includes signatures, "SampleModule::SampleClass.class_method_undocumented"
  end

  test "skips documented methods" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods
    signatures = methods.map(&:signature)

    assert_not_includes signatures, "SampleModule::SampleClass#documented_method"
    assert_not_includes signatures, "SampleModule::SampleClass.class_method_documented"
  end

  test "skips nodoc methods" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods
    signatures = methods.map(&:signature)

    assert_not_includes signatures, "SampleModule::SampleClass#nodoc_method"
  end

  test "skips private and protected methods" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods
    signatures = methods.map(&:signature)

    assert_not_includes signatures, "SampleModule::SampleClass#private_method"
    assert_not_includes signatures, "SampleModule::SampleClass#protected_method"
  end

  test "filters DSL-named methods" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods
    signatures = methods.map(&:signature)

    assert_not_includes signatures, "DslExample#has_many"
    assert_includes signatures, "DslExample#real_method"
  end

  test "extracts source code for each method" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods

    undoc = methods.find { |m| m.signature == "SampleModule::SampleClass#undocumented_method" }
    assert_not_nil undoc
    assert_includes undoc.source_code, "def undocumented_method"
    assert_includes undoc.source_code, '"world"'
  end

  test "extracts class context" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods

    undoc = methods.find { |m| m.signature == "SampleModule::SampleClass#undocumented_method" }
    assert_equal "SampleModule::SampleClass", undoc.class_context
  end

  test "includes source file path relative to repo root" do
    parser = Discovery::MethodParser.new(@fixture_path)
    methods = parser.find_undocumented_methods

    undoc = methods.find { |m| m.signature == "SampleModule::SampleClass#undocumented_method" }
    assert_equal "sample.rb", undoc.source_file_path
  end
end
