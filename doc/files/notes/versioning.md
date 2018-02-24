Versions, Forks and the Mess I Made
==============================================================================

Currently
------------------------------------------------------------------------------

Going to just start at `0.1.0` and go our own with regards to versioning. I'm also adding {Thor::THOR_VERSION} to track the version of upstream Thor that Atli is "up to date" with.


Why
------------------------------------------------------------------------------

In brief...

There's a lot conversation around forking and semantic versioning, and not much consensus that I was able to pick up skimming around...

1.  https://github.com/semver/semver/issues/278
2.  https://github.com/semver/semver/issues/264
3.  https://github.com/semver/semver/issues/265
4.  https://github.com/semver/semver/issues/17

Gem versions allow fourth version number segments, but semver doesn't, and my tools (QB) don't handle it... and it would be nice to just stick to `major.minor.patch` for simplicity's sake.

The above links contain discussion of putting the info in the semver `build`, but that requires building out your own system for it, and no other tool is going to recognize it unless you teach it. Which I don't want to take on.

So, the most reasonable approach seemed to be: start over at `0.1.0`.


Previously, on Half-Baked Ideas in Action
------------------------------------------------------------------------------

It was written:

> For now, Atli versions will start with the upstream Thor version they are
> up-to-date with and use an additional fourth version "numberlet" to track
> fork changes.
>
> So, `0.20.0.0` is up-to-date with Thor `0.20.0` (actually, a little past
> it 'cause I just kept the few minor commits past `v0.20.0` present in
> `master` at the time of the fork) with nothing really changed except the
> gem name and the version.

which resulted in Atli versions `0.20.0.0` through `0.20.0.2` being published. Which sucks, but since nothing except Loc'd uses Atli, I'm going to yank them and hope it all works out going back to `0.1.0`.
