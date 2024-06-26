defmodule BooksBot.Action do
  use ExGram.Bot, name: :books_bot, setup_commands: true
  import BooksBot.Components
  require Logger
  alias BooksBot.Action.Users

  defmacro __using__(_opts) do
    quote do
      import ExGram.Dsl
      import BooksBot.Components, except: [answer_me: 3, answer_me: 4]

      import BooksBot.Action,
        only: [
          put_following_text: 1,
          take_following_text: 0
        ]

      @behaviour BooksBot.Action

      def name do
        Macro.underscore(__MODULE__) |> String.split("/") |> List.last()
      end

      def answer_me(context, prompt, opts \\ []) do
        BooksBot.Components.answer_me(context, name(), prompt, opts)
      end
    end
  end

  @type event() ::
          :init
          | {:event_sticky, String.t()}
          | {:event, String.t()}
          | {:callback, String.t()}
          | {:text, String.t()}

  @callback handle(event(), ExGram.Cnt.t()) :: ExGram.Cnt.t()

  def handle({:command, command, params}, context) do
    if Users.granted_user?(params.from.username) do
      handle(:init, to_string(command), context)
    else
      answer(context, "You're not allowed to ask me anything. Sorry.")
    end
  end

  def handle({:callback_query, %{data: "event sticky " <> data}}, context) do
    [name, data] = String.split(data, " ", parts: 2)
    handle({:event_sticky, data}, name, context)
  end

  def handle({:callback_query, %{data: "event " <> data}}, context) do
    [name, data] = String.split(data, " ", parts: 2)
    handle({:event, data}, name, context)
  end

  def handle({:callback_query, %{data: data}}, context) do
    [name, data] = String.split(data, " ", parts: 2)
    handle({:callback, data}, name, context)
  end

  def handle({:text, text, _metadata}, context) do
    following = take_following_text()

    cond do
      is_nil(following) ->
        Logger.debug("ignored text: #{text}")
        Logger.debug("context: #{inspect(context)}")

      is_binary(following) ->
        handle({:text, text}, following, context)
    end
  end

  def handle({:info, {:send, text, opts}}, context) when is_binary(text) do
    Logger.debug("sending: #{inspect(text)}")
    Logger.debug("context: #{inspect(context)}")
    broadcast(text, opts)
    context
  end

  def handle(request, context) do
    Logger.notice("received: #{inspect(request)}")
    context
  end

  defp handle(event, following, context) do
    module = Module.concat(__MODULE__, Macro.camelize(following))
    Code.ensure_loaded(module)
    Logger.debug("requested command #{inspect(following)} - trying #{module}")

    if function_exported?(module, :handle, 2) do
      module.handle(event, context)
    else
      answer(context, "Command not found. Sorry.")
    end
  end

  defp broadcast(message, opts) do
    Application.get_env(:books_bot, :group_chat_ids)
    |> Enum.map(&ExGram.send_message(&1, message, opts))
  end

  def put_following_text(action) do
    :persistent_term.put({__MODULE__, :following_text}, action)
  end

  def take_following_text do
    key = {__MODULE__, :following_text}

    if following = :persistent_term.get(key, nil) do
      :persistent_term.erase(key)
      following
    end
  end
end
