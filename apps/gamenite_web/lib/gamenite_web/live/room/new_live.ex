defmodule GameniteWeb.Room.NewLive do
  @moduledoc """
  A LiveView for creating and joining chat rooms
  """

  use GameniteWeb, :live_view

  alias GamenitePersistance.Accounts
  alias Gamenite.Games.CharadesOptions
  alias Gamenite.TeamGame
  alias Gamenite.TeamGame.Team
  alias Gamenite.RoomKeeper


  alias GameniteWeb.Presence
  alias Phoenix.Socket.Broadcast



  @impl true
  @spec mount(any, map, Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, %{"slug" => slug, "game_id" => game_id } = session, socket) do
    room_state =

    user = mount_socket_user(socket, session)
    game = GamenitePersistance.Gaming.get_game!(game_id)
    game_state = Gamenite.start_game(game.name, room_state.id)
    game_options_changeset = CharadesOptions.new_salad_bowl(%{})
    team_game_changeset = TeamGame.teams_changeset(%TeamGame{}, %{teams: [%{}, %{}]})

    # This PubSub subscription will also handle other events from the users.
    Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "room:" <> slug)

    # This PubSub subscription will allow the user to receive messages from
    # other users.
    Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "room:" <> slug <> ":" <> user.id)

    # Track the connecting user with the `room:slug` topic.
    {:ok, _} = Presence.track(self(), "room:" <> slug, user.id, %{})

    case RoomKeeper.create_room(slug, "Testing") do
      {:ok, _pid} ->
        {:ok,
          socket
          |> assign(:room_state, room_state)
          |> assign(:game_state, game_state)
          |> assign(:game_options_changeset, game_options_changeset)
          |> assign(:team_game_changeset, team_game_changeset)
          |> assign(:user, user)
          |> assign(:slug, slug)
          |> assign(:connected_users, [])
          |> assign(:offer_requests, [])
          |> assign(:ice_candidate_offers, [])
          |> assign(:sdp_offers, [])
          |> assign(:answers, [])
        }
      _ ->
        {:ok,
          socket
          |> put_flash(:error, "That room does not exist.")
          |> push_redirect(to: Routes.game_path(socket, :index))
        }
    end
  end

  @doc """
  Callback that happens when the LV process is terminating.
  This allows the player to be removed from the game, and
  the entire game server process can also be terminated if
  there are no remaining players.
  """
  @spec unmount(term(), map()) :: :ok
  def unmount(_reason, %{player_id: player_id, room_id: room_id}) do
    # {:ok, game} = GameServer.leave_game(game_id, player_id)
    # broadcast_game_state_update!(room_id, game)

    # if length(game.connected_players) == 0 do
    #   GameSupervisor.terminate_child(game_id)
    # end

    :ok
  end

  @impl true
  def handle_info(%Broadcast{event: "presence_diff"}, socket) do
    {:noreply,
      socket
      |> assign(:connected_users, list_present(socket))}
  end

  @impl true
  @doc """
  When an offer requested has been received, add it to the '@offer_request' list.
  """
  def handle_info(%Broadcast{event: "request_offers", payload: request}, socket) do
    {:noreply,
      socket
      |> assign(:offer_requests, socket.assigns.offer_requests ++ [request])}
  end

  @impl true
  def handle_info(%Broadcast{event: "new_ice_candidate", payload: payload}, socket) do
    {:noreply,
      socket
      |> assign(:ice_candidate_offers, socket.assigns.ice_candidate_offers ++ [payload])
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "new_sdp_offer", payload: payload}, socket) do
    {:noreply,
      socket
      |> assign(:sdp_offers, socket.assigns.ice_candidate_offers ++ [payload])
    }
  end

  @impl true
  def handle_info(%Broadcast{event: "new_answer", payload: payload}, socket) do
    {:noreply,
      socket
      |> assign(:answers, socket.assigns.answers ++ [payload])
    }
  end

  @impl true
  def handle_event("join_call", _params, socket) do
    for user <- socket.assigns.connected_users do
      send_direct_message(
        socket.assigns.slug,
        user,
        "request_offers",
        %{from_user: socket.assigns.user}
      )
    end

    {:noreply, socket}
  end

  @impl true
  def handle_event("new_ice_candidate", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.user.username})

    send_direct_message(socket.assigns.slug, payload["toUser"], "new_ice_candidate", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_sdp_offer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.user.username})

    send_direct_message(socket.assigns.slug, payload["toUser"], "new_sdp_offer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("new_answer", payload, socket) do
    payload = Map.merge(payload, %{"from_user" => socket.assigns.user.username})

    send_direct_message(socket.assigns.slug, payload["toUser"], "new_answer", payload)
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate", %{"charades_options" => params}, socket) do
    game_options_changeset =
      %CharadesOptions{}
      |> CharadesOptions.salad_bowl_changeset(params)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, game_options_changeset: game_options_changeset)}
  end

  @impl true
  def handle_event("validate", %{"player_cards" => params}, socket) do
    game_options_changeset =
      %CharadesOptions{}
      |> CharadesOptions.salad_bowl_changeset(params)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, game_options_changeset: game_options_changeset)}
  end

  @impl true
  def handle_event("change_display_name", %{"new_name" => new_name}, socket) do
    socket
  end

  @impl true
  def handle_event("start_game", _payload, socket) do
    IO.puts "hi"

    players = socket.assigns.connected_users
    |> Enum.map(fn username -> Accounts.get_user_by(%{username: username}) end)
    |> TeamGame.Player.new_players_from_users()
    IO.inspect(players)

    teams = players
    |> TeamGame.Team.split_teams(2)
    IO.inspect(teams)

    TeamGame.new(%{teams: teams})


    {:noreply,
    socket
    |> push_redirect(to: Routes.room_path(socket, :show, socket.assigns.slug))
    }
    {:noreply, socket}
  end


  @spec list_present(
          atom
          | %{:assigns => atom | %{:slug => binary, optional(any) => any}, optional(any) => any}
        ) :: list
  def list_present(socket) do
    Presence.list("room:" <> socket.assigns.slug)
    |> Enum.map(fn {_, %{user: user, metas: _}} -> user.username
     end)
  end

  defp send_direct_message(slug, to_user, event, payload) do
    GameniteWeb.Endpoint.broadcast_from(
      self(),
      "room:" <> slug <> ":" <> to_user,
      event,
      payload
    )
  end

  defp mount_socket_user(socket, params) do
    user_id = Map.get(params, "user_id")
    user = GamenitePersistance.Accounts.get_user(user_id)
    socket
    |> assign(:user, user)
    user
  end
end
