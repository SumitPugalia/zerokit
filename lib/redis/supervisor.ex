defmodule Zerokit.Redis.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    pool_options = Application.get_env(:eredis, :pool_options)

    auth_opts =
      if Application.get_env(:eredis, :auth) == true do
        [
          {:username, Application.get_env(:eredis, :username)},
          {:password, Application.get_env(:eredis, :password)},
          {:tls,
           :tls_certificate_check.options(
             Application.get_env(:eredis, :host)
             |> String.to_charlist()
           )}
        ]
      else
        []
      end

    eredis_args =
      [
        {:host, Application.get_env(:eredis, :host) |> String.to_charlist()},
        {:port, Application.get_env(:eredis, :port)}
      ] ++ auth_opts

    children = [
      :poolboy.child_spec(:redis_pool, pool_options, eredis_args)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
