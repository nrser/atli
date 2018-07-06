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


# Definitions
# =======================================================================

# Experimental support for Bash completions.
# 
module Bash
  
  Request = I8::Struct.new \
    cur: t.str,
    prev: t.str,
    cword: t.non_neg_int,
    split: t.bool,
    words: t.array( t.str )
  
  # Needs to be mixed in to {Thor}. It's all class methods at the moment.
  # 
  # @todo
  #   Deal with that {Thor::Group} thing? I never use it...
  #   
  module Thor
    
    # Methods to be mixed as class methods in to {Thor}.
    # 
    module ClassMethods
      
      # Get this class' {Thor::Command} instances, keyed by how their names will
      # appear in the UI (replace `_` with `-`).
      # 
      # @param [Boolean] include_hidden:
      #   When `true`, "hidden" commands will also be included.
      # 
      # @return [Hash<String, Thor::Command>]
      # 
      def all_commands_by_ui_name include_hidden: false
        all_commands.
          each_with_object( {} ) { |(name, cmd), hash|
            next if cmd.hidden? && !include_hidden
            hash[ name.tr( '_', '-' ) ] = cmd
          }
      end # .all_commands_by_ui_name

      # 
      # 
      def bash_complete comp_req:, index:
        # Find the command, if any
        
        logger.info __method__,
          comp_req: comp_req,
          index: index,
          word: comp_req.words[index]
        
        scan_index = index
        
        while (comp_req.words[scan_index] || '').start_with? '-'
          scan_index += 1
        end
        
        cmd_ui_name = comp_req.words[scan_index] || ''
        
        cmd = all_commands_by_ui_name[cmd_ui_name]
        
        if cmd.nil?
          return all_commands_by_ui_name.keys.select { |ui_name|
            ui_name.start_with? cmd_ui_name
          }
        end
        
        index = scan_index + 1
        
        # is it a subcommand?
        if subcommand_classes.key? cmd.name
          # It is, hand it off to there
          subcommand_classes[cmd.name].bash_complete \
            comp_req: comp_req,
            index: index
        else
          # It's a command, have that handle it
          cmd.bash_complete \
            comp_req: comp_req,
            index: index
        end
      end
      
    end # module ClassMethods
    
    # Hook to mix {ClassMethods} in on include.
    # 
    def self.included base
      base.extend ClassMethods
    end
    
  end # module Thor
  
  
  # Methods that need to mixed in to {Thor::Command}.
  # 
  module Command
    
    def bash_complete comp_req:, index:
      # TODO Handle
      return [] if comp_req.split
      
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
        select { |term| term.start_with? comp_req.cur }
    end
    
  end # module Command
  
end # module Bash

# /Namespace
# =======================================================================

end # module  Completion
end # class   Thor
