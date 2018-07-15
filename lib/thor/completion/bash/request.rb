# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------

require 'nrser'
require 'nrser/labs/i8'


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
  
# Structre to hold Bash complete request parameters
class Request < I8::Struct.new(
  cur: t.str,
  prev: t.str,
  cword: t.non_neg_int,
  split: t.bool,
  words: t.array( t.str )
)
  
end # class Request


# /Namespace
# =======================================================================

end # module Bash
end # module  Completion
end # class   Thor
