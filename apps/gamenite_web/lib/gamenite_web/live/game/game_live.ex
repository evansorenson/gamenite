defmodule GameniteWeb.GameLive do
  use GameniteWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias GamenitePersistance.Accounts

  @impl true
  def mount(_params, %{"slug" => slug, "game_id" => game_id } = _session, socket) do
    game_info = GamenitePersistance.Gaming.get_game!(game_id)

    Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "game:" <> slug)

    game_options_changeset = CharadesOptions.new_salad_bowl(%{})

    {:ok,
    socket
    |> assign(game_info: game_info)
    |> assign(game_options_changeset: game_options_changeset)
    |> assign(slug: slug)
    }
  end

  @impl true
  def handle_event("start_game", _payload, socket) do
    case socket.assigns.game_options_changeset do
      {:ok, game_options} ->
        socket.assigns.game_info
        |> Gamenite.construct_game_data(
          game_options,
          socket.assigns.connected_users,
          &Gamenite.Games.CharadesPlayer.new/1
          )
        |> Gamenite.start_game(socket.assigns.slug)

        {:noreply, assign(socket, Gamenite.SaladBowlGameKeeper.state())}
      {:error, _errors} ->
        {:noreply, put_flash(socket, :error, "Game Options have errors.")}
    end
  end

  defp start_or_get_game_process(game_info, slug) do
    case Gamenite.start_game(game_info.title, slug) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      _ -> :error
    end
  end

  defp broadcast_game_update(room_id, game) do
    GameniteWeb.Endpoint.broadcast_from(
      self(),
      "game:" <> room_id,
      "game_state_update",
      game
    )
  end

  def handle_info(%Broadcast{event: "game_state_update", payload: game}, socket) do

    {:noreply,
      socket
      |> assign(:game, game)}
  end

  def handle_info(%Broadcast{event: "connected_users_update", payload: game}, socket) do

    {:noreply,
      socket
      |> assign(:connected_users, game)}
  end

  @impl true
  def handle_event("validate", %{"charades_options" => params}, socket) do
    game_options_changeset =
      %CharadesOptions{}
      |> CharadesOptions.salad_bowl_changeset(params)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, game_options_changeset: game_options_changeset)}
  end
end
