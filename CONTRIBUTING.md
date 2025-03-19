# Contributing

Realisitcally, this project will likely run fine on any relatively modern Erlang
and Elixir version, but this project specifies the following language versions
(see `.tool-versions`):

* Erlang OTP 27.1.2
* Elixir 1.17.3

One of the best ways to manage multiple Erlang/Elixir versions is
[asdf](https://github.com/asdf-vm/asdf) version manager. If you're using
`asdf-vm`, you can run the following commands to install the specified language
versions:

```bash
asdf plugin-add erlang
asdf plugin-add elixir
asdf install
```

Once you have sufficient versions of Erlang and Elixir versions installed, you
can download the development dependencies:

```bash
mix deps.get
```

Assuming everything was done correctly, you should be able to successfully run
the test suite:

```bash
mix test
```
