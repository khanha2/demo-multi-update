defmodule DemoMultiUpdate.DemoInventory do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix :zalora
  schema "demo_inventories" do
    field(:sku, :string)
    field(:quantity, :integer, default: 0)

    timestamps()
  end

  @default_fields [
    :id,
    :inserted_at,
    :updated_at
  ]

  @required_fields [:sku]

  @doc false
  def changeset(zalora_order, attrs) do
    zalora_order
    |> cast(attrs, __MODULE__.__schema__(:fields) -- @default_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:sku)
  end
end
