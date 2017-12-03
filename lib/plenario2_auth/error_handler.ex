defmodule Plenario2Auth.ErrorHandler do
  import Plug.Conn

  @doc """
  Handles unauthenticated users -- sends a 401 resopnse. Used by Guardian.
  """
  def auth_error(conn, _, _) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:unauthorized, "unauthorized")
    |> halt()
  end

  @doc """
  Handles unauthorized access -- sends a 403 response. Used by Canary.
  """
  def handle_unauthorized(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:forbidden, "forbidden")
    |> halt()
  end

  @doc """
  Handles missing resource -- sends a 404 response. Used by Canary.
  """
  def handle_not_found(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(:not_found, "not found")
    |> halt()
  end
end