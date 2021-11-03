defmodule Gamenite.GameConfigs.GameConfig do
  @enforce_keys [:title, :description, :related_games, :components]
  defstruct [:title, :description, :related_games, :components, :decks]

  def parse_and_store_in_ets() do
    create_ets_table()

    get_game_info_files()
    |> Enum.map(fn file -> decode_file_and_insert(file) end)
  end

  @table :game_configs
  defp create_ets_table do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
  end

  defp get_game_info_files() do
    static_dir = Application.app_dir(:gamenite, "priv/static/")
    _files = Path.wildcard(Path.join(static_dir, "*.json"))
  end

  defp decode_file_and_insert(file) do
    file
    |> File.read!
    |> Poison.decode!(keys: :atoms!)
    |> insert_in_ets
  end

  defp insert_in_ets(game_config) do
    :ets.insert(@table, {game_config.title, game_config})
  end
end
