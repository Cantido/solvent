# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

VERSION 0.6

ARG ELIXIR_VERSION=1.14.2
ARG ERLANG_VERSION=25.2.3
ARG ALPINE_VERSION=3.17.0

all:
  BUILD +all-check
  BUILD +all-test-unlocked

all-check:
  BUILD +check \
    --ELIXIR_VERSION=1.14.2 \
    --ELIXIR_VERSION=1.13.4 \
    --ELIXIR_VERSION=1.12.3 \
    --ELIXIR_VERSION=1.11.4

all-test-unlocked:
  BUILD +test-unlocked \
    --ELIXIR_VERSION=1.14.2 \
    --ELIXIR_VERSION=1.13.4 \
    --ELIXIR_VERSION=1.12.3 \
    --ELIXIR_VERSION=1.11.4

deps:
  FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION}
  COPY mix.exs .
  COPY mix.lock .
  RUN mix local.rebar --force \
      && mix local.hex --force \
      && mix deps.get

check:
  FROM +deps

  # `git` is required for the `mix_audit` check
  # `reuse` is required for the `reuse` check
  RUN apk add git reuse

  COPY --dir lib/ test/ guides/ ./
  COPY .formatter.exs .check.exs .

  RUN mix check --only reuse

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
