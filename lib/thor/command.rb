require 'semantic_logger'

class Thor
  class Command < Struct.new( :name,
                              :description,
                              :long_description,
                              :usage,
                              :examples,
                              :options,
                              :ancestor_name )
    include SemanticLogger::Loggable
    
    FILE_REGEXP = /^#{Regexp.escape(File.dirname(__FILE__))}/

    def initialize  name:,
                    description: nil,
                    long_description: nil,
                    usage: nil,
                    examples: [],
                    options: nil
      super \
        name.to_s,
        description,
        long_description,
        usage,
        examples,
        options || {}
    end

    def initialize_copy(other) #:nodoc:
      super(other)
      self.options = other.options.dup if other.options
    end

    def hidden?
      false
    end
    
    
    # Run a command by calling the actual method on the {Thor::Base} instance.
    # 
    # By default, a command invokes a method in the thor class. You can change
    # this implementation to create custom commands.
    # 
    # @param [Thor::Base] instance
    #   Thor class instance the command is being run for.
    # 
    # @param [Array<?>] args
    #   Arguments for the command.
    # 
    # @return
    #   The return value of the command method on `instance`.
    # 
    # @raise [Thor::InvocationError]
    #   1.  When we find a suitable method on `instance` to call, but it
    #       raised and {ArgumentError} **and** {#handle_argument_error?}
    #       returned `true`.
    # 
    def run instance, args = []
      logger.debug "Command#run",
        name: self.name,
        args: args
      
      # raise "BAD!!!" unless args.include? '--'
      
      # Declaration for arity of the method, which is set in (2) below and
      # used when handling raised {ArgumentError}
      arity = nil
      
      # Method invocation switch - figure out how to make the method call to
      # `instance`, or error out.
      # 
      # Cases:
      # 
      # 1.  Protect from calling private methods by error'ing out if {#name}
      #     is the name of a private method of `instance`.
      #     
      result = if private_method? instance
        instance.class.handle_no_command_error name
      
      # 2.  The success case - if {#name} is a public method of `instance`
      #     than call it with `args`.
      #     
      elsif public_method? instance
        # Save the arity to use when handling {ArgumentError} below
        # 
        # TODO  Why does it fetch the {Method} *then* use {#__send__} instead
        #       of just `#call` it?
        #       
        arity = instance.method( name ).arity
        
        # Unless the method is a subcommand, remove any '--' separators
        # since we know we're done option parsin'
        unless subcommand? instance, name
          args = args.reject { |arg| arg == '--' }
        end
        
        # Do that call
        instance.__send__ name, *args
      
      # 3.  If the {Thor} instance has a `#method_missing` defined in *itself*
      #     (not any super class) than call that.
      #     
      elsif local_method? instance, :method_missing
        instance.__send__ :method_missing, name.to_sym, *args
      
      # 4.  We got nothing... pass of to
      #     {Thor::Base::ClassMethods.handle_no_command_error}
      #     which will raise.
      #     
      else
        instance.class.handle_no_command_error name
      
      end # Method invocation switch
      
      instance.__send__ :on_run_success, result, self, args
      
    rescue ArgumentError => error
      if handle_argument_error? instance, error, caller
        # NOTE  I *believe* `arity` could still be `nil`, assuming that
        #       (3) could raise {ArgumentError} and end up here.
        #       
        #       However...
        instance.class.handle_argument_error self, error, args, arity
      else
        raise error
      end
    
    rescue NoMethodError => error
      if handle_no_method_error? instance, error, caller
        instance.class.handle_no_command_error name
      else
        raise error
      end
    
    rescue Exception => error
      # NOTE  Need to use `#__send__` because the instance may define a
      #       command (method) `#send` - and one of the test fixtures **does**:
      #       
      #       //spec/fixtures/script.thor:100
      #       
      #       That's why the Thor code above uses `#__send__`, and we need to
      #       too.
      #       
      instance.__send__ :on_run_error, error, self, args
      
      # We should not get here!!!
      # {Thor::Base#on_run_error} should exit or re-raise :(
      logger.error "#on_run_error failed to exit or re-raise", error: error
      
      # If you want something done right...
      raise error
    end # #run
    

    # Returns the formatted usage by injecting given required arguments
    # and required options into the given usage.
    def formatted_usage(klass, namespace = true, subcommand = false)
      logger.trace "Formatting usage",
        self: self,
        klass: klass,
        namespace: namespace,
        subcommand: subcommand,
        ancestor_name: ancestor_name
      
      if ancestor_name
        formatted = "#{ancestor_name} ".dup # add space
      elsif namespace
        namespace = klass.namespace
        formatted = "#{namespace.gsub(/^(default)/, '')}:".dup
      end
      formatted ||= "#{klass.namespace.split(':').last} ".dup if subcommand

      formatted ||= "".dup

      # Add usage with required arguments
      formatted << if klass && !klass.arguments.empty?
                     usage.to_s.gsub(/^#{name}/) do |match|
                       match  << " " \
                              << klass.arguments.map(&:usage).compact.join(" ")
                     end
                   else
                     usage.to_s
                   end

      # Add required options
      formatted << " #{required_options}"

      # Strip and go!
      formatted.strip
    end

  protected

    def not_debugging?(instance)
      !(instance.class.respond_to?(:debugging) && instance.class.debugging)
    end

    def required_options
      @required_options ||= options.
        map { |_, o| o.usage if o.required? }.
        compact.
        sort.
        join(" ")
    end
    
    
    
    # Is `name` a subcommand of `instance`?
    # 
    # @param [Thor::Base] instance
    #   The Thor instance this command is being run for.
    # 
    # @param [Symbol | String] name
    #   The subcommand / method name.
    # 
    # @return [return_type]
    #   @todo Document return value.
    # 
    def subcommand? instance, name
      # It doesn't look like {Thor::Group} has `.subcommands`, so test for
      # that first.
      return false unless instance.class.respond_to?( :subcommands )
      
      # See if the names is in the subcommands
      instance.class.subcommands.include? name.to_s
    end # #subcommand?
    
    
    
    # Is this command's {#name} a public method of `instance`?
    # 
    # @param [Thor::Base] instance
    #   The Thor instance this command is being run for.
    # 
    # @return [Boolean]
    #   `true` if {#name} is a public method of `instance`.
    # 
    def public_method?(instance) #:nodoc:
      !(instance.public_methods & [name.to_s, name.to_sym]).empty?
    end
    
    
    # Is this command's {#name} a private method of `instance`?
    # 
    # @param [Thor::Base] instance
    #   The Thor instance this command is being run for.
    # 
    # @return [Boolean]
    #   `true` if {#name} is a private method of `instance`.
    # 
    def private_method?(instance)
      !(instance.private_methods & [name.to_s, name.to_sym]).empty?
    end
    
    
    # Is `name` the name of a method defined in `instance` itself (not
    # any super class)?
    # 
    # @param [Thor::Base] instance
    #   The Thor instance this command is being run for.
    # 
    # @param [Symbol | String] name
    #   The method name.
    # 
    # @return [Boolean]
    #   `true` if `name` is the name of a method defined in `instance` itself.
    # 
    def local_method?(instance, name)
      methods = instance.public_methods(false) +
                instance.private_methods(false) +
                instance.protected_methods(false)
      !(methods & [name.to_s, name.to_sym]).empty?
    end
    

    def sans_backtrace(backtrace, caller) #:nodoc:
      saned = backtrace.reject { |frame|
        (frame =~ FILE_REGEXP) ||
        (frame =~ /\.java:/ && RUBY_PLATFORM =~ /java/) ||
        (frame =~ %r{^kernel/} && RUBY_ENGINE =~ /rbx/)
      }
      saned - caller
    end

    def handle_argument_error?(instance, error, caller)
      not_debugging?(instance) \
      && (  error.message =~ /wrong number of arguments/ \
            || error.message =~ /given \d*, expected \d*/ ) \
      && begin
        saned = sans_backtrace(error.backtrace, caller)
        # Ruby 1.9 always include the called method in the backtrace
        saned.empty? || (saned.size == 1 && RUBY_VERSION >= "1.9")
      end
    end

    def handle_no_method_error?(instance, error, caller)
      not_debugging?(instance) &&
        error.message =~ \
          /^undefined method `#{name}' for #{Regexp.escape(instance.to_s)}$/
    end
  end
  Task = Command

  # A command that is hidden in help messages but still invocable.
  class HiddenCommand < Command
    def hidden?
      true
    end
  end
  HiddenTask = HiddenCommand

  # A dynamic command that handles method missing scenarios.
  class DynamicCommand < Command
    def initialize(name, options = nil)
      super(  name: name.to_s,
              description: "A dynamically-generated command",
              long_description: name.to_s, # why?!
              usage: name.to_s,
              options: options )
    end

    def run(instance, args = [])
      if (instance.methods & [name.to_s, name.to_sym]).empty?
        super
      else
        instance.class.handle_no_command_error(name)
      end
    end
  end
  DynamicTask = DynamicCommand
end
