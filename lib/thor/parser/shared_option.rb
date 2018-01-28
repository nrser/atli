class Thor
  # A +Thor::Option+ that has an additional #groups attribute
  class SharedOption < Option
    
    # Shared option groups this option belongs to.
    # 
    # Returns an Array of Symbol.
    #     
    attr_reader :groups
    

    def initialize(name, options = {})
      super name, options
      
      @groups = if options.key? :groups
        if options[:groups].is_a? Array
          options[:groups]
        else
          [options[:groups]]
        end
      else
        []
      end
    end
  end
end
