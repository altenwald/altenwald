ExUnit.configure(
  exclude: [
    :broken,
    :unimplemented
  ]
)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Books.Repo, :manual)
