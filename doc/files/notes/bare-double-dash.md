The Bare Double-Dash CLI Argument (`--`)
==============================================================================

The behavior of "bare double-dash" command line argument does not seem to be formalized or specified anywhere (like pretty much everything CLI), but is generally understood and used to mean "this is the end of options", or "don't parse any options after here":

1.  https://unix.stackexchange.com/questions/11376/what-does-double-dash-mean-also-known-as-bare-double-dash

I'm most familiar with this as a way to pass CLI commands to other ones, say

    run-later -n my-cmd -- echo -n blah

where you would want `run-later` (which I made up for illustration purposes) to parse arguments something like

```yaml
options:
  n: my-cmd
arguments:
  - echo
  - '-n'
  - blah
```

Allowing `run-later` to re-form that `echo -n blah` command for use, and *especially* for it to parse `-n` as `my-cmd`, *not* `blah`.


The Problem
------------------------------------------------------------------------------

It was the "pass a CLI command to a CLI command" use case that led me into this double-dash business.

The actual problem was with deeply nested sub-commands... given a command nesting like

    main subcmd cmd --name=neil -- travis monitor -n

I was getting the `'name'` assigned to the `name` option (`-n` was a short alias for `--name`).

It turned out that Thor was tossing the `--` during parsing `subcmd` as a command of `main`, so when `cmd` parsed it was seeing

```ruby
args = ['--name=neil', 'travis', 'monitor', '-n']
```

Which was picking up the `-n` with no value for `name` and assigning it it's own name (I'll deal with what I think of that behavior elsewhere).

This was really confusing and frustrating because I had assumed that Thor treated `--` as I was used to: no option parsing after it. Which - of course - is not exactly true.

> **Note**
>
> This issue was addressable by not swallowing the `--` argument during option parsing, allowing subsequent parses to see and respect it, so it isn't directly connected to how Thor handles `--` with regards to options, but in order to fix the issue *and* preserve Thor's behavior required understanding that behavior, and, really, deciding if I wanted to preserve that behavior or not, since this would be the obvious time to change it, which is what led to this investigation.


What Thor Does
------------------------------------------------------------------------------

...and some some educated guesses on why.

Check this shit out:

https://github.com/erikhuda/thor/blob/d55d8ad81f1739ed86c0a110af29d1582e51b7e4/spec/parser/options_spec.rb#L149

You get behavior like

```ruby
"--bar -- --foo def -a" => {  opts: "bar" => "--foo",
                              args: ['def', '-a']     }
```

which, by the way, is obviously totally intentional:

https://github.com/erikhuda/thor/commit/cc52770822f2481c6f4254ecfd7470df7836f8d5

So, `--` obviously doesn't mean strait-up "stop parsing options".

This took me a while to comprehend... just thinking "WTF, why would someone type `--bar -- --foo def -a` and want `bar` to receive `--foo` while the *rest* of the arguments were not option parsed?"

I think I eventually figured it out:

Thor is using `--` *following a switch that wants value(s)* to mean that the following args should be interpreted as the literal string values, *not as subsequent option switches* if they start with `--`.

**It's a very funky way of escaping.**

Think: how do I pass the value `'--foo'` to the option `bar`? In Thor, like this:

    --bar -- --foo

The reason that the test (and all of this) is *so f'ing confusing* is that the bare double-dash *also turns of option parsing for the rest of the args*, so you get

```ruby
args = ['def', '-a']
```

as a *weird side-effect* of wanting to set

```ruby
opts = {'bar' => '--foo'}
```

So, when an option wants to consume an array - which in Thor just eat args until they hit another option switch - the array will receive **all the remaining args**, since nothing will be seen as a switch after the `--`, shedding some light on the

```ruby
"--foo a b -- c d -e" => {
  opts: "bar" => ['--foo', 'a', 'b', 'c', 'd', '-e'],
  args: []
}
```

test where `bar` is an array option that you see
[here](https://github.com/erikhuda/thor/blob/d55d8ad81f1739ed86c0a110af29d1582e51b7e4/spec/parser/options_spec.rb#L155).

Hashes are some-what similar, but stop when they find an arg that doesn't look like a hash pair, as you can see in the test after that (which must be fun with typos). Again, because the `--` was present, everything after that just becomes positional args because we had a `--` in the arguments.

When you're done swearing under your breath, we can move on to...


What I Think About This (and What I'm Going to Do About It)
------------------------------------------------------------------------------

At first impression, I really don't like this as a way of handling escaping option values that would otherwise be parsed as switches.

1.  I don't like how it confuses / abuses the simple interpretation of `--` as "stop parsing options".
    
    It took way too much time to understand the behavior, which to me means it's way too weird and complex.
    
2.  It only allows *one* option to have escaped value, since everything after the `--` will never be parsed as switches.
    
    This is not a scalable solution, and - again - is way too weird and complex a behavior to ask users to understand when they just want to use a CLI tool.

So, I want to get rid of this.

**_In Atli `--` means no more parsing._**

This leaves the question of what to do about option value escaping, but I'm going to punt on that for the moment.
