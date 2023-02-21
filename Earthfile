# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

VERSION 0.6

ARG ELIXIR_VERSION=1.13

all:
  BUILD +all-check
  BUILD +all-test-unlocked

all-check:
  BUILD +check \
    --ELIXIR_VERSION=1.14 \
    --ELIXIR_VERSION=1.13 \
    --ELIXIR_VERSION=1.12 \
    --ELIXIR_VERSION=1.11

all-test-unlocked:
  BUILD +test-unlocked \
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

  # `git` is required for the `mix_audit` check
  # `reuse` adds the `reuse` program for checking the FSFE's Reuse copyright tool
  RUN apk add git reuse

  COPY --dir lib/ test/ guides/ ./

  RUN mix check

test-unlocked:
  FROM elixir:${ELIXIR_VERSION}-alpine

  WORKDIR /app
  RUN mix do local.rebar --force, local.hex --force
  COPY mix.exs .
  COPY mix.lock .

  RUN mix deps.unlock --all
  RUN mix deps.get

  COPY --dir lib/ test/ ./

  RUN mix test
