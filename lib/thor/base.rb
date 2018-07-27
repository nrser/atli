# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------
require 'nrser'

# Project / Package
# -----------------------------------------------------------------------
require "thor/command"
require "thor/core_ext/hash_with_indifferent_access"
require "thor/error"
require "thor/invocation"
require "thor/parser"
require "thor/shell"
require "thor/line_editor"
require "thor/util"
require 'thor/execution'
require 'thor/base/class_methods'
require 'thor/base/arguments_concern'
require 'thor/base/shared_concern'


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types


class Thor
  autoload :Actions,    "thor/actions"
  autoload :RakeCompat, "thor/rake_compat"
  autoload :Group,      "thor/group"

  # Shortcuts for help.
  HELP_MAPPINGS       = %w(-h -? --help -D)

  # Thor methods that should not be overwritten by the user.
  THOR_RESERVED_WORDS = %w(invoke shell options behavior root destination_root
                            relative_root action add_file create_file in_root
                            inside run run_ruby_script)

  TEMPLATE_EXTNAME = ".tt"
  
  # Shared base behavior included in {Thor} and {Thor::Group}.
  # 
  module Base
    
    # Module Methods
    # ============================================================================
    
    # Hook called when {Thor::Base} is mixed in ({Thor} and {Thor::Group}).
    # 
    # Extends `base` with {Thor::Base::ClassMethods}, and includes
    # {Thor::Invocation} and {Thor::Shell} in `base` as well.
    # 
    # @param [Module] base
    #   Module (or Class) that included {Thor::Base}.
    # 
    # @return [void]
    # 
    def self.included base
      base.extend ClassMethods
      base.send :include, Invocation
      base.send :include, Shell
      base.send :include, ArgumentsConcern
      base.send :include, SharedConcern
      
      base.no_commands {
        base.send :include, NRSER::Log::Mixin
      }
      
    end

    # Returns the classes that inherits from Thor or Thor::Group.
    #
    # ==== Returns
    # Array[Class]
    #
    def self.subclasses
      @subclasses ||= []
    end

    # Returns the files where the subclasses are kept.
    #
    # ==== Returns
    # Hash[path<String> => Class]
    #
    def self.subclass_files
      @subclass_files ||= Hash.new { |h, k| h[k] = [] }
    end

    # Whenever a class inherits from Thor or Thor::Group, we should track the
    # class and the file on Thor::Base. This is the method responsible for it.
    #
    def self.register_klass_file(klass) #:nodoc:
      file = caller[1].match(/(.*):\d+/)[1]
      unless Thor::Base.subclasses.include?(klass)
        Thor::Base.subclasses << klass
      end

      file_subclasses = Thor::Base.subclass_files[File.expand_path(file)]
      file_subclasses << klass unless file_subclasses.include?(klass)
    end

    
    # Attributes
    # ========================================================================

    attr_accessor :options, :parent_options, :args


    # Construction
    # ========================================================================

    # It receives arguments in an Array and two hashes, one for options and
    # other for configuration.
    #
    # Notice that it does not check if all required arguments were supplied.
    # It should be done by the parser.
    #
    # ==== Parameters
    # args<Array[Object]>:: An array of objects. The objects are applied to
    #                       their respective accessors declared with
    #                       <tt>argument</tt>.
    #
    # options<Hash>:: An options hash that will be available as self.options.
    #                 The hash given is converted to a hash with indifferent
    #                 access, magic predicates (options.skip?) and then frozen.
    #
    # config<Hash>:: Configuration for this Thor class.
    #
    def initialize args = [], options_args_or_defaults = {}, config = {}
      # Before {#initialize} is called arguments have been split out into
      # either:
      # 
      # 1.  Positional `args` and args that need to be parsed for options.
      # 
      # 2.  Positional `args` and already parsed option values that we call
      #     "defaults".

      if options_args_or_defaults.is_a? Array
        # Case (1)
        # 
        # The start method splits inbound arguments at the first argument
        # that looks like an option (starts with - or --). It then calls
        # new, passing in the two halves of the arguments Array as the
        # first two parameters.
        # 
        # In this case the first Array stays as `args` and the second Array
        # gets assigned to `args_to_parse_for_options` to be parsed for
        # options:
        # 
        args_to_parse_for_options = options_args_or_defaults
        option_defaults = {}
      else
        # Case (2)
        # 
        # Handle the case where the class was explicitly instantiated
        # with pre-parsed options.
        # 
        args_to_parse_for_options = []
        option_defaults = options_args_or_defaults
      end

      logger.debug "#{ self.class.name }#initialize",
        args:                       args,
        options_args_or_defaults:   options_args_or_defaults,
        args_to_parse_for_options:  args_to_parse_for_options,
        option_defaults:            option_defaults

      # Let {Thor::Options} parse the options first, so it can remove
      # declared options from the array. This will leave us with
      # a list of arguments that weren't declared.

      # Hash of {Thor::Option} that we can parse from the CLI args
      # keyed by their {Thor::Option#name}.
      # 
      # @type [HashWithIndifferentAccess<String, Thor::Option>]
      # 
      options_to_parse_by_name = [
        # Add class-level options
        self.class.class_options,

        # Options passed in by {Thor.dispatch} for the command to be
        # invoked. May be `nil`, though I'm not totally sure when... in that
        # case those options won't be parsed.
        # 
        # This was
        # 
        #     config.delete( :command_options ),
        # 
        # though I can't figure out why. Specs still pass without it..
        # 
        config[:command_options],
      ].compact.reduce( HashWithIndifferentAccess.new, :merge! )

      stop_on_unknown = \
        self.class.stop_on_unknown_option? config[:current_command]
      
      disable_required_check = \
        self.class.disable_required_check? config[:current_command]

      logger.trace "Ready to create options",
        options_to_parse_by_name:     options_to_parse_by_name,
        option_defaults:              option_defaults,
        stop_on_unknown:              stop_on_unknown,
        disable_required_check:       disable_required_check,
        args:                         args,
        args_to_parse_for_options:    args_to_parse_for_options
      
      options_parser = Thor::Options.new \
        options_to_parse_by_name,
        option_defaults,
        stop_on_unknown,
        disable_required_check
      
      self.options = options_parser.parse args_to_parse_for_options
      
      if config[:class_options]
        self.options = config[:class_options].merge(options)
      end

      # If unknown options are disallowed, make sure that none of the
      # remaining arguments looks like an option.
      if self.class.check_unknown_options? config
        options_parser.check_unknown!
      end

      # Add the remaining arguments from the options parser to the
      # arguments passed in to initialize. Then remove any positional
      # arguments declared using #argument (this is primarily used
      # by Thor::Group). Tis will leave us with the remaining
      # positional arguments.
      to_parse  = args
      unless self.class.strict_args_position? config
        to_parse += options_parser.remaining
      end

      thor_args = Thor::Arguments.new [
        *self.class.class_arguments,
        *config[:current_command]&.arguments,
      ]

      # Set the arguments as instance variables.
      thor_args.parse( to_parse ).each { |k, v| __send__ "#{k}=", v }

      # Set whatever is left as args
      @args = thor_args.remaining
    end
    
    
    # Instance Methods
    # ========================================================================
    
    protected
    # ========================================================================
      
      # Atli addition: An error handling hook that is called from
      # {Thor::Command#run} when running a command raises an unhandled
      # exception.
      # 
      # I don't believe errors are *recoverable* at this point, but this
      # hook allows the {Thor} subclass to respond to expected errors and
      # gracefully inform the user.
      # 
      # It's basically `goto fail` or whatever.
      # 
      # User overrides should always exit or re-raise the error.
      # 
      # The base implementation here simply re-raises.
      # 
      # Note that {ArgumentError} and {NoMethodError} are both rescued in
      # {Thor::Command#run} and passed off to Thor's relevant
      # `.handle_*_error` methods, so you probably won't be able to intercept
      # any of those.
      # 
      # Generally, it's best to use this to respond to custom, specific errors
      # so you can easily bail out with a `raise` from anywhere in the
      # application and still provide a properly formatted response and exit
      # status to the user.
      # 
      # Errors that are only expected in a single command
      # 
      # @param [Exception] error
      #   The error the bubbled up to {Thor::Command#run}.
      # 
      # @param [Thor::Command] command
      #   The command instance that was running when the error occurred.
      # 
      # @param [Array<String>] args
      #   The arguments to the command that was running.
      # 
      def on_run_error error, command, args
        raise error
      end
      
      
      # Hook for processing values return by command methods. So you can
      # format it or print it or whatever.
      # 
      # This implementation just returns the result per the specs.
      # 
      # @param [Object] result
      #   Whatever the command returned.
      # 
      # @param [Thor::Command] command
      #   The command instance that was running when the error occurred.
      # 
      # @param [Array<String>] args
      #   The arguments to the command that was running.
      # 
      # @return [Object]
      #   The `result`.
      # 
      def on_run_success result, command, args
        result
      end
      
    # end protected
    
  end # module Base
end # class Thor
