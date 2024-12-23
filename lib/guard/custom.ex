defmodule Zerokit.Guard.Custom do
  @moduledoc """
  Custom guard.
  """

  @doc """
  Guards that passes when a binary or nil is the argument.

  ## Examples
    iex> bin_or_nil("binary")
    true

    iex> bin_or_nil(nil)
    true

    iex> bin_or_nil(%{})
    false

    iex> bin_or_nil({"anything", "else"})
    false
  """
  defguard bin_or_nil(value) when is_binary(value) or is_nil(value)

  @doc """
  A string that is neither null nor empty

  ## Examples
    iex> non_empty_string("truth")
    true

    iex> non_empty_string("")
    false

    iex> non_empty_string(nil)
    false
  """
  defguard non_empty_string(value) when is_binary(value) and value not in [nil, ""]
end
