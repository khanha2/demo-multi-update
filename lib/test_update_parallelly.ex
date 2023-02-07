defmodule DemoMultiUpdate.TestUpdateParallelly do
  import Ecto.Query

  alias DemoMultiUpdate.DemoInventory
  alias DemoMultiUpdate.Repo

  require Logger

  def perform(
        inventory_rows,
        use_transaction,
        max_random_numbers,
        query_times,
        make_errors \\ false
      ) do
    # truncate inventories table
    Repo.query("TRUNCATE TABLE demo_inventories RESTART IDENTITY RESTRICT;", [])

    # fill inventories table
    1..inventory_rows
    |> Enum.chunk_every(1000)
    |> Enum.each(fn numbers ->
      inventories = Enum.map(numbers, fn number -> %{sku: "P#{number}"} end)
      Repo.insert_all(DemoInventory, inventories)
    end)

    # Test update parallelly
    tasks =
      Enum.map(1..query_times, fn _query_time ->
        random_number = :rand.uniform(max_random_numbers)
        sku = "P#{random_number}"

        random_action = :rand.uniform(2)

        case random_action do
          1 ->
            Task.async(fn ->
              increase_inventory(sku, use_transaction)
            end)

          2 ->
            Task.async(fn ->
              upsert_inventory(sku, use_transaction, make_errors)
            end)
        end
      end)

    Task.yield_many(tasks, :infinity)

    :ok
  end

  defp increase_inventory(sku, true) do
    multi_key = "update_sku_#{sku}"

    query = from(inventory in DemoInventory, where: inventory.sku == ^sku)

    Ecto.Multi.new()
    |> Ecto.Multi.update_all(multi_key, query, inc: [quantity: 1])
    |> Repo.transaction()
    |> case do
      {:ok, result} ->
        case result[multi_key] do
          {1, _} ->
            nil

          _error ->
            Logger.error("increase inventory for SKU #{sku} unsuccessfully: #{inspect(result)}")
        end

      error ->
        Logger.error("increase inventory for SKU #{sku} unsuccessfully: #{inspect(error)}")
    end
  end

  defp increase_inventory(sku, false) do
    DemoInventory
    |> where([inventory], inventory.sku == ^sku)
    |> Repo.update_all(inc: [quantity: 1])
    |> case do
      {1, _} ->
        nil

      error ->
        Logger.error("increase inventory for SKU #{sku} unsuccessfully: #{inspect(error)}")
    end
  end

  defp upsert_inventory(sku, true, make_errors) do
    inventories = [%{sku: sku}]

    multi_key = "upsert_sku_#{sku}"

    try do
      if make_errors do
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(
          multi_key,
          DemoInventory,
          inventories,
          on_conflict: {:replace, [:quantity]},
          conflict_target: [:sku]
        )
        |> Repo.transaction()
      else
        Ecto.Multi.new()
        |> Ecto.Multi.insert_all(
          multi_key,
          DemoInventory,
          inventories,
          on_conflict: :nothing,
          conflict_target: [:sku]
        )
        |> Repo.transaction()
      end
    rescue
      error ->
        Logger.error("upsert inventory for SKU #{sku} unsuccessfully: #{inspect(error)}")
    end
  end

  defp upsert_inventory(sku, false, make_errors) do
    inventories = [%{sku: sku}]

    try do
      if make_errors do
        Repo.insert_all(
          DemoInventory,
          inventories,
          on_conflict: {:replace, [:quantity]},
          conflict_target: [:sku]
        )
      else
        Repo.insert_all(
          DemoInventory,
          inventories,
          on_conflict: :nothing,
          conflict_target: [:sku]
        )
      end
    rescue
      error ->
        Logger.error("upsert inventory for SKU #{sku} unsuccessfully: #{inspect(error)}")
    end
  end
end
