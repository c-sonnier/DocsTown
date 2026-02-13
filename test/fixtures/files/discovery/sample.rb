module SampleModule
  class SampleClass
    # This method is documented
    def documented_method
      "hello"
    end

    def undocumented_method
      "world"
    end

    # :nodoc:
    def nodoc_method
      "hidden"
    end

    private

    def private_method
      "secret"
    end

    protected

    def protected_method
      "guarded"
    end

    public

    def public_after_private
      "visible"
    end

    def self.class_method_undocumented
      "class level"
    end

    # Documented class method
    def self.class_method_documented
      "class level documented"
    end
  end
end
