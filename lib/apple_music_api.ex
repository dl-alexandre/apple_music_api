defmodule AppleMusicAPI do
  @moduledoc """
  Elixir client for the [Apple Music API](https://developer.apple.com/documentation/applemusicapi).

  The public surface is intentionally small:

      AppleMusicAPI.search_catalog("The Beatles", types: ["songs", "albums"])
      AppleMusicAPI.get_song("123456789")
      AppleMusicAPI.get_album("987654321")
      AppleMusicAPI.get_artist("111111111")
      AppleMusicAPI.get_playlist("222222222")
      AppleMusicAPI.get_songs_by_isrc("USUG12002836")
      AppleMusicAPI.get_user_playlists()
      AppleMusicAPI.token()

  ## Configuration

      config :apple_music_api,
        team_id: System.get_env("APPLE_TEAM_ID"),
        key_id: System.get_env("MUSIC_KEY_ID"),
        private_key: System.get_env("MUSIC_PRIVATE_KEY"),
        base_url: "https://api.music.apple.com",
        storefront: "us",
        token_ttl_seconds: 600

  Every function also accepts per-call `opts` that override the application config.
  """

  alias AppleMusicAPI.{Client, Token}

  @type opts :: keyword()
  @type response :: {:ok, map()} | {:error, term()}

  @doc "Return a cached-per-call Apple Music **access token** (after the JWT → token exchange)."
  @spec token(opts) :: {:ok, String.t()} | {:error, term()}
  def token(opts \\ []), do: Token.access_token(opts)

  @doc """
  Search the Apple Music catalog.

  ## Parameters

    - `term`: Search query term
    - `opts`: 
      - `:types` - List of resource types to search ("songs", "albums", "artists", "playlists")
      - `:limit` - Maximum results per type (1-25, default 5)
      - `:offset` - Pagination offset
      - `:storefront` - Storefront code (default from config or "us")

  ## Examples

      AppleMusicAPI.search_catalog("The Beatles", types: ["songs", "albums"])
      AppleMusicAPI.search_catalog("rock", types: ["playlists"], limit: 10)
  """
  @spec search_catalog(String.t(), opts) :: response
  def search_catalog(term, opts \\ []) when is_binary(term) do
    types = Keyword.get(opts, :types, ["songs", "albums", "artists"])
    limit = Keyword.get(opts, :limit, 5)
    offset = Keyword.get(opts, :offset, 0)
    storefront = Keyword.get(opts, :storefront, nil)

    query_opts = [
      term: term,
      types: Enum.join(types, ","),
      limit: limit,
      offset: offset
    ]

    query_opts =
      if storefront, do: Keyword.put(query_opts, :storefront, storefront), else: query_opts

    Client.get("/v1/catalog/{storefront}/search", query_opts)
  end

  @doc """
  Get a song by ID.

  ## Parameters

    - `id`: Apple Music song ID
    - `opts`: Optional `:storefront` override
  """
  @spec get_song(String.t(), opts) :: response
  def get_song(id, opts \\ []) when is_binary(id) do
    Client.get("/v1/catalog/{storefront}/songs/#{id}", opts)
  end

  @doc """
  Get multiple songs by IDs.

  ## Parameters

    - `ids`: List of Apple Music song IDs (max 100)
    - `opts`: Optional `:storefront` override
  """
  @spec get_songs([String.t()], opts) :: response
  def get_songs(ids, opts \\ []) when is_list(ids) do
    ids_str = Enum.join(Enum.take(ids, 100), ",")
    Client.get("/v1/catalog/{storefront}/songs", Keyword.put(opts, :ids, ids_str))
  end

  @doc """
  Get a song by ISRC (International Standard Recording Code).

  ## Parameters

    - `isrc`: ISRC code (e.g., "USUG12002836")
    - `opts`: Optional `:storefront` override
  """
  @spec get_songs_by_isrc(String.t(), opts) :: response
  def get_songs_by_isrc(isrc, opts \\ []) when is_binary(isrc) do
    Client.get("/v1/catalog/{storefront}/songs", Keyword.put(opts, :"filter[isrc]", isrc))
  end

  @doc """
  Get an album by ID.

  ## Parameters

    - `id`: Apple Music album ID
    - `opts`: Optional `:storefront` override
  """
  @spec get_album(String.t(), opts) :: response
  def get_album(id, opts \\ []) when is_binary(id) do
    Client.get("/v1/catalog/{storefront}/albums/#{id}", opts)
  end

  @doc """
  Get multiple albums by IDs.

  ## Parameters

    - `ids`: List of Apple Music album IDs (max 100)
    - `opts`: Optional `:storefront` override
  """
  @spec get_albums([String.t()], opts) :: response
  def get_albums(ids, opts \\ []) when is_list(ids) do
    ids_str = Enum.join(Enum.take(ids, 100), ",")
    Client.get("/v1/catalog/{storefront}/albums", Keyword.put(opts, :ids, ids_str))
  end

  @doc """
  Get an artist by ID.

  ## Parameters

    - `id`: Apple Music artist ID
    - `opts`: Optional `:storefront` override
  """
  @spec get_artist(String.t(), opts) :: response
  def get_artist(id, opts \\ []) when is_binary(id) do
    Client.get("/v1/catalog/{storefront}/artists/#{id}", opts)
  end

  @doc """
  Get multiple artists by IDs.

  ## Parameters

    - `ids`: List of Apple Music artist IDs (max 100)
    - `opts`: Optional `:storefront` override
  """
  @spec get_artists([String.t()], opts) :: response
  def get_artists(ids, opts \\ []) when is_list(ids) do
    ids_str = Enum.join(Enum.take(ids, 100), ",")
    Client.get("/v1/catalog/{storefront}/artists", Keyword.put(opts, :ids, ids_str))
  end

  @doc """
  Get a playlist by ID.

  ## Parameters

    - `id`: Apple Music playlist ID
    - `opts`: Optional `:storefront` override
  """
  @spec get_playlist(String.t(), opts) :: response
  def get_playlist(id, opts \\ []) when is_binary(id) do
    Client.get("/v1/catalog/{storefront}/playlists/#{id}", opts)
  end

  @doc """
  Get multiple playlists by IDs.

  ## Parameters

    - `ids`: List of Apple Music playlist IDs (max 100)
    - `opts`: Optional `:storefront` override
  """
  @spec get_playlists([String.t()], opts) :: response
  def get_playlists(ids, opts \\ []) when is_list(ids) do
    ids_str = Enum.join(Enum.take(ids, 100), ",")
    Client.get("/v1/catalog/{storefront}/playlists", Keyword.put(opts, :ids, ids_str))
  end

  @doc """
  List all genres available in the catalog.

  ## Parameters

    - `opts`: Optional `:storefront` override
  """
  @spec list_genres(opts) :: response
  def list_genres(opts \\ []) do
    Client.get("/v1/catalog/{storefront}/genres", opts)
  end

  @doc """
  Get charts for a specific type (songs, albums, playlists).

  ## Parameters

    - `opts`:
      - `:types` - List of types to get charts for ["songs", "albums", "playlists"]
      - `:storefront` - Storefront code
      - `:chart` - Chart ID (optional)

  ## Examples

      AppleMusicAPI.get_charts(types: ["songs", "albums"])
  """
  @spec get_charts(opts) :: response
  def get_charts(opts \\ []) do
    types = Keyword.get(opts, :types, ["songs"])
    types_str = Enum.join(types, ",")
    Client.get("/v1/catalog/{storefront}/charts", Keyword.put(opts, :types, types_str))
  end

  @doc """
  Get the user's library playlists (requires user token).

  ## Parameters

    - `opts`:
      - `:user_token` - User MusicKit token (required)
      - `:limit` - Maximum results (default 25)
      - `:offset` - Pagination offset
  """
  @spec get_user_playlists(opts) :: response
  def get_user_playlists(opts \\ []) do
    Client.get("/v1/me/library/playlists", opts)
  end

  @doc """
  Get tracks from the user's library playlist (requires user token).

  ## Parameters

    - `playlist_id`: Library playlist ID
    - `opts`:
      - `:user_token` - User MusicKit token (required)
      - `:limit` - Maximum results (default 25)
  """
  @spec get_user_playlist_tracks(String.t(), opts) :: response
  def get_user_playlist_tracks(playlist_id, opts \\ []) when is_binary(playlist_id) do
    Client.get("/v1/me/library/playlists/#{playlist_id}/tracks", opts)
  end

  @doc """
  Get the user's library songs (requires user token).

  ## Parameters

    - `opts`:
      - `:user_token` - User MusicKit token (required)
      - `:limit` - Maximum results (default 25)
      - `:offset` - Pagination offset
  """
  @spec get_user_songs(opts) :: response
  def get_user_songs(opts \\ []) do
    Client.get("/v1/me/library/songs", opts)
  end

  @doc """
  Get the user's library albums (requires user token).

  ## Parameters

    - `opts`:
      - `:user_token` - User MusicKit token (required)
      - `:limit` - Maximum results (default 25)
      - `:offset` - Pagination offset
  """
  @spec get_user_albums(opts) :: response
  def get_user_albums(opts \\ []) do
    Client.get("/v1/me/library/albums", opts)
  end

  @doc """
  Get the user's library artists (requires user token).

  ## Parameters

    - `opts`:
      - `:user_token` - User MusicKit token (required)
      - `:limit` - Maximum results (default 25)
      - `:offset` - Pagination offset
  """
  @spec get_user_artists(opts) :: response
  def get_user_artists(opts \\ []) do
    Client.get("/v1/me/library/artists", opts)
  end

  @doc """
  Get recommendations for the user (requires user token).

  ## Parameters

    - `opts`:
      - `:user_token` - User MusicKit token (required)
      - `:limit` - Maximum results (default 10)
  """
  @spec get_recommendations(opts) :: response
  def get_recommendations(opts \\ []) do
    Client.get("/v1/me/recommendations", opts)
  end

  @doc """
  Add a resource to the user's library (requires user token).

  ## Parameters

    - `ids`: Map of type to list of IDs, e.g., `%{songs: ["123"], albums: ["456"]}`
    - `opts`:
      - `:user_token` - User MusicKit token (required)

  ## Examples

      AppleMusicAPI.add_to_library(%{songs: ["123456789"]})
  """
  @spec add_to_library(map(), opts) :: :ok | {:error, term()}
  def add_to_library(ids, opts \\ []) when is_map(ids) do
    params =
      ids
      |> Enum.flat_map(fn {type, type_ids} ->
        Enum.map(type_ids, fn id -> {"ids[#{type}]", id} end)
      end)
      |> Enum.into(%{})

    case Client.post("/v1/me/library", %{}, Keyword.merge(opts, params: params)) do
      {:ok, _} -> :ok
      error -> error
    end
  end
end
