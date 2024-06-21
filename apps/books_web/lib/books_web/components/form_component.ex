defmodule BooksWeb.FormComponent do
  use BooksWeb, :component

  attr :title, :string, required: true

  def submit_form(assigns) do
    ~H"""
    <div class="field">
      <%= submit(@title, class: "button is-primary") %>
    </div>
    """
  end

  attr :name, :atom, required: true
  attr :title, :string, required: true
  attr :form, :any, required: true

  attr :rest, :global,
    default: %{class: "input"},
    include:
      ~w[required data-placeholder data-type data-free-input data-search-on data-selectable data-values]

  slot :help

  def text_input(assigns) do
    ~H"""
    <div class="field">
      <%= label(@form, @name, @title, class: "label") %>
      <%= if help = render_slot(@help) do %>
        <p class="help"><%= help %></p>
      <% end %>
      <div class="control">
        <%= text_input(@form, @name, additional_input_attributes(@rest, class: "input")) %>
      </div>
      <.error_tag form={@form} field={@name} />
    </div>
    """
  end

  attr :name, :atom, required: true
  attr :title, :string, required: true
  attr :form, :any, required: true
  attr :values, :list, required: true
  attr :rest, :global, include: ~w[data-type required prompt multiple]
  slot :help

  def select(assigns) do
    ~H"""
    <div class="field">
      <%= label(@form, @name, @title, class: "label") %>
      <%= if help = render_slot(@help) do %>
        <p class="help"><%= help %></p>
      <% end %>
      <div class="control">
        <%= if @rest[:multiple] do %>
          <div class="select is-multiple">
            <%= multiple_select(@form, @name, @values, additional_select_attributes(@rest, [])) %>
          </div>
        <% else %>
          <div class="select">
            <%= select(@form, @name, @values, additional_select_attributes(@rest, [])) %>
          </div>
        <% end %>
      </div>
      <.error_tag form={@form} field={@name} />
    </div>
    """
  end

  attr :name, :atom, required: true
  attr :title, :string, required: true
  attr :form, :any, required: true

  attr :rest, :global,
    include: ~w[data-placeholder data-free-input data-search-on data-selectable data-values]

  def tags_input(assigns) do
    ~H"""
    <.text_input name={@name} title={@title} form={@form} data-type="tags" {@rest} />
    """
  end

  attr :name, :atom, required: true
  attr :title, :string, required: true
  attr :form, :any, required: true

  attr :rest, :global,
    include: ~w[data-placeholder data-free-input data-search-on data-selectable data-values]

  def tags_select(assigns) do
    ~H"""
    <.select name={@name} title={@title} form={@form} data-type="tags" {@rest} />
    """
  end

  attr :name, :atom, required: true
  attr :title, :string, required: true
  attr :form, :any, required: true
  attr :rest, :global, default: %{class: "input"}
  slot :help

  def date(assigns) do
    ~H"""
    <div class="field">
      <%= label(@form, @name, @title, class: "label") %>
      <%= if help = render_slot(@help) do %>
        <p class="help"><%= help %></p>
      <% end %>
      <div class="control">
        <%= date_input(@form, @name, additional_input_attributes(@rest, class: "input")) %>
      </div>
      <.error_tag form={@form} field={@name} />
    </div>
    """
  end

  attr :name, :atom, required: true
  attr :title, :string, required: true
  attr :form, :any, required: true
  attr :rest, :global, default: %{class: "input"}
  slot :help

  def datetime(assigns) do
    ~H"""
    <div class="field">
      <%= label(@form, @name, @title, class: "label") %>
      <%= if help = render_slot(@help) do %>
        <p class="help"><%= help %></p>
      <% end %>
      <div class="control">
        <%= datetime_local_input(@form, @name, additional_input_attributes(@rest, class: "input")) %>
      </div>
      <.error_tag form={@form} field={@name} />
    </div>
    """
  end

  attr :name, :atom, required: true
  attr :title, :string, required: true
  attr :form, :any, required: true
  attr :rest, :global
  slot :help

  def textarea(assigns) do
    ~H"""
    <div class="field">
      <%= label(@form, @name, @title, class: "label") %>
      <%= if help = render_slot(@help) do %>
        <p class="help"><%= help %></p>
      <% end %>
      <div class="control">
        <%= textarea(@form, @name, additional_input_attributes(@rest, [])) %>
      </div>
      <.error_tag form={@form} field={@name} />
    </div>
    """
  end

  defp additional_input_attributes(assigns, defaults) do
    Enum.reduce(assigns, defaults, fn
      {:required, _}, acc ->
        Keyword.put(acc, :required, true)

      {:class, value}, acc ->
        Keyword.put(acc, :class, value)

      {:value, value}, acc ->
        Keyword.put(acc, :value, value)

      {key, value}, acc ->
        case to_string(key) do
          "data-" <> _ -> Keyword.put(acc, key, value)
          "data_" <> _ -> Keyword.put(acc, key, value)
          _ -> acc
        end
    end)
  end

  defp additional_select_attributes(assigns, defaults) do
    Enum.reduce(assigns, defaults, fn
      {:required, _}, acc ->
        Keyword.put(acc, :required, true)

      {:multiple, _}, acc ->
        Keyword.put(acc, :multiple, true)

      {:prompt, value}, acc ->
        Keyword.put(acc, :prompt, value)

      {:class, value}, acc ->
        Keyword.put(acc, :class, value)

      {key, value}, acc ->
        case to_string(key) do
          "data-" <> _ -> Keyword.put(acc, key, value)
          "data_" <> _ -> Keyword.put(acc, key, value)
          _ -> acc
        end
    end)
  end
end
