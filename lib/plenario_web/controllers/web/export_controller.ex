defmodule PlenarioWeb.Web.ExportController do
  use PlenarioWeb, :web_controller

  alias Plenario.Actions.MetaActions

  alias PlenarioEtl.Actions.ExportJobActions

  alias PlenarioEtl.Exporter

  alias Plenario.ModelRegistry

  def export_query(conn, %{"meta_id" => meta_id, "query" => query}) do
    meta = MetaActions.get(meta_id)
    user = Guardian.Plug.current_resource(conn)

    if user == nil do
      conn
      |> put_flash(:error, "You must sign in to export data sets.")
      |> redirect(to: auth_path(conn, :index))
    end

    case ExportJobActions.create(meta, user, query, false) do
      {:ok, job} ->
        case Exporter.export_task(job) do
          {:ok, _} ->
            conn
            |> put_flash(:success, "Export started! You'll be emailed soon with a link.")
            |> redirect(to: page_path(conn, :explorer))

          {:error, _} ->
            conn
            |> put_status(:bad_request)
            |> put_flash(:error, "There was a problem creating your export request.")
            |> redirect(to: page_path(conn, :explorer))
        end

      {:error, _} ->
        conn
        |> put_status(:bad_request)
        |> put_flash(:error, "There was a problem creating your export request.")
        |> redirect(to: page_path(conn, :explorer))
    end
  end
end
