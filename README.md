# `sogen`

**S**hellscript **O**ption **Gen**erator

`sogen` generates a shell-script with ...

* a powerful option parser,
* a help function that displays a well-formatted help-text
* and some other goodies

... from a template that contains definitions in a simple DSL for specifying options and corresponding help text.

***`sogen` keeps help-items always in sync with corresponding options***

## Installation

e.g.

`curl https://raw.githubusercontent.com/yaccob/sogen/latest/sogen -o /usr/local/bin/sogen && chmod +x /usr/local/bin/sogen`

... or clone https://github.com/yaccob/sogen and put the `sogen` script wherever you want it (in your PATH)

## Quick Start

Before we go into details let's start with a sample.
Following a long tradition we'll implement a _Hello World_ shell-script.

As a *template* we use the file `hello.sogen` with the following content:


```
@sogenstart

opt:    o output
id      optputFile
param   FILE
help    Write output to FILE

opt:    name
param   NAME . "World"
help    To whom we want to say "Hello"
:       DEFAULT: "World"

@sogenend

if [ "$outputFile" ]; then
	exec >"$outputFile"
fi

echo "Hello $name"
```

* `opt:` defines an option
* `id` defines the variable-name under which the script can refer to the option's value
* `param` defines a parameter for this option
* `help` defines the help-text for this option
* `:` continues the preceeding (help-)text in a new line

Now let's `sogen` do its' magic...

```
$ sogen -e hello.sogen
```

... and see what we've got.

The -e option instructs `sogen` to generate an executable shell-script with the same
basename as the template but `.sogen` replaced by `.sh`. So we end up with a shell-script named `hello.sh`. 

Let's see how we can use it:


```
$ ./hello.sh -h
  -h, --help         Display this help text and exit
  -o, --output=FILE  Write output to FILE
      --name=NAME    To whom we want to say "Hello"
                     DEFAULT: "World"
```

Okay, that's the help.

But what about the program's functionality?\
Let's try it:

```
$ ./hello.sh
Hello World
```

Looks good.

And now let's use an option we introduced in our specification: `-o` to write the output to a file.


```
$ ./hello.sh -o hello.txt
$ cat hello.txt 
Hello World

```

Works!

We defined the short-option `-o` with the corresponding long-option `--output`.\
So let's try the long-option as well:


```
$ ./hello.sh --output=hello1.txt
$ cat hello1.txt
Hello World
```

The long-option also works without `=`:


```
$ ./hello.sh --output hello2.txt
$ cat hello2.txt
Hello World
```

So far, we were only using the default behaviour which works because we provided 
a default value for `name`.\
Since `name` was defined as an option we can pass a value to get a different output. Let's try it:

```
$ ./hello.sh --name sogen
Hello sogen
```

Obviously we've got quite some functionality by pretty few lines of code.

It's nice to get help for the options but usually we also want to see in the help what the script is about and how to use it in general.

We can easily achieve this by adding a `header` to the template's `sogen`-speficication (`hello2.sogen`):

```
@sogenstart

header: hello.sh prints a greeting.
:       Usage: hello.sh [-o FILE] [--name NAME]
:
:       Optional arguments:

opt:    o output
param   FILE
help    Write output to FILE

opt:    name
param   NAME . "World"
help    To whom we want to say "Hello"
:       DEFAULT: "World"

@sogenend

if [ "$output" ]; then
	exec >"$output"
fi

echo "Hello $name"
```

If we now call `./hello2.sh -h` again, we get:

```
hello.sh prints a greeting.
Usage: hello.sh [-o FILE] [--name NAME]

Optional arguments:
  -h, --help         Display this help text and exit
  -o, --output=FILE  Write output to FILE
      --name=NAME    To whom we want to say "Hello"
                     DEFAULT: "World"
```

## Benefits

### Significantly less implementation- and maintenance effort

`hello.sogen` has 14 lines of code (empty lines not counted).

`hello.sh` that `sogen` generates for you is 70 lines of code (again, empty lines not counted).
And if you'd like to implement the same functionality manually it won't take much less.

This is a factor of 5!

**5 times less writing (and reading!)!**

### Readability 

While it's quite difficult to determine supported options from the source code it's very easy to read and understand a `sogen` specification. 

### Portability

There are many discussions about whether to use `getopt`, `getopts` or manually implemented option-parsing. Many of them focus on portability.

The code `sogen` generates is supposed to work for any POSIX compliant shell.

`sogen` itself can be executed in `bash` > version 3. This means that it can be used on macOS as well as on various Linux flavours.

`sogen` doesn't have any dependency to external tools except `cat`, nor does the code it generates use anything else but `sh` features and `cat`:
No `grep`, no `sed`, no `awk` - only builtin shell commands and `cat`.

### Consistency (help!, help!, help!)!

Regardless whether one uses `getopt`, `getopts` or manual parsing: usually there is no connection betwen the actual options and the help you provide. Keeping those two aspects in sync is quite some effort and it is error-prone as well.

By using `sogen` you don't need to worry about this. Whenever you add, remove or amend an option the help-output is updated accordingly.

### Unified look and feel

All `sogen`-generated scripts follow the same layout (regarding the generated parts of the code). This encompasses help-formatting as well as the way options are parsed or help is invoked.

