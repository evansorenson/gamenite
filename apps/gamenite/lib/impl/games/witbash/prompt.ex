defmodule Gamenite.Witbash.Prompt do
  defstruct id: nil,
            prompt: nil,
            answers: [],
            assigned_player_ids: [],
            votes: [],
            is_final?: false
end