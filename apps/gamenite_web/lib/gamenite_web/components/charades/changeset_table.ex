defmodule GameniteWeb.Components.Charades.ChangesetTable do
  use Surface.LiveComponent
  alias Surface.Components.Form
  alias Surface.Components.Form.{Select, Field, Label, ErrorTag, Submit}

  alias GameniteWeb.ParseHelpers
  alias GamenitePersistance.Accounts
  alias Gamenite.Charades
  alias Gamenite.Charades.{Player}
  alias Gamenite.TeamGame
  alias Gamenite.SaladBowl.API

  data game_changeset, :map
  prop roommates, :map, required: true
  prop slug, :string, required: true

  def update(%{slug: slug, roommates: roommates} = _assigns, socket) do
    {:ok,
     socket
     |> assign(game_changeset: create_game_changeset(%{}, roommates, slug))
     |> assign(slug: slug)
     |> assign(roommates: roommates)}
  end

  def update(%{game_changeset: game_changeset} = _assigns, socket) do
    {:ok,
     socket
     |> assign(
       game_changeset:
         create_game_changeset(game_changeset, socket.assigns.roommates, socket.assigns.slug)
     )}
  end

  defp convert_changeset_params(params, roommates, slug) do
    teams =
      roommates
      |> roommates_to_players
      |> Enum.map(fn player -> Player.new(player) end)
      |> TeamGame.split_teams(2)

    ParseHelpers.key_to_atom(params)
    |> Map.put(:teams, teams)
    |> Map.put(:room_slug, slug)
  end

  defp create_game_changeset(params, roommates, slug) do
    %Charades{}
    |> Charades.salad_bowl_changeset(convert_changeset_params(params, roommates, slug))
  end

  defp roommates_to_players(roommates) do
    roommates
    |> Map.to_list()
    |> Enum.map(fn {_k, %{user_id: user_id} = _roommate} ->
      Accounts.get_user_by(%{id: user_id})
    end)
    |> TeamGame.Player.new_players_from_users()
  end

  @impl true
  def handle_event("start", %{"game" => params}, socket) do
    params = convert_changeset_params(params, socket.assigns.roommates, socket.assigns.slug)

    if SaladBowl.API.exists?(socket.assigns.slug) do
      {:noreply, put_flash(socket, :error, "Game already started.")}
    else
      with {:ok, game} <- Charades.create_salad_bowl(params),
           :ok <- SaladBowl.API.start_game(game, socket.assigns.slug) do
        Gamenite.Room.set_game_in_progress(socket.assigns.slug, true)

        {:noreply,
         socket
         |> assign(:game, game)}
      else
        {:error, reason} ->
          IO.inspect(reason)
          {:noreply, put_flash(socket, :error, "Error creating game.")}
      end
    end
  end

  @impl true
  def handle_event("validate", %{"game" => params}, socket) do
    {:noreply,
     assign(socket,
       game_changeset:
         create_game_changeset(params, socket.assigns.roommates, socket.assigns.slug)
     )}
  end

  # def handle_event("add_round", _from, socket) do
  # end

  # def handle_event("move_round_up", unsigned_params, socket) do
  # end

  # def handle_event("move_round_down", unsigned_params, socket) do
  # end

  # def handle_event("remove_round", unsigned_params, socket) do

  # end

  @impl true
  def render(assigns) do
    ~F"""
    <Form for={@game_changeset} change="validate" submit="start" opts={autocomplete: "off"}>
      <table class="table shadow-md">
        <tbody>
          <Field name={:skip_limit}>
            <tr>
            <td class="options-column rounded-tl-lg">
              <div class="flex justify-start items-center px-4">
                <svg xmlns="http://www.w3.org/2000/svg" class="options-svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7" />
                </svg>
                <div class="px-2 mt-1">
                  <Label>Skip Limit</Label>
                  <ErrorTag/>
                </div>
              </div>
            </td>
            <td class="value-column rounded-tr-lg">
              <Select options={0..5}/>
            </td>
            </tr>
          </Field>
          <Field name={:turn_length}>
          <tr>
            <td class="options-column">
              <div class="flex justify-start items-center px-4">
                <svg xmlns="http://www.w3.org/2000/svg" class="options-svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <div class="px-2 mt-1">
                  <Label>Turn Length</Label>
                  <ErrorTag/>
                </div>
              </div>
            </td>
            <td class="value-column">
              <Select options={[30, 45, 60, 90, 120]}/>
            </td>
          </tr>
          </Field>
          <Field name={:cards_per_player}>
          <tr>
            <td class="options-column rounded-bl-lg">
              <div class="flex justify-start items-center px-4">
                <svg xmlns="http://www.w3.org/2000/svg" class="options-svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
                <div class="px-2 mt-1">
                  <Label>Cards Per Player</Label>
                  <ErrorTag/>
                </div>
              </div>
            </td>
            <td class="value-column rounded-br-lg">
              <Select class="options-select" options={2..10}/>
            </td>
          </tr>
          </Field>
          <Field name={:rounds}>
          <tr class="rounded-b-3xl">
            <td class="options-column">
              <div class="flex justify-start items-center px-4">
                <svg xmlns="http://www.w3.org/2000/svg" class="options-svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
                </svg>
                <div class="px-2 mt-1">
                  <Label>Rounds</Label>
                  <ErrorTag/>
                </div>
              </div>
            </td>
            <td class="value-column">
              {!-- array_input f, :rounds, options: Application.get_env(:gamenite, :salad_bowl_all_rounds)}
              {array_add_button f, :rounds, options: Application.get_env(:gamenite, :salad_bowl_all_rounds)--}
            </td>
          </tr>
          </Field>
        </tbody>
      </table>
      <Submit>Start Game</Submit>
      </Form>
    """
  end
end
