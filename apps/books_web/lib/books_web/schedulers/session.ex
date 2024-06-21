defmodule BooksWeb.Schedulers.Session do
  use Cronex.Scheduler
  require Logger

  # 6 hours for sessions
  @max_session_time 3600 * 6

  every :hour do
    clean_sessions()
  end

  def init do
    :ets.new(:session, [:named_table, :public, read_concurrency: true])
  end

  def clean_sessions do
    for {key, _value, {a, b, _}} <- :ets.tab2list(:session) do
      when_expires = a * 1_000_000 + b + @max_session_time
      {a, b, _} = :os.timestamp()
      just_now = a * 1_000_000 + b

      if when_expires < just_now do
        :ets.delete(:session, key)
      end
    end

    :ok
  end
end
