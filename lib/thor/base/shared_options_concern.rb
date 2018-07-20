# encoding: UTF-8
# frozen_string_literal: true


# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------

require 'active_support/concern'


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

# Support for sharing {Thor::Option} declarations among many 
# {Thor::Command} (methods). All class methods.
# 
module SharedOptionsConcern
  
  # Mixins
  # ========================================================================

  # Get concerned
  extend ActiveSupport::Concern

  
  class_methods do
  # ==========================================================================

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
    end # #find_shared_method_options

    alias_method :find_shared_options, :find_shared_method_options


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

  end # class_methods ********************************************************
  
end # module SharedOptionsConcern


# /Namespace
# =======================================================================

end # module Base
end # class Thor
