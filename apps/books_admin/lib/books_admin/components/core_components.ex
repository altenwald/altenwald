defmodule BooksAdmin.CoreComponents do
  @moduledoc """
  Provides core UI components.

  At the first glance, this module may seem daunting, but its goal is
  to provide some core building blocks in your application, such modals,
  tables, and forms. The components are mostly markup and well documented
  with doc strings and declarative assigns. You may customize and style
  them in any way you want, based on your application growth and needs.

  The default components use Tailwind CSS, a utility-first CSS framework.
  See the [Tailwind CSS documentation](https://tailwindcss.com) to learn
  how to customize them or feel free to swap in another framework altogether.

  Icons are provided by [heroicons](https://heroicons.com). See `icon/1` for usage.
  """
  use Phoenix.Component

  import BooksAdmin.Gettext

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} return_to={Routes.catalog_path(@conn, :index)}>
        <.text_input name={:email} label={gettext("Name")} help={gettext("Provide the name")}/>
      </.simple_form>
  """
  attr(:for, :any, required: true, doc: "the datastructure for the form")
  attr(:return_to, :string, required: true)
  attr(:submit, :string, default: gettext("Save"))
  attr(:cancel, :string, default: gettext("Cancel"))

  attr(:rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"
  )

  slot(:inner_block, required: true)

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} class="form" {@rest}>
      <%= render_slot(@inner_block, f) %>
      <hr/>
        <p class="help">(*) <%= gettext("required") %></p>
      <hr/>
      <div class="field is-grouped">
        <p class="control">
          <%= Phoenix.HTML.Form.submit @submit, class: "button is-primary" %>
        </p>
        <p class="control">
          <%= Phoenix.HTML.Link.link @cancel, to: @return_to, class: "button" %>
        </p>
      </div>
    </.form>
    """
  end

  @doc """
  Generates a generic error message.
  """
  ## TODO change :any to the form struct
  attr(:form, :any, required: true)
  attr(:field, :atom, required: true)

  def error_tag(assigns) do
    ~H"""
    <p :for={error <- get_errors(@form, @field)} class="help is-danger">
      <%= translate_error(error) %>
    </p>
    """
  end

  defp get_errors(form, field) do
    Keyword.get_values(form.errors, field)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    # When using gettext, we typically pass the strings we want
    # to translate as a static argument:
    #
    #     # Translate the number of files with plural rules
    #     dngettext("errors", "1 file", "%{count} files", count)
    #
    # However the error messages in our forms and APIs are generated
    # dynamically, so we need to translate them by calling Gettext
    # with our gettext backend as first argument. Translations are
    # available in the errors.po file (as we use the "errors" domain).
    if count = opts[:count] do
      Gettext.dngettext(BooksAdmin.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(BooksAdmin.Gettext, "errors", msg, opts)
    end
  end

  @doc """
  Translates the errors for a field from a keyword list of errors.
  """
  def translate_errors(errors, field) when is_list(errors) do
    for {^field, {msg, opts}} <- errors, do: translate_error({msg, opts})
  end

  attr(:form, :any, required: true)
  attr(:name, :atom, required: true)
  attr(:help, :string)

  def help(assigns) do
    ~H"""
    <p :if={get_errors(@form, @name) != [] or assigns[:help] != nil} class="help">
      <.error_tag form={@form} field={@name}/>
      <%= if assigns[:help] do %>
      <%= @help %>
      <% end %>
    </p>
    """
  end

  attr(:form, :any, required: true)
  attr(:label, :string, required: true)
  attr(:name, :atom, required: true)
  attr(:help, :string)

  def checkbox(assigns) do
    ~H"""
    <div class="field">
      <label class="label"><%= @label %></label>
      <div class="control">
        <label class={"switch is-rounded#{if(@form.errors[@name], do: " is-danger")}"}>
          <%= Phoenix.HTML.Form.checkbox @form, @name %>
          <span class="check"></span>
          <span class="control-label"></span>
        </label>
      </div>
      <.help form={@form} name={@name} help={assigns[:help]}/>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:help, :string)

  def checkbox_enabled(assigns) do
    ~H"""
    <div class="field">
      <label class="label"><%= gettext("Enabled?") %></label>
      <div class="control">
        <label class={"switch is-rounded#{if(@form.errors[:enabled], do: " is-danger")}"}>
          <%= Phoenix.HTML.Form.checkbox @form, :enabled %>
          <span class="check"></span>
          <span class="control-label"></span>
        </label>
      </div>
      <.help form={@form} name={:enabled} help={assigns[:help]}/>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:label, :string, required: true)
  attr(:name, :atom, required: true)
  attr(:required, :boolean, default: false)
  attr(:help, :string)

  def text_input(assigns) do
    ~H"""
    <div class="field">
      <label class="label"><%= @label %><%= if @required, do: " (*)" %></label>
      <div class="control">
        <%= Phoenix.HTML.Form.text_input @form, @name, class: "input#{if(@form.errors[@name], do: " is-danger")}" %>
      </div>
      <.help form={@form} name={@name} help={assigns[:help]}/>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:label, :string, required: true)
  attr(:name, :atom, required: true)
  attr(:required, :boolean, default: false)
  attr(:help, :string)

  def date_input(assigns) do
    ~H"""
    <div class="field">
      <label class="label"><%= @label %><%= if @required, do: " (*)" %></label>
      <div class="control">
        <%= Phoenix.HTML.Form.date_input @form, @name, class: "input#{if(@form.errors[@name], do: " is-danger")}" %>
      </div>
      <.help form={@form} name={@name} help={assigns[:help]}/>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:label, :string, required: true)
  attr(:name, :atom, required: true)
  attr(:required, :boolean, default: false)
  attr(:help, :string)

  def tags_input(assigns) do
    ~H"""
    <div class="field">
      <label class="label"><%= @label %><%= if @required, do: " (*)" %></label>
      <div class="control">
        <%= Phoenix.HTML.Form.text_input @form, @name, class: "input#{if(@form.errors[@name], do: " is-danger")}", data_type: "tags", data_selectable: "true", data_free_input: "true", data_search_on: "text" %>
      </div>
      <.help form={@form} name={@name} help={assigns[:help]}/>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:label, :string, required: true)
  attr(:name, :atom, required: true)
  attr(:required, :boolean, default: false)
  attr(:help, :string)

  def number_input(assigns) do
    ~H"""
    <div class="field">
      <label class="label"><%= @label %><%= if @required, do: " (*)" %></label>
      <div class="control">
        <%= Phoenix.HTML.Form.number_input @form, @name, class: "input#{if(@form.errors[@name], do: " is-danger")}" %>
      </div>
      <.help form={@form} name={@name} help={assigns[:help]}/>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:label, :string, required: true)
  attr(:required, :boolean, default: false)
  attr(:name, :atom, required: true)
  attr(:values, :list, required: true)
  attr(:help, :string)
  attr(:prompt, :string)

  def select(assigns) do
    assigns =
      assigns
      |> assign(extra_params: if(prompt = assigns[:prompt], do: [prompt: prompt], else: []))

    ~H"""
    <div class="field">
      <label class="label"><%= @label %><%= if @required, do: " (*)" %></label>
      <div class="control">
        <div class={"select is-fullwidth#{if(@form.errors[@name], do: " is-danger")}"}>
          <%= Phoenix.HTML.Form.select @form, @name, @values, @extra_params %>
        </div>
      </div>
      <.help form={@form} name={@name} help={assigns[:help]}/>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:label, :string, required: true)
  attr(:required, :boolean, default: false)
  attr(:name, :atom, required: true)
  attr(:help, :string)

  def textarea(assigns) do
    ~H"""
    <div class="field">
      <label class="label"><%= @label %><%= if @required, do: " (*)" %></label>
      <div class="control">
        <%= Phoenix.HTML.Form.textarea @form, @name, class: "textarea#{if(@form.errors[@name], do: " is-danger")}" %>
      </div>
      <.help form={@form} name={@name} help={assigns[:help]}/>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:label, :string, required: true)
  attr(:required, :boolean, default: false)
  attr(:name, :atom, required: true)
  attr(:help, :string)

  def rich_textarea(assigns) do
    ~H"""
    <div class="field">
      <label class="label"><%= @label %><%= if @required, do: " (*)" %></label>
      <div class="control">
        <%= Phoenix.HTML.Form.textarea @form, @name, class: "textarea trumbowyg#{if(@form.errors[@name], do: " is-danger")}" %>
      </div>
      <.help form={@form} name={@name} help={assigns[:help]}/>
    </div>
    """
  end

  attr(:form, :any, required: true)
  attr(:label, :string, required: true)
  attr(:name, :atom, required: true)
  attr(:values, :list, required: true)
  attr(:required, :boolean, default: false)
  attr(:selected, :list)
  attr(:help, :string)

  def multiple_select(assigns) do
    ~H"""
    <div class="field">
      <label class="label"><%= @label %><%= if @required, do: " (*)" %></label>
      <div class="control">
        <div class={"select is-multiple is-fullwidth#{if(@form.errors[@name], do: " is-danger")}"}>
          <%= if assigns[:selected] do %>
          <%= Phoenix.HTML.Form.multiple_select @form, @name, @values, selected: @selected %>
          <% else %>
          <%= Phoenix.HTML.Form.multiple_select @form, @name, @values %>
          <% end %>
        </div>
      </div>
      <.help form={@form} name={@name} help={assigns[:help]}/>
    </div>
    """
  end
end
