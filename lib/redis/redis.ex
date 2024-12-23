defmodule Zerokit.Redis do
  @moduledoc """
  Redis Interface
  """
  alias Zerokit.Redis.HTTP

  @spec q(list(String.t())) :: {:ok, any()}
  def q(command) do
    get_module().q(command)
  end

  defp get_module() do
    :zerokit
    |> Application.get_env(__MODULE__, [])
    |> Keyword.get(:redis_module, HTTP)
  end
end
