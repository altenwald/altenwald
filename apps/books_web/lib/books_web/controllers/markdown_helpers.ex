defmodule BooksWeb.MarkdownHelpers do
  def to_html(text) do
    {_status, html, _messages} =
      Earmark.as_html(text, smartypants: false, gfm_tables: true, footnotes: true, sub_sup: true)

    html
  end

  def to_text(nil), do: nil

  def to_text(binary) do
    binary
    |> String.split("\n")
    |> EarmarkParser.as_ast()
    |> ast_to_text()
  end

  defp ast_to_text({:ok, ast, []}) do
    ast_to_text(ast, [])
    |> Enum.reverse()
    |> Enum.join()
  end

  defp ast_to_text([], text), do: text
  defp ast_to_text(bin, text) when is_binary(bin), do: [bin | text]

  defp ast_to_text({_, _, children, _opts}, text) do
    Enum.reduce(children, text, &ast_to_text/2)
  end

  defp ast_to_text(list, text) when is_list(list) do
    Enum.reduce(list, text, &ast_to_text/2)
  end
end
