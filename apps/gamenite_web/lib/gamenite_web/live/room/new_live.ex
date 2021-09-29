defmodule GameniteWeb.Room.NewLive do
  @moduledoc """
  A LiveView for creating and joining chat rooms
  """

  use GameniteWeb, :live_view
  require Logger

  alias GamenitePersistance.Accounts
  alias Gamenite.Games.CharadesOptions
  alias Gamenite.TeamGame

  alias GameniteWeb.RoomComponent

  alias Phoenix.Socket.Broadcast

  @impl true
  @spec mount(any, map, Phoenix.LiveView.Socket.t()) :: {:ok, Phoenix.LiveView.Socket.t()}
  def mount(_params, %{"slug" => slug, "game_id" => game_id } = session, socket) do
    user = mount_socket_user(socket, session)
    game = GamenitePersistance.Gaming.get_game!(game_id)
    Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "room:" <> slug)

    with :ok <- start_or_get_game_process(game, slug)
    do
      game_options_changeset = CharadesOptions.new_salad_bowl(%{})
      team_game_changeset = TeamGame.teams_changeset(%TeamGame{}, %{teams: [%{}, %{}]})

      # This PubSub subscription will also handle other events from the users.
      Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "game:" <> slug)

      # This PubSub subscription will allow the user to receive messages from
      # other users.
      Phoenix.PubSub.subscribe(GamenitePersistance.PubSub, "room:" <> slug <> ":" <> user.id)

      {:ok,
    socket
        |> assign(:slug, slug)
        |> assign(:game, game)
        |> assign(:game_options_changeset, game_options_changeset)
        |> assign(:team_game_changeset, team_game_changeset)
        |> assign(:user, user)
        |> assign(:offer_requests, [])
        |> assign(:ice_candidate_offers, [])
        |> assign(:sdp_offers, [])
        |> assign(:answers, [])
    }
    else
      {:error, _reason} -> {:ok,
          socket
          |> put_flash(:error, "Room could not be created.")
          |> push_redirect(to: Routes.game_path(socket, :index))
        }
    end
  end

  defp start_or_get_game_process(game, slug) do
    case Gamenite.start_game(game.title, slug) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      _ -> :error
    end
  end

  def handle_info(%Broadcast{event: "room_state_update", payload: room}, socket) do
    IO.puts socket.assigns.user.id
    IO.inspect room
    send_update(RoomComponent, id: 1, room: room)
    {:noreply, socket}
  end

  def handle_info(%Broadcast{event: "game_state_update", payload: game}, socket) do

    {:noreply,
      socket
      |> assign(:game, game)}
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
  def handle_event("change_display_name", %{"new_name" => new_name}, socket) do
    socket
  end

  @impl true
  def handle_event("start_game", _payload, socket) do
    players = socket.assigns.room.connected_users |> Map.to_list()
    |> Enum.map(fn {_k, %{user_id: user_id} = _roommate} -> Accounts.get_user_by(%{id: user_id}) end)
    |> TeamGame.Player.new_players_from_users()

    teams = players
    |> TeamGame.Team.split_teams(2)

    # game_changeset = TeamGame.finalize_game_changeset(socket.assigns.game, %{teams: teams})

    {:noreply, socket}
  end



  defp broadcast_game_update(room_id, game) do
    GameniteWeb.Endpoint.broadcast_from(
      self(),
      "game:" <> room_id,
      "game_state_update",
      game
    )
  end

  defp mount_socket_user(socket, params) do
    user_id = Map.get(params, "user_id")
    user = GamenitePersistance.Accounts.get_user(user_id)
    socket
    |> assign(:user, user)
    user
  end

    ## All RPC logic >>>
    @impl true
    @doc """
    When an offer requested has been received, add it to the '@offer_request' list.
    """
    defp send_direct_message(slug, to_user, event, payload) do
      GameniteWeb.Endpoint.broadcast_from(
        self(),
        "room:" <> slug <> ":" <> to_user,
        event,
        payload
      )
    end

    @impl true
    def handle_event("join_call", _params, socket) do
      for user <- socket.assigns.room.connected_users do
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
end
