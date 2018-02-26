Too Broken to Fail: Thor's Failure to Fail on Failure
==============================================================================

Ya know, if you can't say nice things... so I'll just leave this here:

1.  https://github.com/erikhuda/thor/issues/244
2.  https://github.com/erikhuda/thor/pull/521

Basically, when a Thor command invoked via `Thor::Base::ClassMethods` - which is *the* documented way to [make an executable with Thor][] - if the command fails because a `Thor::Error` is raised - like when bad arguments are provided, among other things - Thor writes the error message to `$stderr` then... nothing. Absolutely nothing.

[make an executable with Thor]: https://github.com/erikhuda/thor/wiki/Making-An-Executable)

`.start` returns `nil` and the script just goes on it's merry way like nothing ever happen. Usually, this means it reaches it's end, since thats how the Thor wiki recommends to write executables, and script exits normally with status `0`.

No one really seems to know why it does this... best guess is that developers wanted to test `.start` - which sure seems like it's there for use in executables - but didn't want to test it *in* executables (spawning subprocesses is much slower than calling functions). It's now been like this for years and people are scared to change it, despite it causing all sorts of problems.


Anyways...
------------------------------------------------------------------------------

I'm going to fix this so that when Atli terminates due to an error it reports that it terminated due to an error.

For the moment, I've done so by adding `Thor::Base::ClassMethods#exec!` that does almost the same thing as `.start`, but acts like it owns the place and always tries to exit

***
