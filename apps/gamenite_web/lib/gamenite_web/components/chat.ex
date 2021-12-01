defmodule GameniteWeb.Components.Chat do
  use Surface.Component

  alias Rooms.Room

  alias Surface.Components.Form
  alias Surface.Components.Form.{Field, TextInput, Submit, Label, ErrorTag}

  prop room, :map, required: true
  prop user_id, :any, required: true
  prop message, :map, required: true

  def render(assigns) do
    ~F"""
      <div class="bg-white pt-4 shadow-md rounded-lg">
        <div class="flex h-96 flex-col-reverse overflow-y-auto">
        {#for roommate_msgs <- Enum.chunk_by(@room.messages, &(&1.user_id))}
          <div class="pb-4">
          <div class="flex flex-col-reverse">
            {#for message <- roommate_msgs}
              {#if message.user_id == @user_id}
                <div class="flex w-full justify-end py-1">
                  <div class="flex w-3/4 justify-end px-4">
                    <h3 class="bg-blurple text-white rounded-lg px-4 text-right">{message.body}</h3>
                  </div>
                </div>
              {#else}
                <div class="flex flex-col-reverse justify-start py-0.5">
                  <div class="flex w-3/4 justify-start px-4">
                    <div>
                      <h3 class="bg-gray-dark text-gray-light text-right rounded-lg px-4">{message.body}</h3>
                    </div>
                  </div>
                </div>
              {/if}
            {/for}
          </div>
          {#if hd(roommate_msgs).user_id != @user_id}
            <h6 class="text-black text-lg px-4 text-left">{Room.fetch_roommate_or_previous_roommate(@room, hd(roommate_msgs).user_id).name}</h6>
          {/if}
          </div>
        {/for}
        </div>

        <Form for={@message} class="rounded-b-lg flex w-full bg-gray-light items-center justify-center py-4" change="validate_message" submit="send" opts={autocomplete: "off"}>
          <div class="w-11/12 px-4">
            <Field name={:body}>
              <TextInput class="bg-opacity-50 bg-black focus:ring-1 focus:ring-blurple focus:bg-white"/>
              <ErrorTag/>
            </Field>
          </div>
          <div class="flex items-center justify-center pr-4">
            <Submit class="btn-blurple">Send</Submit>
          </div>
        </Form>
      </div>
    """
  end
end
