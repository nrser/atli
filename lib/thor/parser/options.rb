# frozen_string_literal: true

class Thor
  class Options < Arguments # rubocop:disable ClassLength
    
    # Constants
    # ========================================================================
    
    LONG_RE     = /^(--\w+(?:-\w+)*)$/
    SHORT_RE    = /^(-[a-z])$/i
    EQ_RE       = /^(--\w+(?:-\w+)*|-[a-z])=(.*)$/i
    
    # Matches "multiple short switches", like `-xv`.
    # 
    # @return [Regexp]
    # 
    SHORT_SQ_RE = /^-([a-z]{2,})$/i
    
    
    # Matches things like `'-x123'`.
    # 
    # @return [Regexp]
    # 
    SHORT_NUM   = /^(-[a-z])#{ Thor::Arguments::NUMERIC }$/i
    
    
    # The "bare double-dash" used to indicate that following arguments
    # should not be parsed for options.
    # 
    # @return [String]
    # 
    OPTS_END    = "--"
    
    
    # Class Methods
    # ========================================================================
    
    # Receives a hash and makes it switches.
    def self.to_switches(options)
      options.map do |key, value|
        case value
        when true
          "--#{key}"
        when Array
          "--#{key} #{value.map(&:inspect).join(' ')}"
        when Hash
          "--#{key} #{value.map { |k, v| "#{k}:#{v}" }.join(' ')}"
        when nil, false
          nil
        else
          "--#{key} #{value.inspect}"
        end
      end.compact.join(" ")
    end
    
    
    # Constructor
    # ========================================================================
    
    # Takes a hash of Thor::Option and a hash with defaults.
    #
    # If +stop_on_unknown+ is true, #parse will stop as soon as it encounters
    # an unknown option or a regular argument.
    # 
    # @param [Hash<Symbol, Thor::Option>] hash_options
    #   
    # 
    def initialize  hash_options = {},
                    defaults = {},
                    stop_on_unknown = false,
                    disable_required_check = false
      @stop_on_unknown = stop_on_unknown
      @disable_required_check = disable_required_check
      options = hash_options.values
      super(options)

      # Add defaults
      defaults.each do |key, value|
        @assigns[key.to_s] = value
        @non_assigned_required.delete(hash_options[key])
      end

      @shorts = {}
      @switches = {}
      @extra = []

      options.each do |option|
        @switches[option.switch_name] = option

        option.aliases.each do |short|
          name = short.to_s.sub(/^(?!\-)/, "-")
          @shorts[name] ||= option.switch_name
        end
      end
    end
    
    
    # Instance Methods
    # ========================================================================
    
    def remaining
      @extra
    end
    
    
    # What's next?! I think.
    # 
    # @note
    #   This *used to* remove `--` separators (what {OPTS_END} is),
    #   but that was problematic with multiple nested subcommands
    #   'cause Thor classes further down the chain wouldn't know that
    #   it was there and would parse options that had been after it.
    #   
    #   Maybe that's how Thor was supposed to work (???), but it didn't really
    #   jive with me... I've always felt like stuff after `--` meant
    #   **_stop parsing options - these are always args_** since I usually
    #   see it used when passing shell commands to other shell commands -
    #   which is how I was using it when I came across the issues.
    #   
    #   And it ain't like Thor has any documentation to straiten it out. Hell,
    #   this method had no doc when I showed up. The line that dropped the `--`
    #   has no comment. The {Thor::Options} class itself had no doc.
    #   
    #   So, now it *does* mean that... `--` means "no option parsing after
    #   here". For real.
    # 
    def peek
      return super unless @parsing_options

      result = super
      if result == OPTS_END
        # Removed, see note above:
        # shift
        @parsing_options = false
        super
      else
        result
      end
    end
    
    
    def parse args # rubocop:disable MethodLength
      logger.debug __method__.to_s,
        args: args
      
      @pile = args.dup
      @parsing_options = true

      while peek
        if parsing_options?
          match, is_switch = current_is_switch?
          shifted = shift

          if is_switch
            case shifted
            when SHORT_SQ_RE
              unshift($1.split("").map { |f| "-#{f}" })
              next
            when EQ_RE, SHORT_NUM
              unshift $2
              raw_switch_arg = $1
            when LONG_RE, SHORT_RE
              raw_switch_arg = $1
            end

            switch = normalize_switch raw_switch_arg
            option = switch_option switch
            @assigns[option.human_name] = parse_peek switch, option
          elsif @stop_on_unknown
            @parsing_options = false
            @extra << shifted
            @extra << shift while peek
            break
          elsif match
            @extra << shifted
            @extra << shift while peek && peek !~ /^-/
          else
            @extra << shifted
          end
        else
          @extra << shift
        end
      end

      check_requirement! unless @disable_required_check

      assigns = Thor::CoreExt::HashWithIndifferentAccess.new(@assigns)
      assigns.freeze
      
      logger.debug "#{ __method__ } done",
        assigns: assigns,
        remaining: remaining
      
      assigns
    end
    
    
    def check_unknown!
      # an unknown option starts with - or -- and has no more --'s afterward.
      unknown = @extra.select { |str| str =~ /^--?(?:(?!--).)*$/ }
      unless unknown.empty?
        raise UnknownArgumentError, "Unknown switches '#{unknown.join(', ')}'"
      end
    end
  
  
    protected # Instance Methods
    # ==========================================================================
    
      def last?
        super() || peek == OPTS_END
      end

      # Check if the current value in peek is a registered switch.
      #
      # Two booleans are returned.  The first is true if the current value
      # starts with a hyphen; the second is true if it is a registered switch.
      def current_is_switch?
        case peek
        when LONG_RE, SHORT_RE, EQ_RE, SHORT_NUM
          [true, switch?($1)]
        when SHORT_SQ_RE
          [true, $1.split("").any? { |f| switch?("-#{f}") }]
        else
          [false, false]
        end
      end
      
      
      def current_is_switch_formatted?
        case peek
        when LONG_RE, SHORT_RE, EQ_RE, SHORT_NUM, SHORT_SQ_RE
          true
        else
          false
        end
      end
      
      
      def switch?(arg)
        switch_option(normalize_switch(arg))
      end
      
      
      # Get the option for a switch arg.
      # 
      # Handles parsing `--no-<option>` and `--skip-<option>` styles as well.
      # 
      # @param [String] arg
      #   The switch part of the CLI arg, like `--blah`.
      # 
      # @return [Thor::Option]
      #   If we have an option for the switch.
      # 
      # @return [nil]
      #   If we don't have an option for the switch.
      # 
      def switch_option(arg)
        if match = no_or_skip?(arg) # rubocop:disable AssignmentInCondition
          @switches[arg] || @switches["--#{match}"]
        else
          @switches[arg]
        end
      end
      
      
      # Check if the given argument is actually a shortcut.
      # 
      # Also normalizes '_' to '-'.
      # 
      # @param [String] raw_switch_arg
      #   The raw switch arg that we received (essentially, what was passed
      #   on the CLI).
      # 
      # @return [String]
      #   Normalized, de-aliased switch string.
      #
      def normalize_switch raw_switch_arg
        (@shorts[raw_switch_arg] || raw_switch_arg).tr("_", "-")
      end
      
      
      def parsing_options?
        peek
        @parsing_options
      end
      
      
      # Parse boolean values which can be given as --foo=true, --foo or --no-foo.
      # 
      def parse_boolean(switch)
        if current_is_value?
          if ["true", "TRUE", "t", "T", true].include?(peek)
            shift
            true
          elsif ["false", "FALSE", "f", "F", false].include?(peek)
            shift
            false
          else
            !no_or_skip?(switch)
          end
        else
          @switches.key?(switch) || !no_or_skip?(switch)
        end
      end
      
      
      # Parse the value at the peek analyzing if it requires an input or not.
      # 
      # @param [String] switch
      #   The normalized option switch, as returned from {#normalize_switch}.
      # 
      def parse_peek switch, option
        if current_is_switch_formatted? || last?
          if option.boolean?
            # No problem for boolean types
          elsif no_or_skip?(switch)
            return nil # User set value to nil
          elsif option.string? && !option.required?
            # Return the default if there is one, else the human name
            return option.lazy_default || option.default || option.human_name
          elsif option.lazy_default
            return option.lazy_default
          else
            raise MalformattedArgumentError,
              "No value provided for option '#{switch}'"
          end
        end

        @non_assigned_required.delete(option)
        send(:"parse_#{option.type}", switch)
      end # #parse_peek
    
    public # end protected Instance Methods **********************************
    
  end # class Options
end # class Thor
