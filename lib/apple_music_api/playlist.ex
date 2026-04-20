defmodule AppleMusicAPI.Playlist do
  @moduledoc """
  Playlist struct representing a playlist in Apple Music.

  ## Fields

    - `id`: Apple Music playlist ID
    - `type`: Resource type (always "playlists")
    - `href`: API URL for this resource
    - `name`: Playlist name
    - `curator_name`: Name of the curator
    - `description`: Playlist description
    - `track_count`: Number of tracks
    - `artwork_url`: URL to playlist artwork
    - `url`: Apple Music URL for the playlist
    - `is_chart`: Whether this is a chart playlist
    - `genre_names`: List of genres
    - `last_modified_date`: Last modification date
  """

  defstruct [
    :id,
    :type,
    :href,
    :name,
    :curator_name,
    :description,
    :track_count,
    :artwork_url,
    :url,
    :is_chart,
    :genre_names,
    :last_modified_date
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: String.t() | nil,
          href: String.t() | nil,
          name: String.t() | nil,
          curator_name: String.t() | nil,
          description: String.t() | nil,
          track_count: integer() | nil,
          artwork_url: String.t() | nil,
          url: String.t() | nil,
          is_chart: boolean() | nil,
          genre_names: [String.t()] | nil,
          last_modified_date: String.t() | nil
        }

  @doc """
  Decode a playlist resource from the Apple Music API response.
  """
  @spec from_map(map()) :: t()
  def from_map(%{"data" => [first | _]}) do
    from_map(first)
  end

  def from_map(%{"id" => id, "type" => "playlists", "attributes" => attrs}) do
    %__MODULE__{
      id: id,
      type: "playlists",
      href: nil,
      name: attrs["name"],
      curator_name: get_in(attrs, ["curatorName"]),
      description: extract_description(attrs["description"]),
      track_count: get_in(attrs, ["trackCount"]),
      artwork_url: extract_artwork_url(attrs["artwork"]),
      url: attrs["url"],
      is_chart: get_in(attrs, ["isChart"]),
      genre_names: attrs["genreNames"] || [],
      last_modified_date: get_in(attrs, ["lastModifiedDate"])
    }
  end

  def from_map(%{} = data) do
    %__MODULE__{
      id: data["id"],
      type: data["type"],
      href: data["href"],
      name: get_nested(data, ["attributes", "name"]),
      curator_name: get_nested(data, ["attributes", "curatorName"]),
      description: extract_description(get_nested(data, ["attributes", "description"])),
      track_count: get_nested(data, ["attributes", "trackCount"]),
      artwork_url: extract_artwork_url(get_nested(data, ["attributes", "artwork"])),
      url: get_nested(data, ["attributes", "url"]),
      is_chart: get_nested(data, ["attributes", "isChart"]),
      genre_names: get_nested(data, ["attributes", "genreNames"]) || [],
      last_modified_date: get_nested(data, ["attributes", "lastModifiedDate"])
    }
  end

  defp extract_description(nil), do: nil
  defp extract_description(%{"standard" => desc}), do: desc
  defp extract_description(desc) when is_binary(desc), do: desc
  defp extract_description(_), do: nil

  defp extract_artwork_url(nil), do: nil
  defp extract_artwork_url(%{"url" => url}), do: url
  defp extract_artwork_url(_), do: nil

  defp get_nested(data, keys), do: get_nested(data, keys, nil)
  defp get_nested(data, [], default), do: data || default

  defp get_nested(data, [key | rest], default) when is_map(data),
    do: get_nested(data[key], rest, default)

  defp get_nested(_, _, default), do: default
end
