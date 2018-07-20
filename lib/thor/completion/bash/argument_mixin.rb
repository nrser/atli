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

# Methods mixed in to {Thor::Argument}.
# 
module ArgumentMixin

  def bash_complete request:, klass:
    # logger.level = :trace

    logger.trace "ENTERING #{ self.class }##{ __method__ }",
      name: name,
      complete: complete,
      request: request,
      klass: klass

    unless complete
      return [].tap { |results|
        logger.trace "No `#complete` proc to call",
          results: results
      }
    end

    values = case complete.arity
    when 0
      complete.call
    else
      complete.call request: request, klass: klass, command: self
    end

    logger.trace "Got values", values: values

    values.
      select { |value| value.start_with? request.cur }.
      tap { |results|
        logger.trace "Selected values for argument #{ name }",
          results: results
      }
  end
  
end # module ArgumentMixin


# /Namespace
# =======================================================================

end # module  Bash
end # module  Completion
end # class   Thor
