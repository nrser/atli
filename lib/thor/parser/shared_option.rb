require 'set'

class Thor
  # A {Thor::Option} that has an additional {#groups} attribute storing a
  # set of group symbols that the option is a part of.
  # 
  class SharedOption < Option
    
    # Shared option groups this option belongs to.
    # 
    # @return [Set<Symbol>]
    #     
    attr_reader :groups
    
    # 
    # 
    def initialize name, **options
      super name, options
      
      @groups = Set.new [*options[:groups]].map( &:to_sym )
    end
  end
end
