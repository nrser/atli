# encoding: UTF-8
# frozen_string_literal: true


# Definitions
# =======================================================================

class Thor
  
  # Add an example to the next defined command.
  # 
  # @param [String] example
  #   The example text.
  # 
  # @return [nil]
  # 
  def self.example example
    @examples ||= []
    @examples << example
    nil
  end # #example
  
end # class Thor
