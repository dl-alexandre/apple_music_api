defmodule AppleMusicAPI.Config do
  @moduledoc false

  @default_base_url "https://api.music.apple.com"
  @default_storefront "us"
  @default_ttl 10 * 60

  defstruct [
    :team_id,
    :key_id,
    :private_key,
    :private_key_path,
    :base_url,
    :storefront,
    :token_ttl_seconds,
    :req_options
  ]

  @type t :: %__MODULE__{
          team_id: String.t() | nil,
          key_id: String.t() | nil,
          private_key: String.t() | nil,
          private_key_path: String.t() | nil,
          base_url: String.t(),
          storefront: String.t(),
          token_ttl_seconds: pos_integer(),
          req_options: keyword()
        }

  @doc """
  Build a config struct by merging `Application.get_all_env/1` with per-call `opts`.
  Per-call options win.
  """
  @spec load(keyword()) :: t()
  def load(opts \\ []) do
    env = Application.get_all_env(:apple_music_api)
    merged = Keyword.merge(env, opts)

    %__MODULE__{
      team_id: fetch(merged, :team_id),
      key_id: fetch(merged, :key_id),
      private_key: fetch(merged, :private_key),
      private_key_path: fetch(merged, :private_key_path),
      base_url: Keyword.get(merged, :base_url, @default_base_url),
      storefront: Keyword.get(merged, :storefront, @default_storefront),
      token_ttl_seconds: Keyword.get(merged, :token_ttl_seconds, @default_ttl),
      req_options: Keyword.get(merged, :req_options, [])
    }
  end

  @doc "Return the PEM string, reading from `:private_key_path` if needed."
  @spec private_key_pem!(t()) :: String.t()
  def private_key_pem!(%__MODULE__{private_key: pem}) when is_binary(pem) and pem != "", do: pem

  def private_key_pem!(%__MODULE__{private_key_path: path}) when is_binary(path) and path != "" do
    File.read!(path)
  end

  def private_key_pem!(_), do: raise(ArgumentError, "missing :private_key or :private_key_path")

  defp fetch(kw, key) do
    case Keyword.get(kw, key) do
      "" -> nil
      value -> value
    end
  end
end
