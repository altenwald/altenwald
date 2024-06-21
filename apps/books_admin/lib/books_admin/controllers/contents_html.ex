defmodule BooksAdmin.ContentsHTML do
  use BooksAdmin, :html

  def translate_type("1 preface"), do: gettext("Preface")
  def translate_type("2 intro"), do: gettext("Introduction")
  def translate_type("3 chapter"), do: gettext("Chapter")
  def translate_type("4 appendix"), do: gettext("Appendix")

  def translate_status(:todo), do: gettext("todo")
  def translate_status(:prepared), do: gettext("prepared")
  def translate_status(:reviewed), do: gettext("reviewed")
  def translate_status(:done), do: gettext("done")

  embed_templates("contents_html/*")
end
