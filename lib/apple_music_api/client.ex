defmodule AppleMusicAPI.Client do
  @moduledoc false

  alias AppleMusicAPI.{Config, Error, TokenCache}

  @config_keys [
    :team_id,
    :key_id,
    :private_key,
    :private_key_path,
    :base_url,
    :storefront,
    :token_ttl_seconds,
    :req_options,
    :user_token
  ]

  @meta_keys [:decode]

  @spec get(String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def get(path, opts) do
    {config_opts, meta, params} = split_opts(opts)
    config = Config.load(config_opts)

    with {:ok, access_token} <- fetch_access_token(config_opts) do
      # Replace {storefront} placeholder in path
      path_with_storefront = String.replace(path, "{storefront}", config.storefront)

      headers = [
        {"accept", "application/json"},
        {"authorization", "Bearer #{access_token}"}
      ]

      # Add user token if present (for library access)
      headers =
        if user_token = Keyword.get(config_opts, :user_token) do
          [{"music-user-token", user_token} | headers]
        else
          headers
        end

      req =
        Req.new(
          base_url: config.base_url,
          headers: headers
        )
        |> Req.merge(config.req_options)

      req
      |> Req.get(url: path_with_storefront, params: Map.new(params))
      |> normalize(meta)
    end
  end

  @spec post(String.t(), map(), keyword()) :: {:ok, term()} | {:error, term()}
  def post(path, body, opts) do
    {config_opts, meta, _params} = split_opts(opts)
    config = Config.load(config_opts)

    with {:ok, access_token} <- fetch_access_token(config_opts) do
      path_with_storefront = String.replace(path, "{storefront}", config.storefront)

      headers = [
        {"accept", "application/json"},
        {"content-type", "application/json"},
        {"authorization", "Bearer #{access_token}"}
      ]

      headers =
        if user_token = Keyword.get(config_opts, :user_token) do
          [{"music-user-token", user_token} | headers]
        else
          headers
        end

      req =
        Req.new(
          base_url: config.base_url,
          headers: headers
        )
        |> Req.merge(config.req_options)

      req
      |> Req.post(url: path_with_storefront, json: body)
      |> normalize(meta)
    end
  end

  defp fetch_access_token([]), do: TokenCache.fetch()
  defp fetch_access_token(config_opts), do: AppleMusicAPI.Token.access_token(config_opts)

  defp split_opts(opts) do
    {config, rest} = Keyword.split(opts, @config_keys)
    {meta, params} = Keyword.split(rest, @meta_keys)
    {config, meta, params}
  end

  defp normalize({:ok, %Req.Response{status: status, body: body}}, _meta)
       when status in 200..299 do
    {:ok, body}
  end

  defp normalize({:ok, %Req.Response{status: status, body: body}}, _meta),
    do: {:error, Error.from_http(status, body)}

  defp normalize({:error, reason}, _meta),
    do: {:error, {:transport_error, reason}}
end
