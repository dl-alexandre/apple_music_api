defmodule AppleMusicAPI.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [AppleMusicAPI.TokenCache]
    Supervisor.start_link(children, strategy: :one_for_one, name: AppleMusicAPI.Supervisor)
  end
end
