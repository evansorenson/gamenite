defmodule Gamenite.Witbash.Prompt do
  use Accessible

  defstruct prompt: nil,
            answers: [],
            assigned_user_ids: [],
            is_final?: false
end
