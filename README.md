Atli
==============================================================================

[![Gem Version](http://img.shields.io/gem/v/atli.svg)][gem]
[![Build Status](http://img.shields.io/travis/nrser/atli.svg)][travis]

[gem]: https://rubygems.org/gems/atli
[travis]: http://travis-ci.org/nrser/atli

Description
-----------
[Thor][] is a simple and efficient tool for building self-documenting command line utilities.

[Thor]: https://github.com/erikhuda/thor

Atli is a fork of Thor that adds some stuff. For the time being, it intends to be a drop-in replacement, though this might change at some point in the future.

This means that Alti still uses the Thor name and file-space. You require it like

```ruby
require 'thor'
```

and use it exactly like you would Thor.

As you may suspect, this is likely to wreck havoc if you have real Thor installed as well. Please choose one.

Installation
------------
    gem install atli

Usage and documentation
-----------------------

At some point, I'd like to document the additional features that Atli introduces on top of Thor, and even perhaps add general documentation with greater coverage and detail than what is available for Thor (sparse documentation is probably it's weakest point when getting started), but for now all you've got is the [Thor wiki][] and [Thor homepage][].

[Thor wiki]: https://github.com/nrser/atli/wiki
[Thor homepage]: http://whatisthor.com/

Contributing
------------
If you would like to help, please read the [CONTRIBUTING][] file for suggestions.

[contributing]: CONTRIBUTING.md

License
-------
Released under the MIT License.  See the [LICENSE][] file for further details.

[license]: LICENSE.md
