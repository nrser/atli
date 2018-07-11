# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Stdlib
# -----------------------------------------------------------------------

# Deps
# -----------------------------------------------------------------------

require 'nrser'
require 'nrser/labs/i8'

# Project / Package
# -----------------------------------------------------------------------


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types


# Namespace
# =======================================================================

class   Thor
module  Completion
module  Bash

# Definitions
# =======================================================================

# Methods mixed in to {Thor::Command}.
# 
module CommandMixin
  
  def bash_complete request:, index:
    # TODO Handle
    return [] if request.split
    
    logger.info __method__,
      cmd_name: name,
      options: options
    
    options.
      each_with_object( [ '--help' ] ) { |(name, opt), results|
        ui_name = name.to_s.tr( '_', '-' )
        
        if opt.type == :boolean
          results << "--#{ ui_name }"
          results << "--no-#{ ui_name }"
        else
          results << "--#{ ui_name }="
        end
      }.
      select { |term| term.start_with? request.cur }
  end
  
end # module CommandMixin
  


# /Namespace
# =======================================================================

end # module  Bash
end # module  Completion
end # class   Thor
