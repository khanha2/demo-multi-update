defmodule DemoMultiUpdate.TestUpdateParallelly do
  import Ecto.Query

  alias DemoMultiUpdate.DemoInventory
  alias DemoMultiUpdate.Repo

  require Logger

  def perform(inventory_rows, use_transaction, max_random_numbers, query_times) do
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
    Enum.each(1..query_times, fn _query_time ->
      random_number = :rand.uniform(max_random_numbers)
      sku = "P#{random_number}"

      Task.start(fn ->
        increase_inventory(sku, use_transaction)
      end)
    end)
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
end
