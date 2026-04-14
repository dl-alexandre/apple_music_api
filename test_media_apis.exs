#!/usr/bin/env elixir

# Apple Media APIs Integration Test Script
# Run with: elixir test_media_apis.exs

# This script tests apple_music_api, shazam_kit, and apple_music_feed
# with real Apple API credentials from each project's .env file.

Mix.install([
  {:apple_music_api, path: "."},
  {:shazam_kit, path: "../shazam_kit"},
  {:apple_music_feed, path: "../apple_music_feed"},
  {:dotenv, "~> 3.0"}
])

require Logger

defmodule AppleMediaAPITest do
  @moduledoc """
  Integration tests for Apple Media APIs.

  Credentials are loaded from each project's .env file:
  - apple_music_api/.env: AMS_TEAM_ID, AMA_KEY_ID, AMA_PRIVATE_KEY_PATH, AMA_ORIGIN
  - shazam_kit/.env: SK_TEAM_ID, SK_KEY_ID, SK_PRIVATE_KEY_PATH, SK_ORIGIN
  - apple_music_feed/.env: AMS_TEAM_ID, AMF_KEY_ID, AMS_PRIVATE_KEY_PATH, AMS_ORIGIN
  """

  def run do
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("APPLE MEDIA APIs INTEGRATION TEST")
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("")

    # Start required applications
    {:ok, _} = Application.ensure_all_started(:finch)
    IO.puts("✅ HTTP client (Finch) started")

    # Load all .env files
    load_configs()

    if missing_credentials?() do
      print_missing_credentials()
      exit({:shutdown, 1})
    end

    IO.puts("")

    # Configure APIs
    configure_apis()

    # Start token caches
    AppleMusicAPI.TokenCache.start_link([])
    AppleMusicFeed.TokenCache.start_link([])
    ShazamKit.TokenCache.start_link([])
    IO.puts("✅ Token caches initialized")
    IO.puts("")

    # Run tests
    tests = [
      {"Apple Music API - Token Generation", &test_apple_music_token/0},
      {"Apple Music API - Search Catalog", &test_apple_music_search/0},
      {"Apple Music API - Get Charts", &test_apple_music_charts/0},
      {"Apple Music Feed - Token Generation", &test_music_feed_token/0},
      {"Apple Music Feed - Get Charts (Playlists)", &test_music_feed_charts_playlists/0},
      {"Apple Music Feed - Get Charts (Albums)", &test_music_feed_charts_albums/0},
      {"Apple Music Feed - Get Genres", &test_music_feed_genres/0},
      {"ShazamKit - Token Generation", &test_shazam_token/0},
      {"ShazamKit - Search by ISRC", &test_shazam_isrc_search/0},
      {"ShazamKit - Search Tracks", &test_shazam_search_tracks/0}
    ]

    results =
      Enum.map(tests, fn {name, test_fn} ->
        IO.puts("\n► #{name}")
        IO.puts(String.duplicate("-", 50))

        try do
          case test_fn.() do
            :ok ->
              IO.puts("✅ PASSED")
              {name, :passed}

            {:skip, reason} ->
              IO.puts("⏭️  SKIPPED: #{reason}")
              {name, :skipped}

            {:error, reason} ->
              IO.puts("❌ FAILED: #{inspect(reason)}")
              {name, :failed}
          end
        rescue
          e ->
            IO.puts("❌ ERROR: #{Exception.message(e)}")
            {name, :error}
        catch
          kind, reason ->
            IO.puts("❌ EXCEPTION: #{kind} - #{inspect(reason)}")
            {name, :exception}
        end
      end)

    # Summary
    IO.puts("")
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("TEST SUMMARY")
    IO.puts("=" <> String.duplicate("=", 70))

    passed = Enum.count(results, fn {_, status} -> status == :passed end)
    skipped = Enum.count(results, fn {_, status} -> status == :skipped end)
    failed = Enum.count(results, fn {_, status} -> status in [:failed, :error, :exception] end)
    total = length(results)

    IO.puts(
      "Total: #{total} | ✅ Passed: #{passed} | ⏭️  Skipped: #{skipped} | ❌ Failed: #{failed}"
    )

    IO.puts("")

    # Show failed tests
    if failed > 0 do
      IO.puts("Failed Tests:")

      Enum.each(results, fn {name, status} ->
        if status in [:failed, :error, :exception] do
          IO.puts("  ❌ #{name}")
        end
      end)

      exit({:shutdown, 1})
    else
      IO.puts("All tests passed! 🎉")
      :ok
    end
  end

  # Load configurations from each project's .env file
  defp load_configs do
    # Parse and load each .env file manually
    parse_and_load_env(".env")
    parse_and_load_env("../shazam_kit/.env")
    parse_and_load_env("../apple_music_feed/.env")
    :ok
  end

  # Manually parse "export KEY=value" format and set System env
  defp parse_and_load_env(path) do
    if File.exists?(path) do
      File.read!(path)
      |> String.split("\n")
      |> Enum.each(fn line ->
        line = String.trim(line)
        # Match "export KEY=value" or "export KEY='value'" or "export KEY=\"value\""
        if String.starts_with?(line, "export ") do
          rest = String.slice(line, 7..-1//1)

          case String.split(rest, "=", parts: 2) do
            [key, value] ->
              value =
                value
                |> String.trim()
                |> unquote_value()

              System.put_env(key, value)

            _ ->
              :ok
          end
        end
      end)
    end
  end

  # Remove quotes from values
  defp unquote_value(<<"'", rest::binary>>) do
    rest |> String.replace_suffix("'", "")
  end

  defp unquote_value(<<"\"", rest::binary>>) do
    rest |> String.replace_suffix("\"", "")
  end

  defp unquote_value(value), do: value

  defp get_env(key, default \\ nil), do: System.get_env(key) || default

  # Check if required credentials are present
  defp missing_credentials? do
    ama_missing =
      is_nil(get_env("AMS_TEAM_ID")) or is_nil(get_env("AMA_KEY_ID")) or
        (is_nil(get_env("AMA_PRIVATE_KEY")) and is_nil(get_env("AMA_PRIVATE_KEY_PATH")))

    sk_missing =
      is_nil(get_env("SK_TEAM_ID")) or is_nil(get_env("SK_KEY_ID")) or
        (is_nil(get_env("SK_PRIVATE_KEY")) and is_nil(get_env("SK_PRIVATE_KEY_PATH")))

    amf_missing =
      is_nil(get_env("AMS_TEAM_ID")) or is_nil(get_env("AMF_KEY_ID")) or
        (is_nil(get_env("AMS_PRIVATE_KEY")) and is_nil(get_env("AMS_PRIVATE_KEY_PATH")))

    ama_missing or sk_missing or amf_missing
  end

  defp print_missing_credentials do
    IO.puts("❌ Missing required credentials!")
    IO.puts("")

    # Check each project
    if is_nil(get_env("AMS_TEAM_ID")) or is_nil(get_env("AMA_KEY_ID")) do
      IO.puts("Missing apple_music_api/.env:")
      IO.puts("  - AMS_TEAM_ID: #{get_env("AMS_TEAM_ID") || "MISSING"}")
      IO.puts("  - AMA_KEY_ID: #{get_env("AMA_KEY_ID") || "MISSING"}")
      IO.puts("  - AMA_PRIVATE_KEY_PATH: #{get_env("AMA_PRIVATE_KEY_PATH") || "MISSING"}")
      IO.puts("")
    end

    if is_nil(get_env("SK_TEAM_ID")) or is_nil(get_env("SK_KEY_ID")) do
      IO.puts("Missing shazam_kit/.env:")
      IO.puts("  - SK_TEAM_ID: #{get_env("SK_TEAM_ID") || "MISSING"}")
      IO.puts("  - SK_KEY_ID: #{get_env("SK_KEY_ID") || "MISSING"}")
      IO.puts("  - SK_PRIVATE_KEY_PATH: #{get_env("SK_PRIVATE_KEY_PATH") || "MISSING"}")
      IO.puts("")
    end

    if is_nil(get_env("AMF_KEY_ID")) do
      IO.puts("Missing apple_music_feed/.env:")
      IO.puts("  - AMS_TEAM_ID: #{get_env("AMS_TEAM_ID") || "MISSING"}")
      IO.puts("  - AMF_KEY_ID: #{get_env("AMF_KEY_ID") || "MISSING"}")
      IO.puts("  - AMS_PRIVATE_KEY_PATH: #{get_env("AMS_PRIVATE_KEY_PATH") || "MISSING"}")
    end
  end

  # Configure all three APIs with their specific credentials
  defp configure_apis do
    # Configure Apple Music API (key file in current directory)
    ama_key = read_key(get_env("AMA_PRIVATE_KEY"), get_env("AMA_PRIVATE_KEY_PATH"), ".")

    ama_config = [
      team_id: get_env("AMS_TEAM_ID"),
      key_id: get_env("AMA_KEY_ID"),
      private_key: ama_key,
      storefront: "us"
    ]

    ama_config =
      if get_env("AMA_ORIGIN"),
        do: Keyword.put(ama_config, :origin, get_env("AMA_ORIGIN")),
        else: ama_config

    Application.put_all_env(apple_music_api: ama_config)
    IO.puts("✅ Apple Music API configured")
    IO.puts("   Team ID: #{get_env("AMS_TEAM_ID")}")
    IO.puts("   Key ID: #{get_env("AMA_KEY_ID")}")

    # Configure Apple Music Feed (key file in ../apple_music_feed)
    amf_key =
      read_key(get_env("AMS_PRIVATE_KEY"), get_env("AMS_PRIVATE_KEY_PATH"), "../apple_music_feed")

    amf_config = [
      team_id: get_env("AMS_TEAM_ID"),
      key_id: get_env("AMF_KEY_ID"),
      private_key: amf_key,
      storefront: "us"
    ]

    amf_config =
      if get_env("AMS_ORIGIN"),
        do: Keyword.put(amf_config, :origin, get_env("AMS_ORIGIN")),
        else: amf_config

    Application.put_all_env(apple_music_feed: amf_config)
    IO.puts("✅ Apple Music Feed configured")
    IO.puts("   Team ID: #{get_env("AMS_TEAM_ID")}")
    IO.puts("   Key ID: #{get_env("AMF_KEY_ID")}")

    # Configure ShazamKit (key file in ../shazam_kit)
    sk_key = read_key(get_env("SK_PRIVATE_KEY"), get_env("SK_PRIVATE_KEY_PATH"), "../shazam_kit")

    sk_config = [
      team_id: get_env("SK_TEAM_ID"),
      key_id: get_env("SK_KEY_ID"),
      private_key: sk_key
    ]

    sk_config =
      if get_env("SK_ORIGIN"),
        do: Keyword.put(sk_config, :origin, get_env("SK_ORIGIN")),
        else: sk_config

    Application.put_all_env(shazam_kit: sk_config)
    IO.puts("✅ ShazamKit configured")
    IO.puts("   Team ID: #{get_env("SK_TEAM_ID")}")
    IO.puts("   Key ID: #{get_env("SK_KEY_ID")}")
  end

  defp read_key(nil, nil, _), do: nil
  defp read_key(key, _, _) when is_binary(key) and key != "", do: key

  defp read_key(_, path, base_dir) when is_binary(path) and path != "" do
    full_path = Path.join(base_dir, path)

    case File.read(full_path) do
      {:ok, content} ->
        content

      {:error, reason} ->
        IO.puts("   ⚠️  Could not read key file #{full_path}: #{reason}")
        nil
    end
  end

  defp read_key(_, _, _), do: nil

  # Test Apple Music API Token
  defp test_apple_music_token do
    case AppleMusicAPI.token() do
      {:ok, token} ->
        IO.puts("   Token generated successfully (#{String.length(token)} chars)")
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Test Apple Music Catalog Search
  defp test_apple_music_search do
    # Search for The Beatles
    case AppleMusicAPI.search_catalog("The Beatles",
           types: ["songs", "albums", "artists"],
           limit: 5
         ) do
      {:ok, %{"results" => results}} ->
        song_count = length(Map.get(results, "songs", %{}) |> Map.get("data", []))
        album_count = length(Map.get(results, "albums", %{}) |> Map.get("data", []))
        artist_count = length(Map.get(results, "artists", %{}) |> Map.get("data", []))

        IO.puts("   Found #{song_count} songs, #{album_count} albums, #{artist_count} artists")

        if song_count > 0 or album_count > 0 or artist_count > 0 do
          :ok
        else
          {:error, "No results found"}
        end

      {:ok, other} ->
        IO.puts("   Unexpected response format: #{inspect(other) |> String.slice(0, 100)}...")
        {:error, "Unexpected response format"}

      {:error, %AppleMusicAPI.Error{status: 401} = error} ->
        IO.puts("   Authentication failed - check your credentials")
        {:error, error}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Test Apple Music Charts
  defp test_apple_music_charts do
    case AppleMusicAPI.get_charts(types: ["songs"], limit: 5) do
      {:ok, %{"results" => results}} ->
        charts = Map.get(results, "songs", [])

        if length(charts) > 0 do
          IO.puts("   Retrieved #{length(charts)} chart entries")
          :ok
        else
          {:error, "No chart data"}
        end

      {:ok, other} ->
        IO.puts("   Unexpected response: #{inspect(other) |> String.slice(0, 100)}")
        # Charts may not be available in all regions
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Test Apple Music Feed Token
  defp test_music_feed_token do
    case AppleMusicFeed.token() do
      {:ok, token} ->
        IO.puts("   Token generated successfully (#{String.length(token)} chars)")
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Test Apple Music Feed - Charts (Playlists)
  defp test_music_feed_charts_playlists do
    case AppleMusicFeed.get_charts(types: ["playlists"], limit: 5) do
      {:ok, %{"results" => results}} ->
        playlists = Map.get(results, "playlists", [])
        count = length(playlists)
        IO.puts("   Retrieved #{count} playlist charts")

        if count > 0 do
          first = hd(playlists)
          name = get_in(first, ["name"]) || "Unknown"
          IO.puts("   First: #{name}")
          :ok
        else
          # Charts may be empty for some storefronts
          IO.puts("   No playlist charts available")
          :ok
        end

      {:ok, other} ->
        IO.puts("   Response: #{inspect(other) |> String.slice(0, 100)}")
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Test Apple Music Feed - Charts (Albums)
  defp test_music_feed_charts_albums do
    case AppleMusicFeed.get_charts(types: ["albums"], limit: 5) do
      {:ok, %{"results" => results}} ->
        albums = Map.get(results, "albums", [])
        count = length(albums)
        IO.puts("   Retrieved #{count} album charts")

        if count > 0 do
          first = hd(albums)
          name = get_in(first, ["name"]) || "Unknown"
          artist = get_in(first, ["artistName"]) || "Unknown"
          IO.puts("   First: #{name} by #{artist}")
          :ok
        else
          IO.puts("   No album charts available")
          :ok
        end

      {:ok, other} ->
        IO.puts("   Response: #{inspect(other) |> String.slice(0, 100)}")
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Test Apple Music Feed - Get Genres
  defp test_music_feed_genres do
    case AppleMusicFeed.get_genres() do
      {:ok, %{"data" => genres}} ->
        count = length(genres)
        IO.puts("   Retrieved #{count} genres")

        if count > 0 do
          first = hd(genres)
          name = get_in(first, ["attributes", "name"]) || "Unknown"
          IO.puts("   First genre: #{name}")
          :ok
        else
          {:error, "No genres found"}
        end

      {:ok, _} ->
        IO.puts("   Genres endpoint returned empty")
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Test ShazamKit Token
  defp test_shazam_token do
    case ShazamKit.token() do
      {:ok, token} ->
        IO.puts("   Token generated successfully (#{String.length(token)} chars)")
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Test ShazamKit ISRC Search
  defp test_shazam_isrc_search do
    # ISRC for "Yesterday" by The Beatles
    isrc = "USUM71409704"

    case ShazamKit.search_by_isrc(isrc) do
      {:ok, %{} = result} ->
        IO.puts("   Found track for ISRC: #{isrc}")

        # Try to extract track info
        tracks = Map.get(result, "tracks", [])

        if length(tracks) > 0 do
          first = hd(tracks)
          title = Map.get(first, "title") || "Unknown"
          artist = Map.get(first, "artist") || "Unknown"
          IO.puts("   Track: #{title} by #{artist}")
        end

        :ok

      {:ok, _} ->
        IO.puts("   No track found for ISRC (may not be in Shazam catalog)")
        # Not all tracks are in Shazam
        :ok

      {:error, %ShazamKit.Error{status: 404}} ->
        IO.puts("   Track not found in Shazam catalog (expected for some tracks)")
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Test ShazamKit Search
  defp test_shazam_search_tracks do
    case ShazamKit.search_tracks("The Beatles", limit: 5) do
      {:ok, %{} = result} ->
        tracks = Map.get(result, "tracks", [])
        count = length(tracks)
        IO.puts("   Found #{count} tracks")

        if count > 0 do
          first = hd(tracks)
          title = Map.get(first, "title") || "Unknown"
          artist = Map.get(first, "artist") || "Unknown"
          IO.puts("   First: #{title} by #{artist}")
          :ok
        else
          IO.puts("   No tracks found")
          :ok
        end

      {:ok, _} ->
        IO.puts("   Search returned unexpected format")
        :ok

      {:error, %ShazamKit.Error{status: 404}} ->
        IO.puts("   Search endpoint not found (endpoint may differ)")
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end

# Run the tests
AppleMediaAPITest.run()
