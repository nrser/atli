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

  def bash_complete_cur_split request:
    # The input was split at a `=`, so we're looking for a value for
    # an option whose name will be at {Request#prev}.

    logger.trace "Processing split Bash complete request...",
      command: self.name,
      request: request

    matching_options = options.values.select { |option|
      option.long_switch_tokens.
        reject { |token| token.end_with? '=' }.
        include? request.prev
    }

    case matching_options.length
    when 0
      return [].tap { |results|
        logger.trace "No matching options found",
          results: results,
          options: options.transform_values { |option|
            {
              tokens: option.all_switch_tokens,
              names: option.all_switch_names,
            }
          }
      }

    when 1
      option = matching_options[0]

      logger.trace "Unique option found for `request.prev`",
        prev: request.prev,
        option: option
      
      if option.enum
        return option.enum.
          select { |value|
            value.to_s.start_with? request.cur
          }.
          tap { |results|
            logger.trace \
              "Matched against enum option #{ option.name }",
              prev: request.prev,
              results: results,
              option: option
          }

      elsif option.complete
        return option.complete.call.
          select { |value|
            value.to_s.start_with? request.cur
          }.
          tap { |results|
            logger.trace \
              "Matched against complete option #{ option.name }",
              prev: request.prev,
              results: results,
              option: option
          }

      else
        return [].tap { |results|
          logger.trace \
            ( "Matched against non-enum option #{ option.name } " +
              "but we don't have any completions to provide" ),
            prev: request.prev,
            results: results,
            option: option
        }
      end

    else
      return [].tap { |results|
        logger.trace "Multiple options found for prev",
          results: results,
          prev: request.prev,
          options: matching_options
      }
    end
  end

  
  def bash_complete_cur request:
    return bash_complete_cur_split( request: request ) if request.split
    
    if request.cur == ''
      return options.values.
        flat_map { |option| option.long_switch_tokens }.
        # HACK  Just throw help in there... it's actually a command alias,
        #       FML.. prob why this lib didn't exist already...
        +( [ '--help' ] ).
        tap { |results|
          logger.trace "`request.cur` is ''; returning all long opts",
            results: results
        }
    end

    if request.cur.start_with? '-'
      return options.values.flat_map { |option|
        option.long_switch_names.flat_map { |name|
          if option.boolean?
            [ "--#{ name }", "--no-#{ name }" ]
          else
            "--#{ name }="
          end
        }
      }.
      +( [ '--help' ] ).
      select { |token| token.start_with? request.cur }.
      tap { |results|
        logger.trace "Completing partial switch token",
          results: results
      }
    end

    logger.warn "I've failed"

    return []
  end


  def bash_complete request:, index:
    logger.level = :trace

    logger.trace "ENTERING #{ self.class }##{ __method__ }",
      request: request,
      index: index,
      index_word: request.words[index]

    # Index we'll incremenet as we scan past options
    scan_index = index
    
    # Skip over args (for now)
    while scan_index < request.cword &&
          scan_index < request.words.length &&
          !request.words[scan_index].start_with?( '-' )
      scan_index += 1
    end

    if  scan_index == request.cword ||
        ( request.split &&
          scan_index == request.cword - 1 )
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
        logger.trace "No option or empty string found",
          results: []
      }
    end

    # match_word = request.words[scan_index]

    # matching_options = options.values.select { |option|
    #   option.all_switch_tokens.any? { |token| token.start_with? match_word }
    # }

    return [].tap { |results|
      logger.trace "Not implemented",
        results: results
    }
    
  end
  
end # module CommandMixin


# /Namespace
# =======================================================================

end # module  Bash
end # module  Completion
end # class   Thor
