defmodule DemoMultiUpdate.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DemoMultiUpdate.Repo
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: DemoMultiUpdate.Supervisor)
  end
end
