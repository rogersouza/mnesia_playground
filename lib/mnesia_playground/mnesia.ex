defmodule MnesiaPlayground.Mnesia do
  @moduledoc "Orchestrates the connection of a newly spawned node"

  use GenServer

  require Logger

  alias :mnesia, as: Mnesia
  alias :rpc, as: RPC

  @wait_for_tables :timer.seconds(30)

  @doc false
  @spec init(any) :: {:ok, []}
  def init(_) do
    init_tables()

    {:ok, []}
  end

  @doc false
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  defp init_tables do
    Logger.info("#{__MODULE__} initalizing tables")

    nodes = connected_nodes()

    create_schema(nodes)
    start_mnesia_on_all_nodes(nodes)
    add_new_node_to_mnesia_cluster(nodes)
    create_or_copy_table(nodes)

    wait_for_tables()
  end

  defp connected_nodes do
    [node()] ++ Node.list()
  end

  defp create_schema(nodes) when is_list(nodes) do
    case Mnesia.create_schema(nodes) do
      :ok ->
        Logger.info("#{__MODULE__} created schema")
        :ok

      {:error, {_, {:already_exists, _}}} ->
        Logger.info("#{__MODULE__} schema already created")
        :ok
    end
  end

  defp start_mnesia_on_all_nodes(nodes) do
    Logger.info("#{__MODULE__} starting mnesia on all nodes")
    RPC.multicall(nodes, Mnesia, :start, [])
  end

  defp add_new_node_to_mnesia_cluster([node | _] = nodes) do
    Logger.info("#{__MODULE__} starting new node through #{node}")
    RPC.call(node, :mnesia, :change_config, [:extra_db_nodes, nodes])
    Mnesia.change_table_copy_type(:schema, node(), :disc_copies)
  end

  defp create_or_copy_table(nodes) do
    Logger.info("#{__MODULE__} creating Users table")

    case Mnesia.create_table(Users, attributes: [:id, :name], disc_copies: nodes) do
      {:atomic, :ok} ->
        Logger.info("#{__MODULE__} table created")
        :ok

      {:aborted, {:already_exists, _}} ->
        copy_table()
        :ok
    end
  end

  defp copy_table do
    Logger.info("#{__MODULE__} Copying table")
    RPC.multicall(Mnesia, :add_table_copy, [Users, node(), :disc_copies])
  end

  defp wait_for_tables do
    Logger.info("#{__MODULE__} waiting tables")
    :ok = :mnesia.wait_for_tables([Users], @wait_for_tables)
  end
end
