# encoding: UTF-8
# frozen_string_literal: true


# Project / Package
# -----------------------------------------------------------------------

require_relative './bash/argument_mixin'
require_relative './bash/command_mixin'
require_relative './bash/request'
require_relative './bash/subcmd'
require_relative './bash/thor_mixin'


# Namespace
# =======================================================================

class   Thor
module  Completion


# Definitions
# =======================================================================

# Experimental support for Bash completions.
# 
# To enable, require this module and add the following to your entry-point
# {Thor} subclass:
# 
#     include Thor::Completion::Bash
# 
# You should now have a `bash-complete` subcommand present. You can test
# this out with
# 
#     YOUR_EXE bash-complete help
# 
# where `YOUR_EXE` is replaced with your executable name.
# 
# You should see output like
#     
#     Commands:
#       locd bash-complete complete -- CUR PREV CWORD SPLIT WORDS...  # (...)
#       locd bash-complete help [COMMAND]                             # (...)
#       locd bash-complete setup                                      # (...)
# 
# 
# Then, to hook your executable into Bash's `compelte` builtin:
# 
#     source <(YOUR_EXE bash-complete setup)
# 
# where, again, `YOUR_EXE` is replaced with your executable name.
# 
module Bash
  
  # Hook to setup Bash complete on including {Thor} subclass.
  # 
  # 1.  Mixes {ThorMixin} into {Thor}.
  # 2.  Mixes {CommandMixin} into {Thor::Command}.
  # 3.  Creates a new subclass of {Subcmd} boun0d to `base` and adds that
  #     as `bash-complete` to `base` via {Thor.subcommand}.
  # 
  # @param [Class<Thor>] base
  #   The class that inluded {Thor::Completion::Bash}. Should be a {Thor}
  #   subclass and be the main/entry command of the program, though neither
  #   of these are enforced.
  # 
  # @return [nil]
  #   Totally side-effect based.
  # 
  def self.included base
    
    unless Thor.include? ThorMixin
      Thor.send :include, ThorMixin
    end

    unless Thor::Command.include? CommandMixin
      Thor::Command.send :include, CommandMixin
    end

    unless Thor::Argument.include? ArgumentMixin
      Thor::Argument.send :include, ArgumentMixin
    end

    subcmd_class = Class.new Subcmd do
      def self.target
        @target
      end
    end

    subcmd_class.instance_variable_set :@target, base
    
    # Install {Subcmd} as a subcommand
    base.send :subcommand,
              'bash-complete',
              subcmd_class,
      desc:   "Support for Bash command completion."

    nil
  end # #.included
  
end # module Bash

# /Namespace
# =======================================================================

end # module  Completion
end # class   Thor
