# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# ========================================================================

# Stdlib
# ------------------------------------------------------------------------
require 'set'

# Deps
# ------------------------------------------------------------------------

# Need {String#titleize}
require 'active_support/core_ext/string/inflections'

# Need {NRSER::LazyAttr}
require 'nrser/meta/lazy_attr'

# Project / Package
# ------------------------------------------------------------------------

require_relative './option'


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
      @groups = Set.new [*options[:groups]].map( &:to_sym )
      
      # # If
      # if options[:group].nil? && groups.count == 1
      #   options[:group] = groups.first.to_s.titleize
      # end
      
      super name, options
    end
    
    
    def initialize_options
      {
        # {Thor::Argument} options
        desc:               :@description,
        required:           :@required,
        type:               :@type,
        default:            :@default,
        banner:             :@banner,
        eunm:               :@enum,
        
        # {Thor::Option} options
        check_default_type: :@check_default_type,
        lazy_default:       :@lazy_default,
        group:              :@group,
        aliases:            :@aliases,
        hide:               :@hide,
        
        # {Thor::SharedOption} options
        groups:             :@groups,
      }.transform_values &method( :instance_variable_get )
    end
    
  end
  
  
  class IncludedOption < SharedOption
    
    # The match that resulted in this option getting included.
    # 
    # @return [Hash]
    #     
    attr_reader :match
    
    
    def initialize option:, match:
      super option.name, **option.initialize_options
      @match = match
    end
    
    
    +NRSER::LazyAttr
    def group
      case @group
      when false
        nil
      when String
        @group
      when nil
        default_group
      else
        logger.warn "Bad {Option#group}: #{ @group.inspect }",
          option: self
        nil
      end
    end
    
    
    +NRSER::LazyAttr
    def default_group
      return nil unless match[:groups]
      
      match[:groups].map { |group| group.to_s.titleize }.join ' / '
    end
    
  end
end
