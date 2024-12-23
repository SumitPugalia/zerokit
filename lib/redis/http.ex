defmodule Zerokit.Redis.HTTP do
  @moduledoc false
  alias Zerokit.Redis.Behaviour
  @behaviour Behaviour

  @spec q(list(String.t())) :: {:ok, String.t()}
  def q(args) do
    :poolboy.transaction(:redis_pool, fn worker -> :eredis.q(worker, args, 5000) end)
  end
end
