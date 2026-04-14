defmodule AppleMusicAPI.Error do
  @moduledoc "Structured error returned from the Apple Music API."

  defexception [:message, :status, :details]

  @type t :: %__MODULE__{
          message: String.t(),
          status: non_neg_integer() | nil,
          details: term()
        }

  @spec from_http(non_neg_integer(), term()) :: t()
  def from_http(status, body) do
    %__MODULE__{
      message: reason_for(status),
      status: status,
      details: body
    }
  end

  defp reason_for(400), do: "bad request — invalid request format or parameters"
  defp reason_for(401), do: "unauthorized — invalid or expired developer token"
  defp reason_for(403), do: "forbidden — insufficient permissions for this resource"
  defp reason_for(404), do: "not found — resource does not exist"
  defp reason_for(429), do: "rate limited by Apple Music API"
  defp reason_for(500), do: "internal server error — Apple Music API server error"
  defp reason_for(_), do: "Apple Music API request failed"
end
