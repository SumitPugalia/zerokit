defmodule Zerokit.Redis.Behaviour do
  @moduledoc false
  @callback q(list(String.t())) :: {:ok, String.t()}
end
