VERSION 0.6

ARG ELIXIR_VERSION=1.13

all:
  BUILD +check \
    --ELIXIR_VERSION=1.14 \
    --ELIXIR_VERSION=1.13 \
    --ELIXIR_VERSION=1.12 \
    --ELIXIR_VERSION=1.11

deps:
  FROM elixir:${ELIXIR_VERSION}-alpine
  COPY mix.exs .
  COPY mix.lock .
  RUN mix local.rebar --force \
      && mix local.hex --force \
      && mix deps.get

check:
  FROM +deps

  COPY --dir lib/ test/ ./

  RUN mix test
