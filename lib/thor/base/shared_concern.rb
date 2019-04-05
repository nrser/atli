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
    
    
    protected
    # ========================================================================
      
      def this_class_shared_defs_ref
        @shared_defs ||= []
      end
      
      
      def copy_shared_defs_to array, inherited: true
        array.push *this_class_shared_defs_ref
        
        if  inherited &&
            superclass &&
            superclass.respond_to?( :copy_shared_defs_to, true )
          superclass.copy_shared_defs_to array
        end
        
        array
      end
      
    public # end protected ***************************************************
    

    def shared_defs inherited: true
      [].tap do |array|
        copy_shared_defs_to array, inherited: inherited
      end
    end


    def def_shared kind, name:, groups: nil, **options
      this_class_shared_defs_ref << {
        name: name.to_sym,
        kind: kind.to_sym,
        groups: Set[*groups].freeze,
        options: options.freeze,
      }.freeze
    end
    
    
    def include_shared selector, **overrides
      defs = shared_defs.select &selector
      
      if defs.empty?
        logger.warn "No shared parameters found",
          selector: selector,
          class: self
      end
      
      defs.each do |name:, kind:, groups:, options:|
        send kind, name, **options.merge( overrides )
      end
    end

  end # class_methods ********************************************************
  
end # module SharedConcern

# /Namespace
# =======================================================================

end # module Base
end # class Thor
