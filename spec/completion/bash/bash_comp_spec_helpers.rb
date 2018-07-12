module BashCompSpecHelpers
  module ClassMethods
    def basename
      BashCompleteFixtures::Main.basename
    end
  end

  def basename
    self.class.basename
  end

  def build_request *words, cword: -1, split: nil
    words.map! { |word|
      if word == '$0'
        basename
      else
        word
      end
    }

    if cword < 0
      cword = words.length + cword
    end

    # Set split based on the last word ending if it wasn't explicitly
    # provided.
    if split.nil?
      split = words[-1].end_with? '='
    end

    Thor::Completion::Bash::Request.new \
      words: words,
      cword: cword,
      cur: words[cword],
      prev: words[cword - 1],
      split: split
  end

  def self.included base
    base.send :extend, ClassMethods
  end
end