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

  attr_reader :complete

  def initialize name, options = {}
    logger = NRSER::Log[ArgumentMixin]
    logger.level = :trace
    logger.trace "INIT",
      argument: self,
      options: options

    @complete = options[:complete]
    super
  end
  
end # module ArgumentMixin


# /Namespace
# =======================================================================

end # module  Bash
end # module  Completion
end # class   Thor
