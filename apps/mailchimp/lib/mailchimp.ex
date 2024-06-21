defmodule Mailchimp do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://#{cfg(:dc)}.api.mailchimp.com")

  plug(Tesla.Middleware.BasicAuth,
    username: "anystring",
    password: cfg(:api_key)
  )

  plug(Tesla.Middleware.Headers, [{"content-type", "application/json"}])
  plug(Tesla.Middleware.JSON)

  defp cfg(:dc) do
    cfg(:api_key)
    |> String.split("-")
    |> Enum.at(1)
  end

  defp cfg(key) do
    Application.get_env(:mailchimp, key, "")
  end

  def list_lists(query \\ []) do
    get("/3.0/lists", query: query)
  end

  def list_members(list_id, query \\ []) do
    get("/3.0/lists/#{list_id}/members", query: query)
  end

  defp md5(data) do
    :crypto.hash(:md5, data)
  end

  def get_hash(email) do
    email
    |> String.downcase()
    |> md5()
    |> Base.encode16(case: :lower)
  end

  def add_member(list_id \\ nil, data)

  def add_member(nil, data), do: add_member(cfg(:mailling_id), data)

  def add_member(list_id, data) do
    case post("/3.0/lists/#{list_id}/members", data) do
      {:ok, %{body: body}} when is_binary(body) -> {:ok, Jason.decode!(body)}
      {:ok, %{body: body}} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  def add_tags(list_id \\ nil, email, tags)

  def add_tags(nil, email, tags), do: add_tags(cfg(:mailling_id), email, tags)

  def add_tags(list_id, email, tags) do
    email_id = get_hash(email)
    tags = for tag <- tags, do: %{"name" => tag, "status" => "active"}
    data = %{"tags" => tags}

    case post("/3.0/lists/#{list_id}/members/#{email_id}/tags", data) do
      {:ok, %{body: ""}} -> {:ok, %{}}
      {:ok, %{body: body}} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  def get_member(list_id \\ nil, email, fields)

  def get_member(nil, email, fields), do: get_member(cfg(:mailling_id), email, fields)

  def get_member(list_id, email, fields) when is_list(fields) do
    get_member(list_id, email, Enum.join(fields, ","))
  end

  def get_member(list_id, email, fields) when is_binary(fields) do
    email_id = get_hash(email)

    case get("/3.0/lists/#{list_id}/members/#{email_id}", query: [fields: fields]) do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, _reason} = error -> error
    end
  end

  def get_member_permissions(list_id \\ nil, email) do
    case get_member(list_id, email, "marketing_permissions") do
      {:ok, %{"marketing_permissions" => permissions}} -> {:ok, permissions}
      {:error, _reason} = error -> error
    end
  end

  def get_member_tags(list_id \\ nil, email) do
    case get_member(list_id, email, "tags") do
      {:ok, %{"tags" => tags}} -> {:ok, tags}
      {:error, _reason} = error -> error
    end
  end

  def update_member(list_id \\ nil, email, fields)

  def update_member(nil, email, fields), do: update_member(cfg(:mailling_id), email, fields)

  def update_member(list_id, email, fields) do
    email_id = get_hash(email)

    case put("/3.0/lists/#{list_id}/members/#{email_id}", fields) do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, _} = error -> error
    end
  end

  def update_member_permission(list_id \\ nil, email, permission_id, enabled?) do
    permission = %{"marketing_permission_id" => permission_id, "enabled" => enabled?}
    update_member(list_id, email, %{"marketing_permissions" => [permission]})
  end
end
