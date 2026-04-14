# AppleMusicAPI

Elixir client for the [Apple Music API](https://developer.apple.com/documentation/applemusicapi).

## Installation

Add to your `mix.exs`:

```elixir
defp deps do
  [
    {:apple_music_api, "~> 0.1.0"}
  ]
end
```

## Configuration

Add to your `config/runtime.exs`:

```elixir
config :apple_music_api,
  team_id: System.get_env("APPLE_TEAM_ID"),
  key_id: System.get_env("MUSIC_KEY_ID"),
  private_key: System.get_env("MUSIC_PRIVATE_KEY")
```

Or use a file path for the private key:

```elixir
config :apple_music_api,
  team_id: System.get_env("APPLE_TEAM_ID"),
  key_id: System.get_env("MUSIC_KEY_ID"),
  private_key_path: System.get_env("MUSIC_PRIVATE_KEY_PATH"),
  storefront: "us"
```

### Configuration Options

- `team_id` - Your Apple Developer Team ID (required)
- `key_id` - Your Apple Music API key ID (required)
- `private_key` - The contents of your `.p8` private key file (required if not using `private_key_path`)
- `private_key_path` - Path to your `.p8` private key file (required if not using `private_key`)
- `base_url` - API base URL (defaults to `"https://api.music.apple.com"`)
- `storefront` - Default storefront code (defaults to `"us"`)
- `token_ttl_seconds` - JWT token lifetime in seconds (defaults to 600)

## Usage

### Catalog Search

```elixir
# Search for songs, albums, and artists
{:ok, results} = AppleMusicAPI.search_catalog("The Beatles", types: ["songs", "albums"])

# Search with pagination
{:ok, results} = AppleMusicAPI.search_catalog("rock", types: ["playlists"], limit: 25, offset: 0)
```

### Get Resources by ID

```elixir
# Get a song by ID
{:ok, song} = AppleMusicAPI.get_song("123456789")

# Get an album
{:ok, album} = AppleMusicAPI.get_album("987654321")

# Get an artist
{:ok, artist} = AppleMusicAPI.get_artist("111111111")

# Get a playlist
{:ok, playlist} = AppleMusicAPI.get_playlist("222222222")

# Get multiple songs at once (up to 100)
{:ok, songs} = AppleMusicAPI.get_songs(["id1", "id2", "id3"])
```

### Search by ISRC

```elixir
# Find a song by its International Standard Recording Code
{:ok, songs} = AppleMusicAPI.get_songs_by_isrc("USUG12002836")
```

### Charts and Genres

```elixir
# Get top charts
{:ok, charts} = AppleMusicAPI.get_charts(types: ["songs", "albums"])

# List all genres
{:ok, genres} = AppleMusicAPI.list_genres()
```

### User Library (requires user token)

For user library access, you need a MusicKit user token obtained from an authenticated client:

```elixir
# Get user's playlists
{:ok, playlists} = AppleMusicAPI.get_user_playlists(user_token: user_token)

# Get tracks from a specific library playlist
{:ok, tracks} = AppleMusicAPI.get_user_playlist_tracks("playlist_id", user_token: user_token)

# Get user's songs
{:ok, songs} = AppleMusicAPI.get_user_songs(user_token: user_token)

# Get user's albums
{:ok, albums} = AppleMusicAPI.get_user_albums(user_token: user_token)

# Get user's artists
{:ok, artists} = AppleMusicAPI.get_user_artists(user_token: user_token)
```

### Add to Library

```elixir
# Add songs to user's library
:ok = AppleMusicAPI.add_to_library(%{songs: ["123456789"]}, user_token: user_token)

# Add multiple types
:ok = AppleMusicAPI.add_to_library(
  %{songs: ["123"], albums: ["456"], playlists: ["789"]},
  user_token: user_token
)
```

### Recommendations

```elixir
# Get personalized recommendations (requires user token)
{:ok, recommendations} = AppleMusicAPI.get_recommendations(user_token: user_token)
```

### Per-Call Options

All functions accept per-call options that override the application configuration:

```elixir
{:ok, songs} = AppleMusicAPI.search_catalog("query",
  types: ["songs"],
  storefront: "gb",
  limit: 10
)
```

### Token Access

If you need direct access to the developer token:

```elixir
{:ok, token} = AppleMusicAPI.token()
```

## Data Structures

The API returns maps with the raw Apple Music API response structure. Common response fields:

### Song
- `id` - Apple Music song ID
- `attributes.name` - Song name
- `attributes.artistName` - Primary artist
- `attributes.albumName` - Album name
- `attributes.isrc` - ISRC code
- `attributes.durationInMillis` - Duration in milliseconds
- `attributes.artwork` - Artwork URLs
- `attributes.previews` - Preview URLs

### Album
- `id` - Apple Music album ID
- `attributes.name` - Album name
- `attributes.artistName` - Artist name
- `attributes.trackCount` - Number of tracks
- `attributes.releaseDate` - Release date

### Artist
- `id` - Apple Music artist ID
- `attributes.name` - Artist name
- `attributes.genreNames` - List of genres

### Playlist
- `id` - Apple Music playlist ID
- `attributes.name` - Playlist name
- `attributes.curatorName` - Curator name
- `attributes.description` - Playlist description

## Error Handling

All API functions return `{:ok, result}` or `{:error, reason}`. Errors are returned as `AppleMusicAPI.Error` structs:

```elixir
case AppleMusicAPI.get_song("invalid_id") do
  {:ok, song} -> 
    IO.inspect(song)
  
  {:error, %AppleMusicAPI.Error{status: 404, message: message}} ->
    IO.puts("Song not found: #{message}")
    
  {:error, %AppleMusicAPI.Error{status: 401} = error} ->
    IO.puts("Authentication failed: #{error.message}")
    
  {:error, %AppleMusicAPI.Error{status: 429} = error} ->
    IO.puts("Rate limited: #{error.message}")
end
```

Common HTTP status codes:

- `400` - Bad request
- `401` - Unauthorized (invalid developer token)
- `403` - Forbidden (insufficient permissions or invalid user token)
- `404` - Resource not found
- `429` - Rate limited

## Architecture

The library uses a GenServer-based token cache to minimize JWT signing operations. Tokens are automatically refreshed before expiry with a 60-second buffer. The cache is automatically started when the application starts.

## Live Testing

This workspace includes a shared media integration script that exercises:

- `apple_music_api`
- `apple_music_feed`
- `shazam_kit`

Run it with:

```bash
cd apple_music_api
source .env && elixir test_media_apis.exs
```

Use the per-project `.env` files for the real Apple credentials.

## License

MIT
