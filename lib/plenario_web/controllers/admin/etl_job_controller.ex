defmodule PlenarioWeb.Admin.EtlJobController do
  use PlenarioWeb, :admin_controller

  alias PlenarioEtl.Actions.EtlJobActions

  def index(conn, _) do
    jobs = EtlJobActions.list()
    running_now = Enum.filter(jobs, fn j -> j.completed_on == nil end)
    completed = Enum.filter(jobs, fn j -> j.completed_on != nil end)

    num_running = length(running_now)
    num_completed = length(completed)

    render(conn, "index.html",
      running_now: running_now,
      completed: completed,
      num_running: num_running,
      num_completed: num_completed
    )
  end
end
