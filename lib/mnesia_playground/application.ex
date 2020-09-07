defmodule MnesiaPlayground.Application do
  @moduledoc false

  require Logger

  use Application

  def start(_type, _args) do
    :ok = define_mnesia_dir()
    :ok = connect_nodes()

    children = [
      {MnesiaPlayground.Mnesia, []}
    ]

    opts = [strategy: :one_for_one, name: MnesiaPlayground.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp connect_nodes do
    [:a, :b, :c, :e, :f, :g, :h]
    |> Enum.map(&node_name/1)
    |> Enum.each(&connect_node/1)
  end

  defp node_name(id) do
    {:ok, host} = :inet.gethostname()
    :"mnesia_playground_#{id}@#{host}"
  end

  defp connect_node(node) do
    case Node.connect(node) do
      true ->
        Logger.info("#{__MODULE__} connected successfully to #{node}")
        :ok

      err ->
        Logger.warn("#{__MODULE__} could not connect to #{node}. Error: #{inspect(err)}")
        :ok
    end

    :ok
  end

  defp define_mnesia_dir do
    File.mkdir("databases")
    File.mkdir("databases/#{node()}")

    path = Path.join(File.cwd!(), "databases/#{node()}")
    Application.put_env(:mnesia, :dir, to_charlist(path))

    :ok
  end
end
