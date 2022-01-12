defmodule GameniteWeb.Components.SubmittedUsers do
  use Surface.Component

  prop roommates, :map, required: true
  prop submitted_users, :list, required: true
  prop excluded_users, :list, default: []

  def render(assigns) do
    ~F"""
    <div class="flex justify-center">
      <div class="bg-white rounded-xl shadow-lg w-1/2">
        <h1 class="text-4xl font-bold text-center py-4">Waiting for everyone...</h1>
        <div class="flex flex-wrap items-center justify-center space-x-8 pb-4">
            {#for {user_id, roommate} <- Map.to_list(@roommates)}
              {#if user_id in @submitted_users and user_id not in @excluded_users}
                <div class="px-4 py-4">
                  <h1 class="px-4 bg-green-400 font-semibold rounded-lg shadow-md"> {roommate.name} </h1>
                </div>
              {#elseif user_id not in @excluded_users}
                <div class="px-4 py-4">
                  <h1 class="px-4 bg-red-400 font-semibold rounded-lg shadow-md"> {roommate.name} </h1>
                </div>
              {#else}
              {/if}
            {/for}
        </div>
      </div>
    </div>
    """
  end
end
