defmodule GameniteWeb.Components.ConnectedUsers do
  use Surface.Component

  alias GameniteWeb.Components.PlayerName

  prop user_id, :any, required: true
  prop roommates, :map, required: true
  prop flex, :string, default: "wrap"

  def render(assigns) do
    ~F"""
    <div class="bg-white shadow-md rounded-lg">
      <h1 class="text-6xl py-4 text-center font-bold text-black">Players</h1>
      <div class={"flex flex-#{@flex} justify-center items-center pb-8"}>
        {#for {_id, roomate} <- Map.to_list(@roommates)}
          <PlayerName roommate={roomate} {=@user_id} font_size={"text-3xl"}/>
        {/for}
      </div>
    </div>
    """
  end
end
