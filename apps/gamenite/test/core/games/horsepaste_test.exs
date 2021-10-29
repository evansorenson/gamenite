defmodule HorsePasteTest do
  use ExUnit.Case
  use GameBuilders

  describe "creating game" do
    test "game must have at least two teams with four players total" do
    end

    test "board must be initialized with 25 words in 5x5 grid" do
    end

    test "randomize which team goes first" do
    end
  end

  describe "assign cards colors/roles" do
    test "9 cards for starting team" do
    end

    test "8 cards for second team" do
    end

    test "7 bystanders" do
    end

    test "1 assassin" do
    end
  end

  describe "assign players roles" do
    test "one spymaster per team" do
    end

    test "rest of players are guessers" do
    end
  end

  describe "giving clues" do
    test "invalid empty clue" do
    end

    test "invalid clue with more than one word (has spaces)" do
    end

    test "valid one word clue" do
    end
  end

  describe "selecting words" do
    test "selecting own color with words left continues turn" do
    end

    test "selecting own color with no words or +1 from previous remaining ends turn" do
    end

    test "select bystander or other teams color ends turn" do
    end

    test "selecting assassin ends game and other team wins" do
    end

    test "selecting red or blue removes point from appropraite team score" do
    end
  end
end
