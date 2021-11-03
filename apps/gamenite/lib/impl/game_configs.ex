defmodule Gamenite.GameConfigs do
  @table :game_configs
  def list_configs() do
    :ets.tab2list(@table)
    |> Enum.map(fn {_k, v} -> v end)
  end

  def get_config(game_title) do
    [ {_k, config} ] = :ets.lookup(@table, game_title)
    config
  end
end
