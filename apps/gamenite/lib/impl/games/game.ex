defmodule Gamenite.Game do
  @callback setup(struct()) :: struct() | {:error, term()}
  defmacro __using__(_opts) do
    quote do
      import Ecto.Changeset
      alias Gamenite.Game
      @behaviour Gamenite.Game
      use Accessible

      def change(%__MODULE__{} = game, attrs \\ %{}) do
        game
        |> Game.base_changeset(attrs)
        |> __MODULE__.changeset(attrs)
      end

      def new() do
        %__MODULE__{}
      end

      def create(attrs) do
        %__MODULE__{}
        |> Game.base_changeset(attrs)
        |> __MODULE__.changeset(attrs)
        |> apply_action(:update)
      end
    end
  end

  import Ecto.Changeset

  def base_changeset(game, attrs) do
    game
    |> cast(attrs, [:room_slug])
    |> validate_required(:room_slug)
  end
end
