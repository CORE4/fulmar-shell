# Fulmar Shell

This service takes a directory and a hostname (which might be 'localhost'). It then runs all commands given
in the given directory on that machine. You can access the return values and the output on both stdout and stderr.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fulmar-shell', :git => 'https://github.com/CORE4/fulmar-shell.git'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ git clone https://github.com/CORE4/fulmar-shell.git
    $ cd fulmar-shell
    $ gem build fulmar-shell.gemspec
    $ gem install fulmar-shell-#.#.#.gem

## Usage

You can test the shell in irb:

    $ irb -r fulmar-shell

And get a new shell object with

    irb(main):001:0> shell = Fulmar::Shell.new '.'

Shell.new takes two parameters: a directory (this is mandatory) and a hostname which is configured for
access via ssh with key authentication (i.e. does not require a password). You can supply a username with
'my-user@my-host'.
All commands will be executed in the given directory, which is the current directory in the example above.

    irb(main):002:0> shell.run 'echo Hello World'

This will run echo and return true/false depending on the return code of the command. Currently, you cannot
access the return code directly. You can, however, get the output of the last command(s):

    irb(main):003:0> shell.last_output
    => ["Hello World"]

And of course the last error messages:

    irb(main):004:0> shell.run 'echo Hello World 1>&2'
    Hello World
    => true
    irb(main):005:0> shell.last_error
    => ["Hello World"]

If you want to run multiple commands, you can supply them as an array. This is especially recommended if
you work on a remote shell since it will only connect once and chain all commands (with an "&&", so the first
failure will stop the execution of the list).

    irb(main):006:0> shell.run ['echo foo', 'echo bar', 'test -f non_existing_file', 'echo Hidden']
    => false
    irb(main):007:0> shell.last_output
    => ["foo", "bar"]

You can see that it stopped after the third command. You get the output of all commands before that.

If you activate the debug output, you can see which commands are executed:

    irb(main):008:0> shell.run ["echo 'in single quotes'", "echo \"in double quotes\""]
    sh -c 'cd . && echo '\''in single quotes'\'' && echo "in double quotes"'
    => true

The commands will always be run in /bin/sh. Single quotes will be escaped and if you run this on a remote shell,
it will escape them twice which might look weird. :)