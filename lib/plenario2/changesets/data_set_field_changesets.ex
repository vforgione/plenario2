defmodule Plenario2.Changesets.DataSetFieldChangesets do
  @moduledoc """
  This module provides functions for creating changesets for
  DataSetField structs.
  """

  import Ecto.Changeset

  alias Plenario2.Schemas.DataSetField

  @typedoc """
  Verbose map of params for create
  """
  @type create_params :: %{
    name: String.t,
    type: String.t,
    opts: String.t,
    meta_id: integer
  }

  @new_create_param_keys [:name, :type, :opts, :meta_id]

  @valid_types ~w(text integer float boolean timestamptz geometry(polygon,4326))

  @doc """
  Creates a blank changeset for creating a webform
  """
  @spec new() :: Ecto.Changeset.t
  def new() do
    %DataSetField{}
    |> cast(%{}, @new_create_param_keys)
  end

  @doc """
  Creates a changeset for inserting a new DataSetField into the database
  """
  @spec create(params :: create_params) :: Ecto.Changeset.t
  def create(params) do
    %DataSetField{}
    |> cast(params, @new_create_param_keys)
    |> validate_required(@new_create_param_keys)
    |> cast_assoc(:meta)
    |> check_name()
    |> validate_type()
  end

  @doc """
  Updates an existing data set field
  """
  @spec update(field :: DataSetField, params :: create_params) :: Ecto.Changeset.t
  def update(field, params \\ %{}) do
    field
    |> cast(params, @new_create_param_keys)
    |> validate_required(@new_create_param_keys)
    |> cast_assoc(:meta)
    |> check_name()
    |> validate_type()
  end

  # TODO: delete this? i don't know where we're using it or why we would...
  def make_primary_key(field) do
    field
    |> cast(%{}, [])
    |> put_change(:opts, "not null primary key")
  end

  # Converts name values to snake case
  # For example, if a user passes a field named "Event ID", this would return "event_id"
  defp check_name(changeset) do
    name = get_field(changeset, :name)
    snaked_name =
      String.split(name, ~r/\s/, trim: true)
      |> Enum.map(&String.downcase(&1))
      |> Enum.join("_")

    changeset |> put_change(:name, snaked_name)
  end

  # Validates the given type of the field is one we support, as defined in @valid_types
  defp validate_type(changeset) do
    type = get_field(changeset, :type)
    if Enum.member?(@valid_types, type) do
      changeset
    else
      changeset |> add_error(:type, "Invalid type selection")
    end
  end
end
