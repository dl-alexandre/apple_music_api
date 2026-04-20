defmodule AppleMusicAPI.Song do
  @moduledoc """
  Song struct representing a track in Apple Music.

  ## Fields

    - `id`: Apple Music song ID
    - `type`: Resource type (always "songs")
    - `href`: API URL for this resource
    - `name`: Song name
    - `artist_name`: Primary artist name
    - `album_name`: Album name
    - `isrc`: International Standard Recording Code
    - `duration_in_millis`: Duration in milliseconds
    - `track_number`: Track number on the album
    - `disc_number`: Disc number for multi-disc albums
    - `release_date`: Release date (YYYY-MM-DD format)
    - `artwork_url`: URL to album artwork
    - `url`: Apple Music URL for the song
    - `previews`: List of preview URLs
  """

  defstruct [
    :id,
    :type,
    :href,
    :name,
    :artist_name,
    :album_name,
    :isrc,
    :duration_in_millis,
    :track_number,
    :disc_number,
    :release_date,
    :artwork_url,
    :url,
    :previews
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: String.t() | nil,
          href: String.t() | nil,
          name: String.t() | nil,
          artist_name: String.t() | nil,
          album_name: String.t() | nil,
          isrc: String.t() | nil,
          duration_in_millis: integer() | nil,
          track_number: integer() | nil,
          disc_number: integer() | nil,
          release_date: String.t() | nil,
          artwork_url: String.t() | nil,
          url: String.t() | nil,
          previews: [map()] | nil
        }

  @doc """
  Decode a song resource from the Apple Music API response.
  """
  @spec from_map(map()) :: t()
  def from_map(%{"data" => [first | _]}) do
    from_map(first)
  end

  def from_map(%{"id" => id, "type" => "songs", "attributes" => attrs}) do
    %__MODULE__{
      id: id,
      type: "songs",
      href: nil,
      name: attrs["name"],
      artist_name: get_in(attrs, ["artistName"]),
      album_name: get_in(attrs, ["albumName"]),
      isrc: get_in(attrs, ["isrc"]),
      duration_in_millis: get_in(attrs, ["durationInMillis"]),
      track_number: get_in(attrs, ["trackNumber"]),
      disc_number: get_in(attrs, ["discNumber"]),
      release_date: get_in(attrs, ["releaseDate"]),
      artwork_url: extract_artwork_url(attrs["artwork"]),
      url: get_in(attrs, ["url"]),
      previews: attrs["previews"] || []
    }
  end

  def from_map(%{} = data) do
    # Handle data from search results or relationships
    %__MODULE__{
      id: data["id"],
      type: data["type"],
      href: data["href"],
      name: get_nested(data, ["attributes", "name"]),
      artist_name: get_nested(data, ["attributes", "artistName"]),
      album_name: get_nested(data, ["attributes", "albumName"]),
      isrc: get_nested(data, ["attributes", "isrc"]),
      duration_in_millis: get_nested(data, ["attributes", "durationInMillis"]),
      track_number: get_nested(data, ["attributes", "trackNumber"]),
      disc_number: get_nested(data, ["attributes", "discNumber"]),
      release_date: get_nested(data, ["attributes", "releaseDate"]),
      artwork_url: extract_artwork_url(get_nested(data, ["attributes", "artwork"])),
      url: get_nested(data, ["attributes", "url"]),
      previews: get_nested(data, ["attributes", "previews"]) || []
    }
  end

  defp extract_artwork_url(nil), do: nil
  defp extract_artwork_url(%{"url" => url}), do: url
  defp extract_artwork_url(_), do: nil

  defp get_nested(data, keys), do: get_nested(data, keys, nil)
  defp get_nested(data, [], default), do: data || default

  defp get_nested(data, [key | rest], default) when is_map(data),
    do: get_nested(data[key], rest, default)

  defp get_nested(_, _, default), do: default
end
