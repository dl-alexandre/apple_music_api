defmodule AppleMusicAPI.ClientTest do
  use ExUnit.Case, async: true

  alias AppleMusicAPI.{Client, Error, TestKey}

  setup do
    bypass = Bypass.open()

    opts = [
      team_id: "T",
      key_id: "K",
      private_key: TestKey.pem(),
      base_url: "http://localhost:#{bypass.port}",
      storefront: "us"
    ]

    %{bypass: bypass, opts: opts}
  end

  test "get/2 sends authorization header and returns body", %{bypass: bypass, opts: opts} do
    Bypass.expect_once(bypass, "GET", "/v1/catalog/us/songs/123", fn conn ->
      assert [auth_header] = Plug.Conn.get_req_header(conn, "authorization")
      assert String.starts_with?(auth_header, "Bearer ")

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        Jason.encode!(%{
          "data" => [
            %{"id" => "123", "type" => "songs", "attributes" => %{"name" => "Test Song"}}
          ]
        })
      )
    end)

    assert {:ok, %{"data" => _}} =
             Client.get("/v1/catalog/{storefront}/songs/123", opts)
  end

  test "get/2 includes music-user-token for library access", %{bypass: bypass, opts: opts} do
    Bypass.expect_once(bypass, "GET", "/v1/me/library/songs", fn conn ->
      assert ["user_token_123"] = Plug.Conn.get_req_header(conn, "music-user-token")
      assert [_auth] = Plug.Conn.get_req_header(conn, "authorization")

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"data" => []}))
    end)

    opts_with_user = Keyword.put(opts, :user_token, "user_token_123")

    assert {:ok, %{"data" => []}} =
             Client.get("/v1/me/library/songs", opts_with_user)
  end

  test "get/2 maps non-2xx to Error struct", %{bypass: bypass, opts: opts} do
    Bypass.expect_once(bypass, "GET", "/v1/catalog/us/songs/invalid", fn conn ->
      Plug.Conn.resp(conn, 404, Jason.encode!(%{"errors" => [%{"detail" => "Not found"}]}))
    end)

    assert {:error, %Error{status: 404}} =
             Client.get("/v1/catalog/{storefront}/songs/invalid", opts)
  end

  test "get/2 maps transport failure", %{bypass: bypass, opts: opts} do
    Bypass.down(bypass)

    no_retry = Keyword.put(opts, :req_options, retry: false)

    assert {:error, _reason} =
             Client.get("/v1/catalog/{storefront}/songs/123", no_retry)
  end
end
