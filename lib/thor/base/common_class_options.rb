# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Deps
# -----------------------------------------------------------------------
require 'nrser'


# Refinements
# =======================================================================

require 'nrser/refinements/types'
using NRSER::Types

# Declarations
# =======================================================================

module Thor::Base; end


# Definitions
# =======================================================================

# Mixin that provides "macros" for including common class options.
# 
module Thor::Base::CommonClassOptions
  @@messages = Concurrent::Hash.new
  
  def self.define name, *args, &block
    @@messages[name.to_sym] = \
      NRSER::Message.new :class_option, name, *args, &block
  end
  
  
  define  :backtrace,
          desc: "Print stack traces with error messages",
          type: :boolean
  
  
  def common_class_options *names
    messages = Hamster::Hash.new @@messages
    
    names.map( &:to_sym ).each do |name|
      unless messages.key? name
        raise KeyError,
          "No common class option named #{ name }"
      end
      
      messages[name].send_to self
    end
  end
  
end # module Thor::Base::CommonClassOptions
