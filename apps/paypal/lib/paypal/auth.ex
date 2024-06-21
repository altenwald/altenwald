defmodule Paypal.Auth do
  use Tesla
  use GenStateMachine, callback_mode: :state_functions

  require Logger
  import Paypal, only: [cfg: 1]

  plug(Tesla.Middleware.BaseUrl, cfg(:url))

  plug(Tesla.Middleware.Headers, [
    {"content-type", "application/x-www-form-urlencoded"},
    {"accept-language", "en_US"}
  ])

  plug(Tesla.Middleware.BasicAuth,
    username: cfg(:client_id),
    password: cfg(:secret)
  )

  plug(Tesla.Middleware.DecodeJson)

  @time_when_fails 2_500

  def start_link([]) do
    GenStateMachine.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop do
    GenStateMachine.stop(__MODULE__)
  end

  def get_token do
    GenStateMachine.call(__MODULE__, :token)
  end

  @impl GenStateMachine
  def init([]) do
    {:ok, :inactive, "", [{:next_event, :internal, :refresh}]}
  end

  @impl GenStateMachine
  def code_change(_old_vsn, :inactive, [_], _extra) do
    GenStateMachine.cast(self(), :refresh)
    {:ok, :inactive, nil}
  end

  def code_change(_old_vsn, state_name, state_data, _extra) do
    {:ok, state_name, state_data}
  end

  def inactive(_type, :refresh, _token) do
    case auth() do
      {:ok, body} ->
        expires = body["expires_in"]
        Logger.info("expires in #{expires} seconds")
        time_to_expire = :timer.seconds(body["expires_in"])
        action = [{:state_timeout, time_to_expire, :refresh}]
        {:next_state, :active, body["access_token"], action}

      {:error, error} ->
        Logger.error("PayPal couldn't refresh token: #{inspect(error)}")
        {:keep_state_and_data, [{:state_timeout, @time_when_fails, :refresh}]}
    end
  end

  def inactive({:call, _from}, :token, _token) do
    {:keep_state_and_data, [:postpone]}
  end

  def active(:state_timeout, :refresh, _token) do
    {:next_state, :inactive, nil, [{:next_event, :internal, :refresh}]}
  end

  def active({:call, from}, :token, token) do
    {:keep_state_and_data, [{:reply, from, token}]}
  end

  def auth do
    Logger.info("requesting auth for PayPal")
    {:ok, resp} = post("/v1/oauth2/token", "grant_type=client_credentials")
    Logger.debug("resp => #{inspect(resp)}")

    if is_map_key(resp.body, "access_token") do
      Logger.info("granted access to PayPal")
      {:ok, resp.body}
    else
      Logger.error(
        "cannot access to PayPal: #{resp.body["error"]} - " <>
          "#{resp.body["error_description"]}"
      )

      {:error, {resp.body["error"], resp.body["error_description"]}}
    end
  end
end
