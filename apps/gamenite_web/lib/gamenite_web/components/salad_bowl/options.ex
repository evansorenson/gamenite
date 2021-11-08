defmodule GameniteWeb.Components.SaladBowl.Options do
  use Surface.Component
  alias Surface.Components.Form
  alias Surface.Components.Form.{Submit, Select, NumberInput}
  alias GameniteWeb.Components.OptionsTable.Row

  prop game_changeset, :map, required: true
  prop change, :event, required: true
  prop submit, :event, required: true

  def render(assigns) do
    ~F"""
    <Form for={@game_changeset} as={:game} {=@change} {=@submit} opts={autocomplete: "off"}>
    <table class="table shadow-md">
      <tbody>
      <Row name={:skip_limit} label={"Skip Limit"} first?={true}>
      <:icon>
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7" />
      </svg>
      </:icon>
      <:input>
    <NumberInput/>
    </:input>
    </Row>
    <Row name={:turn_length} label={"Turn Length"}>
      <:icon>
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      </:icon>
      <:input>
    <NumberInput/>
    </:input>
    </Row>
    <Row name={:cards_per_player} label={"Cards Per Player"}>
    <:icon>
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
      </svg>
    </:icon>
    <:input>
    <NumberInput/>
    </:input>
    </Row>
    <Row name={:rounds} label={"Rounds"} last?={true}>
    <:icon>
    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
      </svg>
      </:icon>
      <:input>
      <div>
    {!-- array_input f, :rounds, options: Application.get_env(:gamenite, :salad_bowl_all_rounds)}
    {array_add_button f, :rounds, options: Application.get_env(:gamenite, :salad_bowl_all_rounds)--}
    </div>
    </:input>
    </Row>
      </tbody>
    </table>
    <Submit class="btn-blurple w-full">Start Game</Submit>
    </Form>
    """
  end

  # def handle_event("add_round", _from, socket) do
  # end

  # def handle_event("move_round_up", unsigned_params, socket) do
  # end

  # def handle_event("move_round_down", unsigned_params, socket) do
  # end

  # def handle_event("remove_round", unsigned_params, socket) do

  # end
end
