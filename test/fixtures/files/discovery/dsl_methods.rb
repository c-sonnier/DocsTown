class DslExample
  def has_many
    "this shadows the DSL but is a real method"
  end

  def real_method
    "should be detected"
  end
end
