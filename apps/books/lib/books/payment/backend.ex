defmodule Books.Payment.Backend do
  @moduledoc false
  defmacro backend(name, args) do
    quote do
      def unquote(name)(provider, unquote_splicing(args)) do
        module = Module.concat([Books.Payment.Provider, String.capitalize(provider)])

        apply(module, unquote(name), [unquote_splicing(args)])
        |> Books.Payment.notify(module)
      end
    end
  end
end
