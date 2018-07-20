class Thor
  class Argument
    
    # Constants
    # ========================================================================

    VALID_TYPES = [:numeric, :hash, :array, :string]

    
    # Mixins
    # ========================================================================

    include NRSER::Log::Mixin

    
    # Attributes
    # ========================================================================

    attr_reader :name, :description, :enum, :required, :type, :default, :banner
    

    # Optional block to provide dynamic shell completion.
    # 
    # @return [nil]
    #   This argument does not provide dynamic completion.
    # 
    # @return [Proc<() => Array<String>>]
    #   Arity `0` proc that will be called with no arguments to provide 
    #   dynamic completion options.
    # 
    # @return [Proc<(request:, klass:, command:) => Array<String>]
    #   Arity `-1` proc that will be passed:
    #   
    #   -   {Thor::Completion::Bash::Request} `request:`
    #       The completion request.
    #       
    #   -   {Class<Thor::Base>} `klass:`
    #       The {Thor} or {Thor::Group} subclass being completed.
    #       
    #   -   {Thor::Command} `command:`
    #       The command being completed.
    #   
    #   As in the arity `0` case, must return an array of string completion
    #   options.
    #     
    attr_reader :complete
    

    alias_method :human_name, :name

    def initialize(name, options = {})
      class_name = self.class.name.split("::").last

      type = options[:type]

      if name.nil?
        raise ArgumentError,
          "#{class_name} name can't be nil."
      end

      if type && !valid_type?(type)
        raise ArgumentError,
          "Type :#{type} is not valid for #{class_name.downcase}s."
      end

      @name         = name.to_s
      @description  = options[:desc]
      @required     = options.key?(:required) ? options[:required] : true
      @type         = (type || :string).to_sym
      @default      = options[:default]
      @banner       = options[:banner] || default_banner
      @enum         = options[:enum]
      @complete     = options[:complete]

      validate! # Trigger specific validations
    end

    def usage
      required? ? banner : "[#{banner}]"
    end

    def required?
      required
    end

    def show_default?
      case default
      when Array, String, Hash
        !default.empty?
      else
        default
      end
    end

  protected

    def validate!
      if required? && !default.nil?
        raise ArgumentError,
          "An argument cannot be required and have default value."
      end
      
      if @enum && !@enum.is_a?(Array)
        raise ArgumentError,
          "An argument cannot have an enum other than an array."
      end
    end

    def valid_type?(type)
      self.class::VALID_TYPES.include?(type.to_sym)
    end

    def default_banner
      case type
      when :boolean
        nil
      when :string, :default
        human_name.upcase
      when :numeric
        "N"
      when :hash
        "key:value"
      when :array
        "one two three"
      end
    end
  end
end
