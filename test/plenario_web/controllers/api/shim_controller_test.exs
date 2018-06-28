defmodule PlenarioWeb.Api.ShimControllerTest do
  use ExUnit.Case
  use Phoenix.ConnTest

  alias Plenario.{
    ModelRegistry,
    Repo
  }

  alias Plenario.Actions.{
    DataSetActions,
    DataSetFieldActions,
    MetaActions,
    UserActions,
    VirtualPointFieldActions
  }

  alias PlenarioAot.AotActions

  @aot_fixture_path "test/fixtures/aot-chicago-future.json"
  @endpoint PlenarioWeb.Endpoint

  setup do
    Ecto.Adapters.SQL.Sandbox.checkout(Plenario.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Plenario.Repo, {:shared, self()})

    {:ok, user} = UserActions.create("API Test User", "test@example.com", "password")
    {:ok, meta} = MetaActions.create("API Test Dataset", user.id, "https://www.example.com", "csv")
    {:ok, _} = DataSetFieldActions.create(meta.id, "pk", "integer")
    {:ok, _} = DataSetFieldActions.create(meta.id, "datetime", "timestamp")
    {:ok, location} = DataSetFieldActions.create(meta.id, "location", "text")
    {:ok, _} = DataSetFieldActions.create(meta.id, "data", "text")
    {:ok, vpf} = VirtualPointFieldActions.create(meta, location.id)

    MetaActions.update_latest_import(meta, NaiveDateTime.utc_now())

    DataSetActions.up!(meta)
    ModelRegistry.clear()

    insert = """
    INSERT INTO "#{meta.table_name}"
      (pk, datetime, data, location)
    VALUES
      (1, '2500-01-01 00:00:00', null, '(50, 50)'),
      (2, '2500-01-01 00:00:00', null, '(50, 50)'),
      (3, '2500-01-01 00:00:00', null, '(50, 50)'),
      (4, '2500-01-01 00:00:00', null, '(50, 50)'),
      (5, '2500-01-01 00:00:00', null, '(50, 50)'),
      (6, '2500-01-02 00:00:00', null, '(50, 50)'),
      (7, '2500-01-02 00:00:00', null, '(50, 50)'),
      (8, '2500-01-02 00:00:00', null, '(50, 50)'),
      (9, '2500-01-02 00:00:00', null, '(50, 50)'),
      (10, '2500-01-02 00:00:00', null, '(50, 50)'),
      (11, '2500-01-02 00:00:00', null, '(50, 50)'),
      (12, '2500-01-02 00:00:00', null, '(50, 50)'),
      (13, '2500-01-02 00:00:00', null, '(50, 50)'),
      (14, '2500-01-02 00:00:00', null, '(50, 50)'),
      (15, '2500-01-02 00:00:00', null, '(50, 50)');
    """
    Ecto.Adapters.SQL.query!(Repo, insert)

    refresh = """
    REFRESH MATERIALIZED VIEW "#{meta.table_name}_view";
    """
    Ecto.Adapters.SQL.query!(Repo, refresh)

    imetas = Enum.map((1..5), fn i ->
      {:ok, m} = MetaActions.create("META #{i}", user.id, "https://www.example.com/#{i}", "csv")
      {:ok, _} = DataSetFieldActions.create(m, "dummy", "integer")
      DataSetActions.up!(m)
      MetaActions.update_latest_import(m, NaiveDateTime.from_iso8601!("2000-01-0#{i}T00:00:00"))
      m
    end)

    metas = imetas ++ [meta]
    Enum.each(metas, fn meta ->
      refresh = """
      REFRESH MATERIALIZED VIEW "#{meta.table_name}_view";
      """
      {:ok, _} = Repo.query(refresh)
    end)

    {:ok, aot_meta} = AotActions.create_meta("Chicago", "https://example.com/")

    File.read!(@aot_fixture_path)
    |> Poison.decode!()
    |> Enum.map(fn obj -> AotActions.insert_data(aot_meta, obj) end)

    AotActions.compute_and_update_meta_bbox(aot_meta)
    AotActions.compute_and_update_meta_time_range(aot_meta)

    %{
      meta: meta,
      vpf: vpf,
      conn: build_conn()
    }
  end

  test "GET /api/v1/datasets", %{conn: conn} do
    get(conn, "/api/v1/datasets")
    |> json_response(200)
  end

  test "GET /api/v1/detail", %{conn: conn, meta: meta} do
    get(conn, "/api/v1/detail?dataset_name=#{meta.slug}")
    |> json_response(200)
  end

  test "GET /api/v1/detail has no 'dataset_name'", %{conn: conn} do
    get(conn, "/api/v1/detail")
    |> json_response(422)
  end

  test "GET /api/v1/detail __ gt", %{conn: conn, meta: meta} do
    get(conn, "/api/v1/detail?dataset_name=#{meta.slug}")
    |> json_response(200)
  end

  test "GET /v1/api/detail", %{conn: conn, meta: meta} do
    get(conn, "/v1/api/detail?dataset_name=#{meta.slug}")
    |> json_response(200)
  end

  test "GET /v1/api/detail has no 'dataset_name'", %{conn: conn} do
    get(conn, "/v1/api/detail")
    |> json_response(422)
  end

  # test "GET /v1/api/detail __ ge", %{conn: conn, meta: meta} do
  #   result =
  #     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__ge=2500-01-01")
  #     |> json_response(200)
  #
  #   assert length(result["data"]) == 100
  #
  #   result =
  #     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__ge=2500-01-02")
  #     |> json_response(200)
  #
  #   assert length(result["data"]) == 25
  # end

  # test "GET /v1/api/detail __gt", %{conn: conn, meta: meta} do
  #   result =
  #     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__gt=2500-01-01")
  #     |> json_response(200)
  #
  #   assert length(result["data"]) == 25
  #
  #   result =
  #     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__gt=2500-01-02")
  #     |> json_response(200)
  #
  #   assert length(result["data"]) == 0
  # end

  # test "GET /v1/api/detail __lt", %{conn: conn, meta: meta} do
  #   result =
  #     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__lt=2500-01-01")
  #     |> json_response(200)
  #
  #   assert length(result["data"]) == 0
  #
  #   result =
  #     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__lt=2500-01-02")
  #     |> json_response(200)
  #
  #   assert length(result["data"]) == 75
  # end

  # test "GET /v1/api/detail __le", %{conn: conn, meta: meta} do
  #   result =
  #     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__le=2500-01-01")
  #     |> json_response(200)
  #
  #   assert length(result["data"]) == 75
  #
  #   result =
  #     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__le=2500-01-02")
  #     |> json_response(200)
  #
  #   assert length(result["data"]) == 100
  # end

  # test "GET /api/v1/detail __eq", %{conn: conn, meta: meta} do
  #   result =
  #     get(conn, "/v1/api/detail?dataset_name=#{meta.slug}&datetime__eq=2500-01-02")
  #     |> json_response(200)
  #
  #   assert length(result["data"]) == 25
  # end

  test "GET /v1/api/datasets", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets"), 200)
    assert length(result["data"]) == 6
  end

  test "GET /api/v1/datasets has correct count", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets"), 200)
    assert result["meta"]["counts"]["total_records"] == 6
  end

  test "GET /v1/api/datasets __ge", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__ge=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 4
  end

  test "GET /v1/api/datasets __gt", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__gt=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 3
  end

  test "GET /v1/api/datasets __le", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__le=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 3
  end

  test "GET /v1/api/datasets __lt", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__lt=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 2
  end

  test "GET /v1/api/datasets __eq", %{conn: conn} do
    result = json_response(get(conn, "/api/v1/datasets?latest_import__eq=2000-01-03T00:00:00"), 200)
    assert result["meta"]["counts"]["total_records"] == 1
  end
end