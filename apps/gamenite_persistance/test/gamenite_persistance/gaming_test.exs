defmodule GamenitePersistance.GamingTest do
  use GamenitePersistance.DataCase

  alias GamenitePersistance.Gaming

  describe "games" do
    alias GamenitePersistance.Gaming.Game

    @valid_attrs %{description: "some description", play_count: 42, title: "some title"}
    @update_attrs %{description: "some updated description", play_count: 43, title: "some updated title"}
    @invalid_attrs %{description: nil, play_count: nil, title: nil}

    def game_fixture(attrs \\ %{}) do
      {:ok, game} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Gaming.create_game()

      game
    end

    test "list_games/0 returns all games" do
      game = game_fixture()
      assert Gaming.list_games() == [game]
    end

    test "get_game!/1 returns the game with given id" do
      game = game_fixture()
      assert Gaming.get_game!(game.id) == game
    end

    test "create_game/1 with valid data creates a game" do
      assert {:ok, %Game{} = game} = Gaming.create_game(@valid_attrs)
      assert game.description == "some description"
      assert game.play_count == 42
      assert game.title == "some title"
    end

    test "create_game/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Gaming.create_game(@invalid_attrs)
    end

    test "update_game/2 with valid data updates the game" do
      game = game_fixture()
      assert {:ok, %Game{} = game} = Gaming.update_game(game, @update_attrs)
      assert game.description == "some updated description"
      assert game.play_count == 43
      assert game.title == "some updated title"
    end

    test "update_game/2 with invalid data returns error changeset" do
      game = game_fixture()
      assert {:error, %Ecto.Changeset{}} = Gaming.update_game(game, @invalid_attrs)
      assert game == Gaming.get_game!(game.id)
    end

    test "delete_game/1 deletes the game" do
      game = game_fixture()
      assert {:ok, %Game{}} = Gaming.delete_game(game)
      assert_raise Ecto.NoResultsError, fn -> Gaming.get_game!(game.id) end
    end

    test "change_game/1 returns a game changeset" do
      game = game_fixture()
      assert %Ecto.Changeset{} = Gaming.change_game(game)
    end
  end
end
