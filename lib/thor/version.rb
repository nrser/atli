require 'pathname'

class Thor
  # Absolute, expanded path to the gem's root directory.
  # 
  # @return [Pathname]
  # 
  ROOT = Pathname.new( __dir__ ).join( '..', '..' ).expand_path
  
  
  # Gem version string.
  # 
  # See {file:doc/files/notes/versioning.md} for details.
  # 
  # @return [String]
  # 
  VERSION = '0.1.11'
  
  
  # The version of Thor that Atli is up to date with.
  # 
  # Right now, it's the version of Thor that was forked, but if I'm able to
  # merge Thor updates in and end up doing so, I intend to update this to
  # reflect it.
  # 
  # See {file:doc/files/notes/versioning.md} for details.
  # 
  # @return [String]
  # 
  THOR_VERSION = '0.1.11'


  # Are we running from the source code (vesus from a Gem install)?
  # 
  # Looks for the `//dev` directory, which is not included in the package.
  # 
  # @return [Boolean]
  # 
  def self.running_from_source?
    ( ROOT + 'dev' ).directory?
  end
end
