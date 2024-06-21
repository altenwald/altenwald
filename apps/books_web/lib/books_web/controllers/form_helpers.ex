defmodule BooksWeb.FormHelpers do
  @moduledoc """
  Functions related to forms which are going to be in use
  in different templates and views.
  """

  def input_classes(f, field) do
    if f.errors != [] do
      if f.errors[field] do
        "input is-danger"
      else
        "input is-success"
      end
    else
      "input"
    end
  end

  def check_classes(f, field) do
    if f.errors != [] do
      if f.errors[field] do
        "is-danger"
      else
        "is-success"
      end
    end
  end
end
