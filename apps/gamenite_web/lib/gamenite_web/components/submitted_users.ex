defmodule GameniteWeb.Components.SubmittedUsers do
  use Surface.Component

  prop roommates, :map, required: true
  prop submitted_users, :list, required: true
  prop excluded_users, :list, default: []

  def render(assigns) do
    ~F"""
    <h1 class="text-4xl font-bold text-center">Waiting for others...</h1>
    <div class="flex flex-wrap items-center justify-evenly">
        {#for {user_id, roommate} <- Map.to_list(@roommates)}
          {#if user_id in @submitted_users and user_id not in @excluded_users}
            <div class="px-4 py-4">
              <h1 class="px-4 bg-green-400 rounded-lg shadow-md"> {roommate.name} </h1>
            </div>
          {#elseif user_id not in @excluded_users}
            <div class="px-4 py-4">
              <h1 class="px-4 bg-red-400 rounded-lg shadow-md"> {roommate.name} </h1>
            </div>
          {#else}
          {/if}
        {/for}
      </div>
    """
  end
end
