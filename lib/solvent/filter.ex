# SPDX-FileCopyrightText: 2023 Rosa Richter
#
# SPDX-License-Identifier: MIT

defprotocol Solvent.Filter do
  @moduledoc """
  A protocol for matching events.

  Filter expressions are built up from structs that implement this protocol, and they may be nested.
  Solvent uses a shorthand for building filter expressions from structs using keyword lists.

  In general, filter expressions are keyword lists, with the keys being a filter dialect, and the values being properties for that filter.
  Solvent supports all the filter dialects given in the WIP CloudEvents subscriptions spec, except for the `sql` dialect.

  ## Filters

  The `exact` filter compares its properties against an event's properties.

      [exact: [type: "com.example.event", source: "myapp"]]

  The `prefix` filter specifies string values that an event's properties must start with.

      [prefix: [type: "com.example.", subject: "https://example.com/objects"]]

  The `suffix` filter matches properties that end with the given strings.

      [suffix: [type: ".created"]]

  The `all` dialect lets you combine multiple filters, all of which must match.

      [all: [
        [prefix: [type: "com.example."]],
        [exact: [source: "myapp"]]
      ]]

  The `any` filter works similarly, but will return true if any one of the given filters is true.

      [any: [
        [exact: [type: "com.example.event"]],
        [exact: [type: "com.example.other_event"][
      ]]

  Finally, the `not` filter inverts the match of another filter.

      [not: [exact: [type: "com.example.event"]]]
  """

  @doc """
  Returns `true` if the given event matches the filter's criteria, `false` otherwise.
  """
  @spec match?(Solvent.Filter.t(), Solvent.Event.t()) :: boolean()
  def match?(filter, event)
end
