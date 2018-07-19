# encoding: UTF-8
# frozen_string_literal: true
##############################################################################
# Support for {Thor::Argument} in {Thor::Base} Classes
# ============================================================================
# 
# With this file I've started to split the "Thor classes" stuff out by feature
# to make things easier to find and keep the files shorter.
# 
##############################################################################

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

require 'active_support/concern'

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types

# Namespace
# =======================================================================

class   Thor
module  Base

# Definitions
# =======================================================================


# @todo document Arguments module.
# 
module ArgumentsConcern
  extend ActiveSupport::Concern
  
  # Instance Methods
  # ========================================================================


  class_methods do
  # ==========================================================================

    def arguments command: nil
      [*class_arguments, *command&.arguments]
    end

    
    protected
    # ========================================================================

    def build_argument name, options, scope
      name = name.to_s

      is_thor_reserved_word? name, :argument
      no_commands { attr_accessor name }

      required = if options.key?(:optional)
        !options[:optional]
      elsif options.key?(:required)
        options[:required]
      else
        # If neither `:required` or `:optional` options were provided,
        # default to the argument being required if no `:default` was provided.
        options[:default].nil?
      end

      scope.delete_if { |argument| argument.name == name }

      if required
        scope.each do |argument|
          next if argument.required?
          raise ArgumentError,
            "You cannot have #{ name.inspect } as required argument " \
            "after the non-required argument #{ argument.human_name.inspect }."
        end
      end

      options[:required] = required

      scope << Thor::Argument.new( name, options )
    end


    def remove_argument_from *names, scope:, undefine: false
      names.each do |name|
        scope.delete_if { |a| a.name == name.to_s }
        undef_method name, "#{name}=" if undefine
      end
    end

    public # end protected ***************************************************


    # @!group Class-Level Argument Class Methods
    # ------------------------------------------------------------------------

    # Returns this class' class-level arguments, looking up in the ancestors 
    # chain.
    #
    # @return [Array<Thor::Argument>]
    #
    def class_arguments
      @class_arguments ||= from_superclass( :class_arguments, [] )
    end


    # Adds an argument to the class and creates an attr_accessor for it.
    # 
    # @note
    #   This used to just be called `.argument`, and apparently arguments
    #   were class-level **only**. I don't know why.
    #   
    #   Atli switches them to mirror options, with class and command levels.
    #
    # Arguments are different from options in several aspects. The first one
    # is how they are parsed from the command line, arguments are retrieved
    # from position:
    #
    #   thor command NAME
    #
    # Instead of:
    #
    #   thor command --name=NAME
    #
    # Besides, arguments are used inside your code as an accessor
    # (self.argument), while options are all kept in a hash (self.options).
    #
    # Finally, arguments cannot have type :default or :boolean but can be
    # optional (supplying :optional => :true or :required => false), although
    # you cannot have a required argument after a non-required argument. If
    # you try it, an error is raised.
    #
    # @param [String | Symbol] name
    #   The name of the argument.
    # 
    # @param [Hash] options
    # 
    # @option options [String] :desc
    #   Description for the argument.
    # 
    # @option options [Boolean] :required
    #   If the argument is required or not (opposite of `:optional`).
    # 
    # @option options [Boolean] :optional
    #   If the argument is optional or not (opposite of `:required`).
    # 
    # @option options [:string | :hash | :array | :numeric] :type
    #   The type of the argument.
    # 
    # @option options [Object] :default
    #   Default value for this argument. It cannot be required and
    #   have default values.
    # 
    # @option options [String] :banner
    #   String to show on usage notes.
    # 
    # @return (see #class_arguments)
    # 
    # @raise [ArgumentError]
    #   Raised if you supply a required argument after a non-required one.
    #
    def class_argument name, **options
      build_argument name, options, class_arguments
    end


    # Removes a previous defined class-level argument. If `:undefine` option is
    # given, un-defines accessors as well.
    #
    # @param [Array<String | Symbol>] *names
    #   Arguments to be removed
    #
    # @param [Boolean] undefine:
    #   Un-defines the arguments' setter methods as well.
    #
    # @example
    #   remove_class_argument :foo
    # 
    # @example
    #   remove_class_argument :foo, :bar, :baz, :undefine => true
    #
    def remove_class_argument *names, undefine: false
      remove_argument_from *names, scope: class_arguments, undefine: undefine
    end

    # @!endgroup Class-Level Argument Class Methods # ************************


    # @!group Method-Specific Argument Class Methods
    # ------------------------------------------------------------------------

    # Returns this class' class-level arguments, looking up in the ancestors 
    # chain.
    #
    # @return [Array<Thor::Argument>]
    #
    def method_arguments 
      @method_arguments ||= []
    end


    # Adds an argument to the class and creates an attr_accessor for it.
    # 
    # @note
    #   This used to just be called `.argument`, and apparently arguments
    #   were class-level **only**. I don't know why.
    #   
    #   Atli switches them to mirror options, with class and command levels.
    #
    # Arguments are different from options in several aspects. The first one
    # is how they are parsed from the command line, arguments are retrieved
    # from position:
    #
    #   thor command NAME
    #
    # Instead of:
    #
    #   thor command --name=NAME
    #
    # Besides, arguments are used inside your code as an accessor
    # (self.argument), while options are all kept in a hash (self.options).
    #
    # Finally, arguments cannot have type :default or :boolean but can be
    # optional (supplying :optional => :true or :required => false), although
    # you cannot have a required argument after a non-required argument. If
    # you try it, an error is raised.
    #
    # @param [String | Symbol] name
    #   The name of the argument.
    # 
    # @param [Hash] options
    # 
    # @option options [String] :desc
    #   Description for the argument.
    # 
    # @option options [Boolean] :required
    #   If the argument is required or not (opposite of `:optional`).
    # 
    # @option options [Boolean] :optional
    #   If the argument is optional or not (opposite of `:required`).
    # 
    # @option options [:string | :hash | :array | :numeric] :type
    #   The type of the argument.
    # 
    # @option options [Object] :default
    #   Default value for this argument. It cannot be required and
    #   have default values.
    # 
    # @option options [String] :banner
    #   String to show on usage notes.
    # 
    # @return (see #class_arguments)
    # 
    # @raise [ArgumentError]
    #   Raised if you supply a required argument after a non-required one.
    #
    def method_argument name, **options
      build_argument( name, options, method_arguments )
    end

    alias_method :argument, :method_argument
    alias_method :arg,      :method_argument


    # Removes a previous defined class-level argument. If `:undefine` option is
    # given, un-defines accessors as well.
    #
    # @param [Array<String | Symbol>] *names
    #   Arguments to be removed
    #
    # @param [Boolean] undefine:
    #   Un-defines the arguments' setter methods as well.
    #
    # @example
    #
    #   remove_argument :foo remove_argument :foo, :bar, :baz, :undefine => true
    #
    def remove_method_argument *names, undefine: false
      remove_argument_from *names, scope: method_arguments, undefine: undefine
    end

    # @!endgroup Method-Specific Argument Class Methods # ********************

  end # class_methods ********************************************************
  
end # module ArgumentsConcern

# /Namespace
# =======================================================================

end # module Base
end # class Thor