## `sogen`-Spec Syntax

```
sogendef   ::= '@sogenstart' '\n' header? option* footer? '@sogenend' '\n'
header     ::= 'header' ':' textlines
footer     ::= 'footer' ':' textlines
option     ::= optdef (namedef? paramdef* helpdef?) '\n'*
optdef     ::= ('OPT' | 'opt') ':'? '[[:blank:]]+' (shortlong) '[[:blank:]]*' '\n'
namedef    ::= 'name' '[[:blank:]]+' ID '[[:blank:]]*' '\n'
paramdef   ::= 'param' '[[:blank:]]'+ pdef '[[:blank:]]'* '\n'
helpdef    ::= 'help' textlines

textlines  ::= '[[:blank:]]+' TEXT '\n' (':' '[[:blank:]]+' TEXT '\n')*
shortlong  ::= (SHORT LONG) | (LONG SHORT) | SHORT | LONG
pdef       ::= PNAME ('[[:blank:]]+' ID ('[[:blank:]]+' DEFAULT)?)?

SHORT      ::= '[[:lower:]]'
LONG       ::= '[[:lower:]]'+ ('-' '[[:lower:]]'+)+
PNAME      ::= '[[:upper:]]'+
ID         ::= '[_[:alpha:]]' '[_[:alnum:]]'* | '.'
DEFAULT    ::=  TEXT
TEXT       ::= '[^\n]*'
```

<!---
* With `opt:` we define an option as a short-option (-[[:alpha:]]) and/or long-option (--[[:alpha:]][[:alnum:]]+). The `-` or `--` is omitted in the specification.
* `id` specifies the variable-name under which the script can refer to the option's value 
  if the option has no parameters or one parameter.
  * If no id is specified, `sogen` will use the string that defined the long-option
  (without the leading `--`) after replacing `-` by `_`.
  * If no `id` and no long-option was provided, the short-option character will become the id.
* `param` defines an option-parameter.
  * A parameter definition requires at least the parameter-name that will be
    displayed in the help output.
  * Additionally an `id` can be added. That's the variable-name that will be used 
    in the shellscript to refer to this option-parameter.
    * The special character `.` will be replaced by the id of option itself.
      It can occur anywhere in the parameter-id - so if you specify ...
      ```
      param FILE ._file
-->


## Multi-Parameter Options

`sogen` supports options with multiple parameters:

```
@sogenstart

opt:    multi-param
param   P ._p "value p"
param   Q ._q "value q"
help    multi-parameter option
:       DEFAULTS:
:       P: 'value p'
:       Q: 'value q'

@sogenend
```

## Debugging

Any `sogen`-generated script contains a function that dumps the actual value of all available options. The function is called `sogen_dump` and your script can call it whenever you need it. This is particularily useful while developing, testing and debugging a script.

Furthermore a long-option `--sogen-dump` is generated by `sogen`.
If you want to get all options and positional parameters printed just call your generated script with `--sogen-dump` and all other intended arguments.\
All variables set by `sogen` plus all positional arguments will be printed to stdout,
and the script will terminate with exit code 0.

Of course you can also call the generated function `sogen_dump` from within your script whenever you want.

## Syntax-Coloring

Currently no editor and no IDE know about `sogen` and its' syntax. 

Rather than trying to implement dozens of plugins for various editors and IDEs `sogen` supports a simple trick:

If you embed your `sogen`-specification like this the `sogen`-template becomes a valid bash-script:

```
cat hello3.sogen
```

```
<<-@SOGEN
@sogenstart

opt:    o output
id      optputFile
param   FILE
help    Write output to FILE

opt:    name
param   NAME . "World"
help    To whom we want to say "Hello"
:       DEFAULT: "World"

@sogenend

if [ "$outputFile" ]; then
	exec >"$outputFile"
fi

echo "Hello $name"
@SOGEN
```

`sogen` ignores the lines ...

```
<<-@SOGEN
```

... and ...

```
@SOGEN
```

... meaning that those lines are not included in the output.

This way editors that support syntax-coloring for `bash`-scripts won't get confused.

You can even go a step further by inlining the generated code like below.

Provided you make your template (`hello4.sogen`) executable (`chmod +x hello4.sogen`) you'll be able to execute this template directly:


```
$ cat hello4.sogen
#!/usr/bin/env sh

eval "$(sogen <<-@SOGEN
@sogenstart

opt:    o output
id      optputFile
param   FILE
help    Write output to FILE

opt:    name
param   NAME . "World"
help    To whom we want to say "Hello"
:       DEFAULT: "World"

@sogenend
)"

if [ "$outputFile" ]; then
	exec >"$outputFile"
fi

echo "Hello $name"
```

Strictly speaking this approach isn't a `sogen`-feature but a `bash`-feature.

Let's try it:

```
$ chmod +x hello4.sogen
$ ./hello4.sogen --help
  -h, --help         Display this help text and exit
  -o, --output=FILE  Write output to FILE
      --name=NAME    To whom we want to say "Hello"
                     DEFAULT: "World"
```

Downside of this approach is that 

* `sogen` needs to be available during execution, and
* the code-generation will take place every time you execute the script. This will increase the execution time.

Yet, this approach may speed you up during development of the script.

## Implementation Recommendations

## Contributing
