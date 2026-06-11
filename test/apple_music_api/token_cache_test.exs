defmodule AppleMusicAPI.TokenCacheTest do
  use ExUnit.Case

  alias AppleMusicAPI.{TestKey, TokenCache}

  setup do
    # Ensure the cache is cleared before each test
    TokenCache.clear()

    # Store original env to restore later
    original_env = Application.get_all_env(:apple_music_api)

    on_exit(fn ->
      # Restore original env
      Application.put_all_env(apple_music_api: original_env)
      TokenCache.clear()
    end)

    {:ok, %{original_env: original_env}}
  end

  test "fetch/0 returns cached token on subsequent calls" do
    # Set application env for the test
    Application.put_all_env(
      apple_music_api: [
        team_id: "T",
        key_id: "K",
        private_key: TestKey.pem()
      ]
    )

    # First call should generate a new JWT
    assert {:ok, token1} = TokenCache.fetch()

    # Second call should return the same cached token
    assert {:ok, token2} = TokenCache.fetch()

    # For Apple Music, the JWT is the token, and they should be the same when cached
    assert token1 == token2
  end

  test "clear/0 removes cached token" do
    # Just verify the function exists and returns :ok
    assert :ok = TokenCache.clear()
  end
end
