defmodule BooksAdmin.FormHelpers do
  @moduledoc """
  Functions related to forms which are going to be in use
  in different templates and views.
  """

  def input_classes(f, field) do
    case {is_nil(f.errors[field]), is_nil(f.action)} do
      {false, false} -> "input is-danger"
      {true, true} -> "input is-success"
      {_, _} -> "input"
    end
  end

  def check_classes(f, field) do
    case {is_nil(f.errors[field]), is_nil(f.action)} do
      {false, false} -> "is-danger"
      {true, true} -> "is-success"
      {_, _} -> nil
    end
  end
end
