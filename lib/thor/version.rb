class Thor
  # Gem version string.
  # 
  # For now, Atli versions will start with the upstream Thor version they are
  # up-to-date with and use an additional fourth version "numberlet" to track
  # fork changes.
  # 
  # So, `0.20.0.0` is up-to-date with Thor `0.20.0` (actually, a little past
  # it 'cause I just kept the few minor commits past `v0.20.0` present in
  # `master` at the time of the fork) with nothing really changed except the
  # gem name and the version.
  # 
  # @return [String]
  # 
  VERSION = "0.20.0.1-dev"
end
