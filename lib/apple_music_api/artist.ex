defmodule AppleMusicAPI.Artist do
  @moduledoc """
  Artist struct representing an artist in Apple Music.

  ## Fields

    - `id`: Apple Music artist ID
    - `type`: Resource type (always "artists")
    - `href`: API URL for this resource
    - `name`: Artist name
    - `genre_names`: List of genres
    - `artwork_url`: URL to artist artwork
    - `url`: Apple Music URL for the artist
  """

  defstruct [
    :id,
    :type,
    :href,
    :name,
    :genre_names,
    :artwork_url,
    :url
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          type: String.t() | nil,
          href: String.t() | nil,
          name: String.t() | nil,
          genre_names: [String.t()] | nil,
          artwork_url: String.t() | nil,
          url: String.t() | nil
        }

  @doc """
  Decode an artist resource from the Apple Music API response.
  """
  @spec from_map(map()) :: t()
  def from_map(%{"data" => [first | _]}) do
    from_map(first)
  end

  def from_map(%{"id" => id, "type" => "artists", "attributes" => attrs}) do
    %__MODULE__{
      id: id,
      type: "artists",
      href: nil,
      name: attrs["name"],
      genre_names: attrs["genreNames"] || [],
      artwork_url: extract_artwork_url(attrs["artwork"]),
      url: attrs["url"]
    }
  end

  def from_map(%{} = data) do
    %__MODULE__{
      id: data["id"],
      type: data["type"],
      href: data["href"],
      name: get_nested(data, ["attributes", "name"]),
      genre_names: get_nested(data, ["attributes", "genreNames"]) || [],
      artwork_url: extract_artwork_url(get_nested(data, ["attributes", "artwork"])),
      url: get_nested(data, ["attributes", "url"])
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
