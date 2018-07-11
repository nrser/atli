# encoding: UTF-8
# frozen_string_literal: true

# Requirements
# =======================================================================

# Project / Package
# -----------------------------------------------------------------------

require 'thor'
require 'thor/completion/bash'


# Definitions
# =======================================================================

# @todo document BashCompleteFixtures module.
module BashCompleteFixtures
  
  # A base class for all fixture {Thor} subclasses
  class Base < Thor
    def self.basename
      'bash-complete-fixture'
    end

    class_option  :base_class_bool_opt,
      desc:       "A :boolean class option on Base",
      type:       :boolean
    
    class_option  :base_class_str_opt,
      desc:       "A :string class option on Base",
      type:       :string
    
    class_option  :base_class_str_enum_opt,
      desc:       "A :string class option on Base with enum values",
      type:       :string,
      enum:       [
                    'base_class_str_enum_opt_1',
                    'base_class_str_enum_opt_2',
                  ]
  end # Base


  class Alpha < Base
    class_option  :main_class_bool_opt,
    desc:       "A :boolean class option on Main",
    type:       :boolean
  
    class_option  :main_class_str_opt,
      desc:       "A :string class option on Main",
      type:       :string
    
    class_option  :main_class_str_enum_opt,
      desc:       "A :string class option on Main with enum values",
      type:       :string,
      enum:       [
                    'main_class_str_enum_opt_1',
                    'main_class_str_enum_opt_2',
                  ]
  
    desc "dashed-alpha-cmd", "Alpha command with dashed usage name."
    
    def dashed_alpha_cmd
    end


    desc "underscored_alpha_cmd", "Alpha command with underscore usage name."
    
    def underscored_alpha_cmd
    end
  end # class Alpha


  class Main < Base
    include Thor::Completion::Bash

    class_option  :main_class_bool_opt,
      desc:       "A :boolean class option on Main",
      type:       :boolean
    
    class_option  :main_class_str_opt,
      desc:       "A :string class option on Main",
      type:       :string
    
    class_option  :main_class_str_enum_opt,
      desc:       "A :string class option on Main with enum values",
      type:       :string,
      enum:       [
                    'main_class_str_enum_opt_1',
                    'main_class_str_enum_opt_2',
                  ]
    
    desc "dashed-main-cmd", "Main command with dashed usage name."
    
    def dashed_main_cmd
    end


    desc "underscored_main_cmd", "Main command with underscore usage name."
    
    def underscored_main_cmd
    end


    subcommand 'alpha', Alpha, desc: 'Subcommand A'
    
  end


  
  
end # module BashCompleteFixtures
