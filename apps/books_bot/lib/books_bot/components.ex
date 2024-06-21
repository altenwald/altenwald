defmodule BooksBot.Components do
  import ExGram.Dsl
  alias BooksBot.Action
  alias ExGram.Model.InlineKeyboardButton
  alias ExGram.Model.InlineKeyboardMarkup
  require Logger

  def get_money(amount) do
    case Regex.run(~r/^(-?)([0-9]+)(?:\.([0-9]{1,2}))?$/, amount, capture: :all_but_first) do
      [sign, int | decimal] ->
        decimal =
          case decimal do
            [] ->
              0

            [decimal] when byte_size(decimal) == 1 ->
              String.to_integer(decimal) * 10

            [decimal] when byte_size(decimal) == 2 ->
              String.to_integer(decimal)
          end

        amount = String.to_integer(int) * 100 + decimal
        sign = if(sign == "-", do: -1, else: 1)
        {:ok, amount * sign}

      nil ->
        {:error, :invalid_amount}
    end
  end

  def get_chat_id(context) do
    cond do
      context.update.message ->
        context.update.message.chat.id

      context.update.callback_query ->
        context.update.callback_query.message.chat.id
    end
  end

  def answer_select(context, prompt, options, extra_options \\ [], opts \\ []) do
    extra_buttons =
      for {label, value} <- extra_options do
        %InlineKeyboardButton{text: label, callback_data: value}
      end

    buttons =
      if Enum.all?(options, &is_tuple/1) do
        for {label, value} <- options do
          [%InlineKeyboardButton{text: label, callback_data: value}]
        end
      else
        Enum.map(options, fn
          {label, value} ->
            [%InlineKeyboardButton{text: label, callback_data: value}]

          sub_options when is_list(sub_options) ->
            for {label, value} <- sub_options do
              %InlineKeyboardButton{text: label, callback_data: value}
            end
        end)
      end ++ [extra_buttons]

    markup = %InlineKeyboardMarkup{inline_keyboard: buttons}
    answer(context, prompt, [{:reply_markup, markup} | opts])
  end

  def escape_markdown(text) when is_binary(text) do
    Regex.replace(~r/([_*~`#+=|\{\}!\[\].\-\(\)])/, text, "\\\\\\1", global: true)
  end

  def escape_markdown(text) when is_number(text) or is_atom(text) do
    text
    |> to_string()
    |> escape_markdown()
  end

  def answer_me(context, name, prompt, opts \\ []) do
    Action.put_following_text(name)
    answer(context, prompt, opts)
  end

  def delete_callback(context) do
    delete(context, context.update.callback_query.message)
  end

  def choose_date(context, action) do
    Action.put_following_text(action)

    answer_select(
      context,
      "Write or choose date for the entry (YYYY-MM-DD)",
      [
        {"Today", "#{action} date #{Date.utc_today()}"},
        {"Yesterday", "#{action} date #{Date.add(Date.utc_today(), -1)}"}
      ]
    )
  end

  def currency_fmt(value) do
    value
    |> to_string()
    |> String.pad_leading(15)
    |> escape_markdown()
  end

  def month_year_fmt(month, year) do
    "#{year}/#{String.pad_leading(to_string(month), 2, "0")}"
  end
end
