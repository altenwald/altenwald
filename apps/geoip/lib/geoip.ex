defmodule Geoip do
  use Tesla
  require Logger

  plug(Tesla.Middleware.BaseUrl, "https://ipinfo.io")
  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])
  plug(Tesla.Middleware.JSON)

  @default_country_code "ES"

  defp cfg(:token) do
    Application.get_env(:geoip, :ipinfo_token, "")
  end

  def geoip(ip) when is_binary(ip) do
    case lookup(ip) do
      {:ok, resp} ->
        resp.body["country"]

      error ->
        Logger.error("not found IP #{ip}: #{inspect(error)}")
        @default_country_code
    end
  end

  def lookup(ip) when is_tuple(ip) do
    ip
    |> :inet_parse.ntoa()
    |> to_string()
    |> lookup()
  end

  def lookup(ip) when is_binary(ip) do
    get("/#{ip}", query: %{"token" => cfg(:token)})
  end
end
