defmodule DemoMultiUpdate.Repo.Migrations.CreateDemoInventories do
  use Ecto.Migration

  def change do
    create table(:demo_inventories) do
      add(:sku, :text)
      add(:quantity, :integer, default: 0)
    end

    create(unique_index(:demo_inventories, [:sku]))
  end
end
