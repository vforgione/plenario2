defmodule PlenarioEtl.ScheduledJobs do
  import Ecto.Query
  alias Plenario.Schemas.Meta
  alias Plenario.Repo

  def find_refreshable_metas() do
    offset = Application.get_env(:plenario, :refresh_offest)
    starts = DateTime.utc_now()
    ends = Timex.shift(starts, offset)

    Repo.all(
      from(
        m in Meta,
        where: m.refresh_starts_on <= ^starts,
        where: is_nil(m.refresh_ends_on) or m.refresh_ends_on >= ^ends,
        where: m.next_import >= ^starts,
        where: m.next_import < ^ends
      )
    )
  end
end
