defmodule AppleMusicAPI.Album do
  @moduledoc """
  Album struct representing an album in Apple Music.

  ## Fields

    - `id`: Apple Music album ID
    - `type`: Resource type (always "albums")
    - `href`: API URL for this resource
    - `name`: Album name
    - `artist_name`: Primary artist name
    - `artist_id`: Apple Music artist ID
    - `track_count`: Number of tracks
    - `is_single`: Whether this is a single
    - `is_complete`: Whether the album is complete
    - `release_date`: Release date (YYYY-MM-DD format)
    - `record_label`: Record label name
    - `copyright`: Copyright notice
    - `artwork_url`: URL to album artwork
    - `url`: Apple Music URL for the album
    - `genre_names`: List of genres
  """

  defstruct [
    :id,
    :type,
    :href,
    :name,
    :artist_name,
    :artist_id,
    :track_count,
    :is_single,
    :is_complete,
    :release_date,
    :record_label,
    :copyright,
    :artwork_url,
    :url,
    :genre_names
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: String.t() | nil,
          href: String.t() | nil,
          name: String.t() | nil,
          artist_name: String.t() | nil,
          artist_id: String.t() | nil,
          track_count: integer() | nil,
          is_single: boolean() | nil,
          is_complete: boolean() | nil,
          release_date: String.t() | nil,
          record_label: String.t() | nil,
          copyright: String.t() | nil,
          artwork_url: String.t() | nil,
          url: String.t() | nil,
          genre_names: [String.t()] | nil
        }

  @doc """
  Decode an album resource from the Apple Music API response.
  """
  @spec from_map(map()) :: t()
  def from_map(%{"data" => [first | _]}) do
    from_map(first)
  end

  def from_map(%{"id" => id, "type" => "albums", "attributes" => attrs}) do
    %__MODULE__{
      id: id,
      type: "albums",
      href: nil,
      name: attrs["name"],
      artist_name: get_in(attrs, ["artistName"]),
      artist_id: nil,
      track_count: get_in(attrs, ["trackCount"]),
      is_single: get_in(attrs, ["isSingle"]),
      is_complete: get_in(attrs, ["isComplete"]),
      release_date: get_in(attrs, ["releaseDate"]),
      record_label: get_in(attrs, ["recordLabel"]),
      copyright: get_in(attrs, ["copyright"]),
      artwork_url: extract_artwork_url(attrs["artwork"]),
      url: get_in(attrs, ["url"]),
      genre_names: get_in(attrs, ["genreNames"]) || []
    }
  end

  def from_map(%{} = data) do
    %__MODULE__{
      id: data["id"],
      type: data["type"],
      href: data["href"],
      name: get_nested(data, ["attributes", "name"]),
      artist_name: get_nested(data, ["attributes", "artistName"]),
      artist_id: nil,
      track_count: get_nested(data, ["attributes", "trackCount"]),
      is_single: get_nested(data, ["attributes", "isSingle"]),
      is_complete: get_nested(data, ["attributes", "isComplete"]),
      release_date: get_nested(data, ["attributes", "releaseDate"]),
      record_label: get_nested(data, ["attributes", "recordLabel"]),
      copyright: get_nested(data, ["attributes", "copyright"]),
      artwork_url: extract_artwork_url(get_nested(data, ["attributes", "artwork"])),
      url: get_nested(data, ["attributes", "url"]),
      genre_names: get_nested(data, ["attributes", "genreNames"]) || []
    }
  end

  defp extract_artwork_url(nil), do: nil
  defp extract_artwork_url(%{"url" => url}), do: url
  defp extract_artwork_url(_), do: nil

  defp get_nested(nil, _), do: nil
  defp get_nested(data, keys), do: get_nested(data, keys, nil)
  defp get_nested(data, [], default), do: data || default
  defp get_nested(data, [key | rest], default) when is_map(data), do: get_nested(data[key], rest, default)
  defp get_nested(_, _, default), do: default
end
