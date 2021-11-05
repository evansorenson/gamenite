defmodule GameniteWeb.Components.Charades.Options do
  use Surface.Component
  alias Surface.Components.Form.{Select}
  alias GameniteWeb.Components.OptionsTable.Row

  def render(assigns) do
    ~F"""
    <Row name={:skip_limit} label={"Skip Limit"}>
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 5l7 7-7 7M5 5l7 7-7 7" />
        </svg>
      <Select options={0..5}/>
    </Row>
    <Row name={:turn_length} label={"Turn Length"}>
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
      <Select options={[30, 45, 60, 90, 120]}/>
    </Row>
    <Row name={:cards_per_player} label={"Cards Per Player"}>
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
        </svg>
      <Select class="options-select" options={2..10}/>
    </Row>
    <Row name={:rounds} label={"Rounds"}>
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
        </svg>
        <div>
      {!-- array_input f, :rounds, options: Application.get_env(:gamenite, :salad_bowl_all_rounds)}
      {array_add_button f, :rounds, options: Application.get_env(:gamenite, :salad_bowl_all_rounds)--}
      </div>
    </Row>
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
