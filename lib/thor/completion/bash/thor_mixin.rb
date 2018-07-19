# encoding: UTF-8
# frozen_string_literal: true


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

# To be mixed in to {Thor}. It's all class methods at the moment.
# 
# @todo
#   Deal with that {Thor::Group} thing? I never use it...
#   
module ThorMixin
  
  # Methods to be mixed as class methods in to {Thor}.
  # 
  module ClassMethods

    # Handles Bash completion requests at the {Thor} *class* level.
    # 
    # This consists of:
    # 
    # 1.  Finding the next word in the `request` at of after `index` that
    #     identifies next the command or subcommand.
    #     
    #     **NOTE** This is done by simply scanning over words that start 
    #     with `-`, which will not work for options that take values as
    #     separate shell words.
    #     
    # 2.  Looking for an exact match command or subcommand to the word from
    #     (1), and passing processing off to the respective {Thor::Command}
    #     instance or {Thor::Base} subclass.
    # 
    # 3.  Or returning an array of "starts with" matches for available
    #     {Thor::Base::ClassMethods#all_commands} and any partial input.
    #     
    #     Checks against both {Thor::Command#name} ("method" name) and
    #     {Thor::Command#usage_name}, preferring usage name.
    # 
    # @param [Request] request:
    #   
    # 
    def bash_complete request:, index:
      logger.level = :trace

      logger.trace __method__,
        request: request,
        index: index,
        word: request.words[index]
      
      # Index we'll incremenet as we scan past options
      scan_index = index
      
      while scan_index < request.cword &&
            scan_index < request.words.length &&
            request.words[scan_index].start_with?( '-' )
        scan_index += 1
      end

      if scan_index == request.cword
        return bash_complete_cur request: request
      end

      unless scan_index < request.words.length
        # We ran out of words without hitting a command name or ending 
        # empty string (for which we would provide all commands as options)
        # 
        # TODO  In the future we can deal with half-written class options
        #       I guess? Maybe? But for now we just give up.
        # 
        return [].tap { |results|
          logger.trace "No command or empty string found",
            results: []
        }
      end
      
      # OK, we should have either '' or something we can match
      match_word = request.words[scan_index]

      # We have nothing, return all commands
      if match_word == ''
        return all_commands.values.map( &:usage_name ).tap { |results|
          logger.trace "Empty match word, returning all commands",
            results: results
        }
      end

      # See what possibilities we have
      possibilities = find_command_possibilities match_word.tr( '-', '_' )

      case possibilities.length
      when 0
        # We couldn't match anything
        logger.trace "Found no command possibilities",
          match_word: match_word,
          results: []

        return []

      when 1
        # We have a unique match

        logger.trace "Unique command matched",
          match_word: match_word,
          match: possibilities[0]
      
        # pass to below

      else
        # There is more than one possbility, but we're trying to fill in 
        # something later on, so we're SO
        return []
      end

      # See if we're got an extact match
      cmd = all_commands[ possibilities[0].underscore ]
      
      # Bump the index to the scan index + 1 to go past the word we just
      # used to find `cmd`
      index = scan_index + 1
      
      # is it a subcommand?
      if subcommand_classes.key? cmd.name
        # It is, hand it off to there
        subcommand_classes[cmd.name].bash_complete \
          request: request,
          index: index
      else
        cmd.bash_complete request: request, index: index, klass: self
      end
    end # #bash_complete


    
    private
    # ========================================================================

      def bash_complete_cur request:
        logger.trace "START #{ self.class.safe_name }.#{ __method__ }",
          cur: request.cur

        cur_method_name = if request.cur.start_with? '-'
          request.cur
        else
          request.cur.tr( '-', '_' )
        end

        method_name_matches = find_command_possibilities( cur_method_name ).map &:to_s

        logger.trace "Matched #{ method_name_matches.length } method name(s)",
          matches: method_name_matches # ,
          # all_method_names: all_commands.keys,
          # map: map
        
        case method_name_matches.length
        when 0
          return [].tap { |results|
            logger.trace "No commands matched",
              results: results
          }
        
        when 1
          method_name = method_name_matches[0]

          logger.trace "Found unique method name",
            method_name: method_name

          cmd = all_commands[ method_name ] || all_commands[ map[ method_name ].to_s ]

          logger.trace "Got command",
            command: cmd

          cmd.names_by_format.each { |format, name|
            if name.start_with?( request.cur )
              return [ name ].tap { |results|
                logger.trace \
                  "Prefix-matched cur against cmd's #{ format } name",
                  name_format: format,
                  results: results,
                  cmd: cmd
              }
            end
          }

          matching_mappings = map.map { |map_name, cmd_name|
            map_name.to_s if  cmd.name == cmd_name.to_s &&
                              map_name.to_s.start_with?( request.cur )
          }.compact

          return matching_mappings unless matching_mappings.empty?

          return [ request.cur ]

        else
          # There is more than one possbility...

          cmd_matches = method_name_matches.map { |method_name|
            all_commands[ method_name ] || all_commands[ map[ method_name ].to_s ]
          }.uniq

          logger.trace "Unique command matches",
            cmd_matches: cmd_matches

          usage_name_results = cmd_matches.map( &:usage_name ).select { |usage_name|
            usage_name.start_with? request.cur
          }

          return usage_name_results unless usage_name_results.empty?

          return method_name_matches.select { |method_name|
            method_name.start_with? request.cur
          }
        end
      end # #bash_complete_cur
      
    public # end private *****************************************************

  end # module ClassMethods
  

  # Hook to mix {ClassMethods} in on include.
  # 
  def self.included base
    base.extend ClassMethods
  end

end # module ThorMixin


# /Namespace
# =======================================================================

end # module  Bash
end # module  Completion
end # class   Thor
