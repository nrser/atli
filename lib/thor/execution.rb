# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types


# Declarations
# =======================================================================


# Definitions
# =======================================================================


# An execution is an object created by {Thor::Base::ClassMethods#exec!} that
# holds references to all relevant objects for running a {Thor} instance as
# an executable and manages that execution.
# 
class Thor::Execution
  
  # Constants
  # ======================================================================
  
  BUILT_IN_ENV_PREFIXES = Hamster::Vector['ATLI', 'THOR']
  
  
  # Mixins
  # ============================================================================
  
  include SemanticLogger::Loggable
  
  
  # Attributes
  # ======================================================================
  
  # The {Thor} subclass that is being executed.
  # 
  # @return [Class<Thor>]
  #     
  attr_reader :thor_class
  
  
  # The command line arguments given for execution.
  # 
  # @return [Array<String>]
  #     
  attr_reader :given_args
  
  
  # The configuration hash, which includes any config values passed to
  # {Thor::Base::ClassMethods#exec!}, and is mutated in {Thor::Base#initialize}
  # to include things like the current command.
  # 
  # @return [Hash]
  #     
  attr_reader :thor_config
  
  
  # The instance or {Thor} being executed, if it has been successfully
  # constructed.
  # 
  # @return [Class<Thor>?]
  #     
  attr_reader :thor_instance
  
  
  # Constructor
  # ======================================================================
  
  # Instantiate a new `Thor::Execution`.
  def initialize thor_class:, given_args:, thor_config:
    @thor_class = thor_class
    @given_args = given_args.dup
    @thor_config = thor_config
    @thor_instance = nil
  end # #initialize
  
  
  # Instance Methods
  # ======================================================================
  
  # @todo Document env_prefixes method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def env_prefixes
    BUILT_IN_ENV_PREFIXES
  end # #env_prefixes
  
  
  
  # @todo Document env_key method.
  # 
  # @param [type] arg_name
  #   @todo Add name param description.
  # 
  # @return [return_type]
  #   @todo Document return value.
  # 
  def env_key_for prefix:, key:
    "#{ prefix }_#{ key.upcase }"
  end # #env_key
  
  
  # @todo Document get_from_env method.
  # 
  # @param key (see #get_context_value)
  # @param with_source: (see #get_context_value)
  # 
  # @return [String?]
  #   When +with_source:+ is +false+, just returns the value that was found,
  #   or +nil+ if none was.
  # 
  # @return [Array<(nil, nil, nil)>]
  #   When +with_source:+ is +true+ and no value was found.
  # 
  # @return [Array<(String, :env, String)>]
  #   When +with_source:+ is +true+ and the value was found.
  #   
  #   The first entry is the value, the last is the +ENV+ key it was at.
  # 
  def get_from_env key, with_source: false
    env_prefixes.each do |prefix|
      env_key = env_key_for prefix: prefix, key: key
      if ENV.key? env_key
        if with_source
          return [ENV[env_key], :env, env_key]
        else
          return ENV[env_key]
        end
      end
    end
    
    if with_source
      [nil, nil, nil]
    else
      nil
    end
  end # #get_from_env
  
  
  # Get the value for a key from the "context", which is the hierarchy of
  # {Thor} instance class options, Thor config values and ENV variables.
  # 
  # @param [Symbol] key
  #   The key to get the value for.
  # 
  # @param [Boolean] with_source:
  #   When +true+, returns where the value was found as well (see below).
  # 
  # @return [Object]
  #   When +with_source:+ is +false+, just returns the value that was found,
  #   or +nil+ if none was.
  # 
  # @return [Array<(Object, Symbol?, (String | Symbol)?>)]
  #   When +with_source:+ is +true+ returns an Array triple:
  #   
  #   1.  The value that was found, or `nil` if none was.
  #       
  #   2.  A symbol indicating where the value was found:
  #       1.  +:thor_instance_options+ The `#options` hash of the
  #           {#thor_instance}. You will only see this result if the Thor
  #           instance successfully constructed and became available to the
  #           execution.
  #       2.  +:thor_config+ The {#thor_config} hash.
  #       3.  +:env+ The +ENV+.
  #       
  #       If the value isn't found, this will be +nil+.
  #       
  #   3.  The key used to get the value from the source hash-like. This is only
  #       really important when it came from the +ENV+.
  #       
  #       If the value is not found, this will be +nil+.
  # 
  def get_context_value key, with_source: false
    # 1.  First stop is the Thor instance's options (if we have a Thor instance)
    if thor_instance && thor_instance.options.key?( key )
      if with_source
        return [thor_instance.options[key], :thor_instance_options, key]
      else
        return thor_instance.options[key]
      end
    end
    
    # 2.  Next, check the config that was handed to `.exec!`
    if thor_config.key? key
      if with_source
        return [thor_config[key], :thor_config, key]
      else
        return thor_config[key]
      end
    end
    
    # 3. Last, check the ENV (returns `nil` if nothing found)
    get_from_env key, with_source: with_source
  end # #get_context_value
  
  
  # Are we in debug mode?
  def debug?
    get_context_value( :debug ).truthy?
  end
  
  
  # Should we print backtraces with errors?
  def backtrace?
    debug? || get_context_value( :backtrace ).truthy?
  end
  
  
  # Should we raise errors (versus print them and exit)?
  def raise_errors?
    debug? || get_context_value( :raise_errors ).truthy?
  end
  
  
  # Let's do this thang!
  def exec!
    thor_config[:shell] ||= Thor::Base.shell.new
    
    thor_class.send(
      :dispatch,
      nil,
      given_args,
      nil,
      thor_config
    ) { |thor_instance|
      @thor_instance = thor_instance
      
      logger.debug "Got Thor instance",
        options: thor_instance.options
    }
  rescue SystemExit
    # `exit` was called; we want to just let this keep going
    raise
  rescue Errno::EPIPE
    # This happens if a thor command is piped to something like `head`,
    # which closes the pipe when it's done reading. This will also
    # mean that if the pipe is closed, further unnecessary
    # computation will not occur.
    exit true
  rescue Exception => error
    raise if raise_errors?
    
    if backtrace?
      logger.error error
    else
      logger.error error.message
    end
    
    exit false
  end # #start
  
  
end # class Thor::Execution
