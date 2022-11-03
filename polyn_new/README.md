# PolynNew

Provides `polyn.new` installer as an archive.

## Installation

In order to build a PolynHive application, we will need a few dependencies installed in our Operating System:

The Erlang VM and the Elixir programming language
Please take a look at this list and make sure to install anything necessary for your system. Having dependencies installed in advance can prevent frustrating problems later on.

### Elixir 1.12 or later
PolynHive is written in Elixir, and the application code will also be written in Elixir. We won't get far in a PolynHive app without it! The Elixir site maintains a great [Installation Page](https://elixir-lang.org/install.html) to help.

If we have just installed Elixir for the first time, we will need to install the Hex package manager as well. Hex is necessary to get a PolynHive app running (by installing dependencies) and to install any extra dependencies we might need along the way.

Here's the command to install Hex (If you have Hex already installed, it will upgrade Hex to the latest version):

```bash
$ mix local.hex
```

### Erlang 22 or later
Elixir code compiles to Erlang byte code to run on the Erlang virtual machine. Without Erlang, Elixir code has no virtual machine to run on, so we need to install Erlang as well.

When we install Elixir using instructions from the Elixir [Installation Page](https://elixir-lang.org/install.html), we will usually get Erlang too. If Erlang was not installed along with Elixir, please see the [Erlang Instructions](https://elixir-lang.org/install.html#installing-erlang) section of the Elixir Installation Page for instructions.

### PolynHive
To check that we are on Elixir 1.12 and Erlang 22 or later, run:

```bash
elixir -v
Erlang/OTP 22 [erts-10.7] [source] [64-bit] [smp:8:8] [async-threads:10] [hipe] [kernel-poll:false] [dtrace]
```

Elixir 1.12.1
Once we have Elixir and Erlang, we are ready to install the Polyn application generator:

```bash
$ mix archive.install hex polyn_new
```

The `polyn.new` generator is now available to generate new applications in the next guide, called Up and Running. The flags mentioned below are command line options to the generator; see all available options by calling `mix help polyn.new`.

## Generating Docs

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/polyn_new>.

