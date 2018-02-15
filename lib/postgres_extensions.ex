Postgrex.Types.define(
  Plenario.PostGisTypes,
  [Geo.PostGIS.Extension] ++ Ecto.Adapters.Postgres.extensions(),
  json: Poison
)

defmodule Plenario.TsTzRange do
  @behaviour Ecto.Type

  def type(), do: :tstzrange

  def cast(nil), do: {:ok, nil}
  def cast([lower, upper]), do: {:ok, [lower, upper]}
  def cast(_), do: :error

  def load(%Postgrex.Range{lower: lower, upper: upper}) do
    lower = to_datetime(lower)
    upper = to_datetime(upper)

    case {lower, upper} do
      {nil, nil} -> {:ok, [nil, nil]}
      {{:ok, lower}, {:ok, upper}} -> {:ok, [lower, upper]}
      _ -> :error
    end
  end
  def load(_), do: :error

  def dump([lower, upper]) do
    {
      :ok,
      %Postgrex.Range{
        lower: from_datetime(lower),
        upper: from_datetime(upper),
        upper_inclusive: true
      }
    }
  end
  def dump(_), do: :error

  defp to_datetime(nil), do: nil
  defp to_datetime({{y, m, d}, {h, mm, s, ms}}) do
    {status, dt, _} = DateTime.from_iso8601("#{y}-#{lp(m)}-#{lp(d)}T#{lp(h)}:#{lp(mm)}:#{lp(s)}.#{ms}Z")
    case status do
      :ok -> {:ok, dt}
      _ -> :error
    end
  end

  defp from_datetime(nil), do: nil
  defp from_datetime(dt) do
    {
      {dt.year, dt.month, dt.day},
      {dt.hour, dt.minute, dt.second, elem(dt.microsecond, 0)}
    }
  end

  defp lp(number) do
    if number >= 10 do
      "#{number}"
    else
      "0#{number}"
    end
  end
end