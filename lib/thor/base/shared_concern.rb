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

# Share stuff... define {Thor::Argument}, {Thor::Option} and whatever else
# you like once then apply those definitions to many commands.
# 
module SharedConcern

  extend ActiveSupport::Concern
  
  class_methods do
  # ==========================================================================

    def shared_defs
      @shared_defs ||= []
    end


    # def normalize_kind input
    #   {
    #     'arg' => 'argument',

    #   }
    # end


    def def_shared kind, name:, groups: nil, **options
      shared_defs << {
        name: name.to_s,
        kind: kind,
        groups: Set[*groups],
        options: options,
      }
    end
    
    
    def include_shared *names, kinds: nil, groups: nil, **overrides
      find_shared( *names, kinds: kinds, groups: groups ).
        each do |name:, kind:, groups:, options:|
          send kind, name, **options.merge( overrides )
        end
    end


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
    def find_shared *names, kinds: nil, groups: nil
      groups_set = Set[*groups]
      kinds_set = Set[*kinds]
      names.map! &:to_s

      results = []
      
      shared_defs.each do |name:, kind:, groups:, options:|
        match = {}
        
        if names.include? name
          match[:name] = true
        end
        
        match_groups = groups & groups_set
          
        unless match_groups.empty?
          match[:groups] = match_groups
        end

        if kinds_set.include? kind
          match[:kind] = true
        end
        
        unless match.empty?
          results << {
            name: name,
            kind: kind,
            groups: groups,
            options: options,
          }
        end
      end
    end # #find_shared

  end # class_methods ********************************************************
  
end # module SharedConcern

# /Namespace
# =======================================================================

end # module Base
end # class Thor
