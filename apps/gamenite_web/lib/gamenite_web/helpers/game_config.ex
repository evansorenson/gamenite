defmodule GameniteWeb.GameConfig do
  @enforce_keys [:title, :category, :team_game?, :description, :related_games, :components]
  defstruct [:title, :description, :category, :team_game?, :related_games, :components, :decks]

  defmodule Components do
    @enforce_keys [:game, :options, :scoreboard, :finished]
    defstruct game: nil, changeset: nil, scoreboard: nil, finished: nil

    def new(attr) do
      struct!(__MODULE__, attr)
    end
  end

  @table :game_configs
  def list_configs() do
    :ets.tab2list(@table)
    |> Enum.map(fn {_k, v} -> v end)
  end

  def get_config(game_title) do
    [{_k, config}] = :ets.lookup(@table, game_title)
    config
  end

  def parse_and_store_in_ets() do
    create_ets_table()

    get_game_config_filepaths()
    |> Enum.map(&decode_file_and_insert/1)
  end

  defp create_ets_table do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
  end

  defp get_game_config_filepaths() do
    static_dir = Application.app_dir(:gamenite_web, "priv/game_configs/")
    _files = Path.wildcard(Path.join(static_dir, "*.json"))
  end

  defp decode_file_and_insert(filepath) do
    filepath
    |> File.read!()
    |> Poison.decode!(keys: :atoms)
    |> component_modules_to_atoms
    |> modules_to_atoms
    |> insert_in_ets()
  end

  defp component_modules_to_atoms(game_config) do
    update_in(game_config.components, fn modules ->
      Enum.into(modules, %{}, fn {k, v} -> {k, String.to_existing_atom(v)} end)
    end)
  end

  defp modules_to_atoms(game_config, modules \\ [:server, :impl, :player]) do
    game_config
    |> Enum.into(%{}, fn {k, v} ->
      if k in modules do
        {k, String.to_existing_atom(v)}
      else
        {k, v}
      end
    end)
  end

  defp insert_in_ets(game_config) do
    :ets.insert(@table, {game_config.title, game_config})
  end
end
