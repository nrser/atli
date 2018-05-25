require "set"
require 'nrser'
require 'semantic_logger'
require "thor/base"
require 'thor/example'


class Thor
  
  class << self
    # Allows for custom "Command" package naming.
    #
    # === Parameters
    # name<String>
    # options<Hash>
    #
    def package_name(name, _ = {})
      @package_name = name.nil? || name == "" ? nil : name
    end

    # Sets the default command when thor is executed without an explicit
    # command to be called.
    #
    # ==== Parameters
    # meth<Symbol>:: name of the default command
    #
    def default_command(meth = nil)
      if meth
        @default_command = meth == :none ? "help" : meth.to_s
      else
        @default_command ||= from_superclass(:default_command, "help")
      end
    end
    alias_method :default_task, :default_command

    # Registers another Thor subclass as a command.
    #
    # ==== Parameters
    # klass<Class>:: Thor subclass to register
    # command<String>:: Subcommand name to use
    # usage<String>:: Short usage for the subcommand
    # description<String>:: Description for the subcommand
    def register(klass, subcommand_name, usage, description, options = {})
      if klass <= Thor::Group
        desc usage, description, options
        define_method(subcommand_name) { |*args| invoke(klass, args) }
      else
        desc usage, description, options
        subcommand subcommand_name, klass
      end
    end

    # Defines the usage and the description of the next command.
    #
    # ==== Parameters
    # usage<String>
    # description<String>
    # options<String>
    #
    def desc(usage, description, options = {})
      if options[:for]
        command = find_and_refresh_command(options[:for])
        command.usage = usage             if usage
        command.description = description if description
      else
        @usage = usage
        @desc = description
        @hide = options[:hide] || false
      end
    end

    # Defines the long description of the next command.
    #
    # ==== Parameters
    # long description<String>
    #
    def long_desc(long_description, options = {})
      if options[:for]
        command = find_and_refresh_command(options[:for])
        command.long_description = long_description if long_description
      else
        @long_desc = long_description
      end
    end

    # Maps an input to a command. If you define:
    #
    #   map "-T" => "list"
    #
    # Running:
    #
    #   thor -T
    #
    # Will invoke the list command.
    #
    # ==== Parameters
    # Hash[String|Array => Symbol]:: Maps the string or the strings in the
    # array to the given command.
    #
    def map(mappings = nil)
      @map ||= from_superclass(:map, {})

      if mappings
        mappings.each do |key, value|
          if key.respond_to?(:each)
            key.each { |subkey| @map[subkey] = value }
          else
            @map[key] = value
          end
        end
      end

      @map
    end

    # Declares the options for the next command to be declared.
    #
    # ==== Parameters
    # Hash[Symbol => Object]:: The hash key is the name of the option and the value
    # is the type of the option. Can be :string, :array, :hash, :boolean, :numeric
    # or :required (string). If you give a value, the type of the value is used.
    #
    def method_options(options = nil)
      @method_options ||= {}
      build_options(options, @method_options) if options
      @method_options
    end

    alias_method :options, :method_options

    # Adds an option to the set of method options. If :for is given as option,
    # it allows you to change the options from a previous defined command.
    #
    #   def previous_command
    #     # magic
    #   end
    #
    #   method_option :foo => :bar, :for => :previous_command
    #
    #   def next_command
    #     # magic
    #   end
    #
    # ==== Parameters
    # name<Symbol>:: The name of the argument.
    # options<Hash>:: Described below.
    #
    # ==== Options
    # :desc     - Description for the argument.
    # :required - If the argument is required or not.
    # :default  - Default value for this argument. It cannot be required and
    #             have default values.
    # :aliases  - Aliases for this option.
    # :type     - The type of the argument, can be :string, :hash, :array,
    #             :numeric or :boolean.
    # :banner   - String to show on usage notes.
    # :hide     - If you want to hide this option from the help.
    #
    def method_option(name, options = {})
      scope = if options[:for]
        find_and_refresh_command(options[:for]).options
      else
        method_options
      end

      build_option(name, options, scope)
    end
    alias_method :option, :method_option

    # Prints help information for the given command.
    #
    # @param [Thor::Shell] shell
    # 
    # @param [String] command_name
    # 
    # @param [Boolean] subcommand
    #   *Alti* *addition* - passed from {#help} when that command is being
    #   invoked as a subcommand.
    #   
    #   The values is passed through to {.banner} and eventually
    #   {Command#formatted_usage} so that it can properly display the usage
    #   message
    #   
    #       basename subcmd cmd ARGS...
    #   
    #   versus what it did when I found it:
    #   
    #       basename cmd ARGS...
    #   
    #   which, of course, doesn't work if +cmd+ is inside +subcmd+.
    # 
    # @return [nil]
    #
    def command_help(shell, command_name, subcommand = false)
      meth = normalize_command_name(command_name)
      command = all_commands[meth]
      handle_no_command_error(meth) unless command

      shell.say "Usage:"
      shell.say "  #{banner(command, nil, subcommand)}"
      shell.say
      
      class_options_help \
        shell,
        command.options.values.group_by { |option| option.group }
      
      if command.long_description
        shell.say "Description:"
        shell.print_wrapped(command.long_description, :indent => 2)
      else
        shell.say command.description
      end
      
      unless command.examples.empty?
        shell.say "\n"
        shell.say "Examples:"
        shell.say "\n"
        
        command.examples.each_with_index do |example, index|
          lines = example.lines
          
          shell.say "1.  #{ lines[0] }"
          
          lines[1..-1].each do |line|
            shell.say "    #{ line }"
          end
        end
        
        shell.say "\n"
      end
      
      nil
    end
    alias_method :task_help, :command_help

    # Prints help information for this class.
    #
    # @param [Thor::Shell] shell
    # @return (see Thor::Base::ClassMethods#class_options_help)
    #
    def help(shell, subcommand = false)
      list = printable_commands(true, subcommand)
      Thor::Util.thor_classes_in(self).each do |klass|
        list += klass.printable_commands(false)
      end
      list.sort! { |a, b| a[0] <=> b[0] }

      if defined?(@package_name) && @package_name
        shell.say "#{@package_name} commands:"
      else
        shell.say "Commands:"
      end

      shell.print_table(list, :indent => 2, :truncate => true)
      shell.say
      class_options_help(shell)
    end

    # Returns commands ready to be printed.
    def printable_commands(all = true, subcommand = false)
      (all ? all_commands : commands).map do |_, command|
        next if command.hidden?
        item = []
        item << banner(command, false, subcommand)
        item << ( command.description ?
                  "# #{command.description.gsub(/\s+/m, ' ')}" : "" )
        item
      end.compact
    end
    alias_method :printable_tasks, :printable_commands
    
    
    # List of subcommand names, including those inherited from super
    # classes.
    # 
    # @return [Array<String>]
    # 
    def subcommands
      @subcommands ||= from_superclass(:subcommands, [])
    end
    alias_method :subtasks, :subcommands
    
    
    # Map of subcommand names to Thor classes for *this* Thor class only.
    # 
    # @note
    #   `.subcommands` is not necessarily equal to `.subcommand_classes.keys`
    #   - it won't be when there are subcommands inherited from super classes.
    # 
    # @note
    #   I'm not really sure how this relates to {Thor::Group}... and I'm not
    #   going to take the time to find out now.
    # 
    # @return [Hash<String, Class<Thor::Base>]
    #   
    def subcommand_classes
      @subcommand_classes ||= {}
    end
    
    
    def subcommand(subcommand, subcommand_class)
      subcommands << subcommand.to_s
      subcommand_class.subcommand_help subcommand
      subcommand_classes[subcommand.to_s] = subcommand_class

      define_method(subcommand) do |*args|
        args, opts = Thor::Arguments.split(args)
        invoke_args = [
          args,
          opts,
          {:invoked_via_subcommand => true, :class_options => options}
        ]
        invoke_args.unshift "help" if opts.delete("--help") || opts.delete("-h")
        invoke subcommand_class, *invoke_args
      end
      subcommand_class.commands.each do |_meth, command|
        command.ancestor_name = subcommand
      end
    end
    alias_method :subtask, :subcommand

    # Extend check unknown options to accept a hash of conditions.
    #
    # === Parameters
    # options<Hash>: A hash containing :only and/or :except keys
    def check_unknown_options!(options = {})
      @check_unknown_options ||= {}
      options.each do |key, value|
        if value
          @check_unknown_options[key] = Array(value)
        else
          @check_unknown_options.delete(key)
        end
      end
      @check_unknown_options
    end

    # Overwrite check_unknown_options? to take subcommands and options into
    # account.
    def check_unknown_options?(config) #:nodoc:
      options = check_unknown_options
      return false unless options

      command = config[:current_command]
      return true unless command

      name = command.name

      if subcommands.include?(name)
        false
      elsif options[:except]
        !options[:except].include?(name.to_sym)
      elsif options[:only]
        options[:only].include?(name.to_sym)
      else
        true
      end
    end

    # Stop parsing of options as soon as an unknown option or a regular
    # argument is encountered.  All remaining arguments are passed to the command.
    # This is useful if you have a command that can receive arbitrary additional
    # options, and where those additional options should not be handled by
    # Thor.
    #
    # ==== Example
    #
    # To better understand how this is useful, let's consider a command that calls
    # an external command.  A user may want to pass arbitrary options and
    # arguments to that command.  The command itself also accepts some options,
    # which should be handled by Thor.
    #
    #   class_option "verbose",  :type => :boolean
    #   stop_on_unknown_option! :exec
    #   check_unknown_options!  :except => :exec
    #
    #   desc "exec", "Run a shell command"
    #   def exec(*args)
    #     puts "diagnostic output" if options[:verbose]
    #     Kernel.exec(*args)
    #   end
    #
    # Here +exec+ can be called with +--verbose+ to get diagnostic output,
    # e.g.:
    #
    #   $ thor exec --verbose echo foo
    #   diagnostic output
    #   foo
    #
    # But if +--verbose+ is given after +echo+, it is passed to +echo+ instead:
    #
    #   $ thor exec echo --verbose foo
    #   --verbose foo
    #
    # ==== Parameters
    # Symbol ...:: A list of commands that should be affected.
    def stop_on_unknown_option!(*command_names)
      stop_on_unknown_option.merge(command_names)
    end

    def stop_on_unknown_option?(command) #:nodoc:
      command && stop_on_unknown_option.include?(command.name.to_sym)
    end

    # Disable the check for required options for the given commands.
    # This is useful if you have a command that does not need the required options
    # to work, like help.
    #
    # ==== Parameters
    # Symbol ...:: A list of commands that should be affected.
    def disable_required_check!(*command_names)
      disable_required_check.merge(command_names)
    end

    def disable_required_check?(command) #:nodoc:
      command && disable_required_check.include?(command.name.to_sym)
    end
    
    # Atli Public Class Methods
    # ========================================================================
    
    # @return [Hash<Symbol, Thor::SharedOption]
    #   Get all shared options
    # 
    def shared_method_options(options = nil)
      @shared_method_options ||= begin
        # Reach up the inheritance chain, if there's anyone there
        if superclass.respond_to? __method__
          superclass.send( __method__ ).dup
        else
          # Or just default to empty
          {}
        end
      end
      
      if options
        # We don't support this (yet at least)
        raise NotImplementedError,
          "Bulk set not supported, use .shared_method_option"
        # build_shared_options(options, @shared_method_options)
      end
      @shared_method_options
    end
    alias_method :shared_options, :shared_method_options
    
    
    # Find shared options given names and groups.
    # 
    # @param [*<Symbol>] names
    #   Individual shared option names to include.
    # 
    # @param [nil | Symbol | Enumerable<Symbol>] groups:
    #   Single or list of shared option groups to include.
    # 
    # @return [Hash<Symbol, Thor::SharedOption>]
    #   Hash mapping option names (as {Symbol}) to instances.
    # 
    def find_shared_method_options *names, groups: nil
      groups_set = Set[*groups]
      
      shared_method_options.each_with_object( {} ) do |(name, option), results|
        match = {}
        
        if names.include? name
          match[:name] = true
        end
        
        match_groups = option.groups & groups_set
          
        unless match_groups.empty?
          match[:groups] = match_groups
        end
        
        unless match.empty?
          results[name] = {
            option: option,
            match: match,
          }
        end
      end
    end
    alias_method :find_shared_options, :find_shared_method_options
    
    
    # Declare a shared method option with an optional groups that can then
    # be added by name or group to commands.
    # 
    # The shared options can then be added to methods individually by name and
    # collectively as groups with {Thor.include_method_options}.
    # 
    # @example
    #   class MyCLI < Thor
    #     
    #     # Declare a shared option:
    #     shared_option :force,
    #       groups: :write,
    #       desc: "Force the operation",
    #       type: :boolean
    #     
    #     # ...
    #     
    #     desc            "write [OPTIONS] path",
    #                     "Write to a path"
    #     
    #     # Add the shared options to the method:
    #     include_options groups: :write
    #     
    #     def write       path
    #       
    #       # Get a slice of `#options` with any of the `:write` group options
    #       # that were provided and use it in a method call:
    #       MyModule.write path, **option_kwds( groups: :write )
    #       
    #     end
    #   end
    # 
    # @param [Symbol] name
    #   The name of the option.
    # 
    # @param [**<Symbol, V>] options
    #   Keyword args used to initialize the {Thor::SharedOption}.
    #   
    #   All +**options+ are optional.
    # 
    # @option options [Symbol | Array<Symbol>] :groups
    #   One or more _shared_ _option_ _group_ that the new option will belong
    #   to.
    #   
    #   Examples:
    #     groups: :read
    #     groups: [:read, :write]
    #   
    #   *NOTE*  The keyword is +groups+ with an +s+! {Thor::Option} already has
    #           a +group+ string attribute that, as far as I can tell, is only
    #           
    # 
    # 
    # @option options [String] :desc
    #   Description for the option for help and feedback.
    # 
    # @option options [Boolean] :required
    #   If the option is required or not.
    # 
    # @option options [Object] :default
    #   Default value for this argument.
    #   
    #   It cannot be +required+ and have default values.
    # 
    # @option options [String | Array<String>] :aliases
    #   Aliases for this option.
    #   
    #   Examples:
    #     aliases: '-s'
    #     aliases: '--other-name'
    #     aliases: ['-s', '--other-name']
    # 
    # @option options [:string | :hash | :array | :numeric | :boolean] :type
    #   Type of acceptable values, see
    #   {types for method options}[https://github.com/erikhuda/thor/wiki/Method-Options#types-for-method_options]
    #   in the Thor wiki.
    # 
    # @option options [String] :banner
    #   String to show on usage notes.
    # 
    # @option options [Boolean] :hide
    #   If you want to hide this option from the help.
    # 
    # @return (see .build_shared_option)
    # 
    def shared_method_option name, **options
      # Don't think the `:for` option makes sense... that would just be a
      # regular method option, right? I guess `:for` could be an array and
      # apply the option to each command, but it seems like that would just
      # be better as an extension to the {.method_option} behavior.
      # 
      # So, we raise if we see it
      if options.key? :for
        raise ArgumentError,
          ".shared_method_option does not accept the `:for` option"
      end
      
      build_shared_option(name, options)
    end # #shared_method_option
    alias_method :shared_option, :shared_method_option
    
    
    # Add the {Thor::SharedOption} instances with +names+ and in +groups+ to
    # the next defined command method.
    # 
    # @param (see .find_shared_method_options)
    # @return (see .find_shared_method_options)
    # 
    def include_method_options *names, groups: nil
      find_shared_method_options( *names, groups: groups ).
        each do |name, result|
          method_options[name] = Thor::IncludedOption.new **result
        end
    end
    
    alias_method :include_options, :include_method_options
    
    # END Atli Public Class Methods ******************************************
    
    
    protected # Class Methods
    # ============================================================================

      def stop_on_unknown_option #:nodoc:
        @stop_on_unknown_option ||= Set.new
      end

      # help command has the required check disabled by default.
      def disable_required_check #:nodoc:
        @disable_required_check ||= Set.new([:help])
      end

      # The method responsible for dispatching given the args.
      def dispatch(meth, given_args, given_opts, config) #:nodoc: # rubocop:disable MethodLength
        meth ||= retrieve_command_name(given_args)
        command = all_commands[normalize_command_name(meth)]

        if !command && config[:invoked_via_subcommand]
          # We're a subcommand and our first argument didn't match any of our
          # commands. So we put it back and call our default command.
          given_args.unshift(meth)
          command = all_commands[normalize_command_name(default_command)]
        end

        if command
          args, opts = Thor::Options.split(given_args)
          if stop_on_unknown_option?(command) && !args.empty?
            # given_args starts with a non-option, so we treat everything as
            # ordinary arguments
            args.concat opts
            opts.clear
          end
        else
          args = given_args
          opts = nil
          command = dynamic_command_class.new(meth)
        end

        opts = given_opts || opts || []
        config[:current_command] = command
        config[:command_options] = command.options

        instance = new(args, opts, config)
        yield instance if block_given?
        args = instance.args
        trailing = args[Range.new(arguments.size, -1)]
        instance.invoke_command(command, trailing || [])
      end
      
      
      # The banner for this class. You can customize it if you are invoking the
      # thor class by another ways which is not the Thor::Runner. It receives
      # the command that is going to be invoked and a boolean which indicates if
      # the namespace should be displayed as arguments.
      # 
      # @param [Thor::Command] command
      #   The command to render the banner for.
      # 
      # @param [nil | ?] namespace
      #   *Atli*: this argument is _not_ _used_ _at_ _all_. I don't know what it
      #   could or should be, but it doesn't seem like it matters at all :/
      #  
      # @param [Boolean] subcommand
      #   Should be +true+ if the command was invoked as a sub-command; passed
      #   on to {Command#formatted_usage} so it can render correctly.
      # 
      # @return [String]
      #   The banner for the command.
      # 
      def banner(command, namespace = nil, subcommand = false)
        "#{basename} #{command.formatted_usage(self, $thor_runner, subcommand)}"
      end
      
      
      def baseclass #:nodoc:
        Thor
      end

      def dynamic_command_class #:nodoc:
        Thor::DynamicCommand
      end

      def create_command(meth) #:nodoc:
        @usage ||= nil
        @desc ||= nil
        @long_desc ||= nil
        @hide ||= nil
        
        examples = @examples || []
        @examples = []

        if @usage && @desc
          base_class = @hide ? Thor::HiddenCommand : Thor::Command
          commands[meth] = base_class.new(
            meth,
            @desc,
            @long_desc,
            @usage,
            examples,
            method_options
          )
          @usage, @desc, @long_desc, @method_options, @hide = nil
          true
        elsif all_commands[meth] || meth == "method_missing"
          true
        else
          puts "[WARNING] Attempted to create command #{meth.inspect} without usage or description. " \
               "Call desc if you want this method to be available as command or declare it inside a " \
               "no_commands{} block. Invoked from #{caller[1].inspect}."
          false
        end
      end
      alias_method :create_task, :create_command

      def initialize_added #:nodoc:
        class_options.merge!(method_options)
        @method_options = nil
      end

      # Retrieve the command name from given args.
      def retrieve_command_name(args) #:nodoc:
        meth = args.first.to_s unless args.empty?
        args.shift if meth && (map[meth] || meth !~ /^\-/)
      end
      alias_method :retrieve_task_name, :retrieve_command_name

      # receives a (possibly nil) command name and returns a name that is in
      # the commands hash. In addition to normalizing aliases, this logic
      # will determine if a shortened command is an unambiguous substring of
      # a command or alias.
      #
      # +normalize_command_name+ also converts names like +animal-prison+
      # into +animal_prison+.
      def normalize_command_name(meth) #:nodoc:
        return default_command.to_s.tr("-", "_") unless meth

        possibilities = find_command_possibilities(meth)
        
        if possibilities.size > 1
          raise AmbiguousTaskError,
            "Ambiguous command #{meth} matches [#{possibilities.join(', ')}]"
        end

        if possibilities.empty?
          meth ||= default_command
        elsif map[meth]
          meth = map[meth]
        else
          meth = possibilities.first
        end

        meth.to_s.tr("-", "_") # treat foo-bar as foo_bar
      end
      alias_method :normalize_task_name, :normalize_command_name

      # this is the logic that takes the command name passed in by the user
      # and determines whether it is an unambiguous substrings of a command or
      # alias name.
      def find_command_possibilities(meth)
        len = meth.to_s.length
        possibilities = all_commands.merge(map).keys.select { |n|
          meth == n[0, len]
        }.sort
        unique_possibilities = possibilities.map { |k| map[k] || k }.uniq

        if possibilities.include?(meth)
          [meth]
        elsif unique_possibilities.size == 1
          unique_possibilities
        else
          possibilities
        end
      end
      alias_method :find_task_possibilities, :find_command_possibilities

      def subcommand_help(cmd)
        logger.trace __method__.to_s,
          cmd: cmd,
          caller: caller
        
        desc "help [COMMAND]", "Describe subcommands or one specific subcommand"
        
        # Atli -  This used to be {#class_eval} (maybe to support really old
        #         Rubies? Who knows...) but that made it really hard to find in
        #         stack traces, so I switched it to {#define_method}.
        # 
        define_method :help do |*args|
          
          # Add the `is_subcommand = true` trailing arg
          case args[-1]
          when true
            # pass
          when false
            # Weird, `false` was explicitly passed... whatever, set it to `true`
            args[-1] = true
          else
            # "Normal" case, append it
            args << true
          end
          
          super( *args )
        end
        
      end
      alias_method :subtask_help, :subcommand_help
      
      # Atli Protected Class Methods
      # ======================================================================
      
      # Build a Thor::SharedOption and add it to Thor.shared_method_options.
      # 
      # The Thor::SharedOption is returned.
      #
      # ==== Parameters
      # name<Symbol>:: The name of the argument.
      # options<Hash>::   Described in both class_option and method_option,
      #                   with the additional `:groups` shared option keyword.
      def build_shared_option(name, options)
        shared_method_options[name] = Thor::SharedOption.new(
          name,
          options.merge(:check_default_type => check_default_type?)
        )
      end # #build_shared_option
    
    # END protected Class Methods ********************************************
  
  end # class << self ********************************************************
  
  
  protected # Instance Methods
  # ==========================================================================
  
    # Get a Hash mapping option name symbols to their values ready for
    # +**+ usage in a method call for the option names and shared option
    # groups.
    # 
    # @param (see .find_shared_method_options)
    # 
    # @return [Hash<Symbol, V>]
    #   Map of option name to value.
    # 
    def option_kwds *names, groups: nil
      # Transform names into a set of strings
      name_set = Set.new names.map( &:to_s )
      
      # Add groups (if any)
      if groups
        self.class.find_shared_options( groups: groups ).each do |name, option|
          name_set << name.to_s
        end
      end
      
      options.slice( *name_set ).sym_keys
    end
    
  public # END protected Instance Methods ************************************
  
  
  # After this, {.method_added} hook is installed and defined methods become
  # commands
  include Thor::Base
  
  
  # Commands
  # ==========================================================================

  map HELP_MAPPINGS => :help

  desc "help [COMMAND]", "Describe available commands or one specific command"
  def help(*args)
    is_subcommand = case args[-1]
    when true, false
      args.pop
    else
      false
    end
    
    # Will be the {String} command (get help on that command)
    # or `nil` (get help on this class)
    command = args.shift
    
    # Possibly empty array of string subcommands from something like
    # 
    #     myexe help sub cmd
    # 
    # in which case it would end up being `['cmd']` and we actually are just
    # passing through and want to get help on the `cmd` subcommand.
    # 
    subcommands = args
    
    logger.trace "#help",
      args: args,
      command: command,
      is_subcommand: is_subcommand,
      subcommands: subcommands
    
    if command
      if self.class.subcommands.include? command
        if subcommands.empty?
          # Get help on a subcommand *class*
          self.class.subcommand_classes[command].help(shell, true)
        else
          # Atli addition - handle things like `myexe help sub cmd`
          # Want help on something (class or command) further down the line
          invoke  self.class.subcommand_classes[command],
                  ['help', *subcommands],
                  {},
                  {:invoked_via_subcommand => true, :class_options => options}
        end
      else
        # Want help on a *command* of this class
        # 
        # Atli -  Now that we've modified {.command_help} to accept
        #         `subcommand`, pass it (it seems to have already been getting
        #         the correct value to here).
        self.class.command_help(shell, command, is_subcommand)
      end
    else
      # We want help on *this class itself* (list available commands)
      self.class.help(shell, is_subcommand)
    end
  end
  
end # class Thor
