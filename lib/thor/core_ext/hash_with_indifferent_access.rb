# Namespace
# ========================================================================

class Thor
module CoreExt

# Definitions
# ========================================================================

# A hash with indifferent access and magic predicates.
#
#   hash = HashWithIndifferentAccess.new 'foo' => 'bar', 'baz' => 'bee', 'force' => true
#
#   hash[:foo]  #=> 'bar'
#   hash['foo'] #=> 'bar'
#   hash.foo?   #=> true
#
class HashWithIndifferentAccess < ::HashWithIndifferentAccess #:nodoc:

  protected
  # ========================================================================
    
    # Magic predicates. For instance:
    #
    #   options.force?                  # => !!options['force']
    #   options.shebang                 # => "/usr/lib/local/ruby"
    #   options.test_framework?(:rspec) # => options[:test_framework] == :rspec
    #
    def method_missing(method, *args)
      method = method.to_s
      if method =~ /^(\w+)\?$/
        if args.empty?
          !!self[$1]
        else
          self[$1] == args.first
        end
      else
        self[method]
      end
    end
    
  public # end protected ***************************************************
  
end


# /Namespace
# ========================================================================

end # module CoreExt
end # class Thor
