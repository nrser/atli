# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# ========================================================================

# Project / Package
# ------------------------------------------------------------------------

# Need to make sure {Thor} is loaded first in case a user file requires
# us here beforehand
require 'thor'


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

# {Thor} added as a {Thor.subcommand} to the includer of 
# {Thor::Completion::Bash} to expose Bash completion endpoints.
# 
class Subcmd < ::Thor

  # Commands
  # ========================================================================

  desc  'complete -- CUR PREV CWORD SPLIT WORDS...',
        "Provide Bash completions"
  
  # Execute Bash completion.
  # 
  # @param [Array] *_
  #   Ignored - input custom read from `ARGV`.
  # 
  # @return [void]
  #   Never returns - manually calls `exit` when done.
  # 
  def complete *_
    # logger.level = :trace

    logger.trace "Starting Bash complete...",
      ARGV: ARGV,
      args: args

    args = ARGV.dup

    args.shift while args[0] != '--'
    args.shift

    cur, prev, cword, split, *words = args

    request = Request.new \
      cur: cur, # options[:cur],
      prev: prev, # options[:prev],
      cword: cword.to_i, # options[:cword],
      split: split.truthy?, # options[:split],
      words: words

    logger.trace "Bash complete Request loaded",
      request: request

    results = begin
      self.class.target.bash_complete( request: request, index: 1 )
    rescue StandardError => error
      logger.error "Error raised processing Bash complete request",
        { request: request },
        error
      
      []
    end

    joined = results.shelljoin

    logger.trace "Sending Bash compelte response",
      request: request,
      results: results,
      joined: joined

    puts joined
    exit true
  end # #complete


  desc  'setup',
        "Source this output in your shell or profile to install."
  
  long_desc <<~END
    Prints Bash source code to STDOUT that hooks `complete` into the exe.
  END

  example "source <(#{ $0 } bash-complete setup)"

  # Print Bash source code to hook into `complete` to `$stdout`.
  # 
  # @return [nil]
  # 
  def setup
    bin = File.basename $0
    name = bin.underscore

    erb_src_path = ::Thor::ROOT.join  'support',
                                      'completion',
                                      'complete.inc.bash.erb'

    erb_src = erb_src_path.read

    bash_src = binding.erb erb_src

    puts bash_src

    nil
  end # #setup

end # class Subcmd


# /Namespace
# =======================================================================

end # module  Bash
end # module  Completion
end # class   Thor
