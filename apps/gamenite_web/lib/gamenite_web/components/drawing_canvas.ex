defmodule GameniteWeb.Components.DrawingCanvas do
  use Surface.LiveComponent

  alias GameniteWeb.Router.Helpers, as: Routes

  alias Phoenix.PubSub

  prop slug, :string, required: true
  prop user_id, :any, required: true
  prop drawing_user_id, :any, required: true
  prop phrase_to_draw, :string, required: true
  prop canvas, :string

  prop canvas_hex_colors, :list,
    default: [
      "#000000",
      "#964B00",
      "#0000FF",
      "#378805",
      "#FF9900",
      "#9900FF",
      "#FFFFFF",
      "#FF0000",
      "#00FFFF",
      "#00FF00",
      "#FFFF00",
      "#FF00FF"
    ]

  def handle_event("update_canvas", canvas_data, socket) do
    Gamenite.SaladBowl.API.update_canvas(
      socket.assigns.slug,
      canvas_data,
      socket.assigns.user_id
    )

    {:noreply, socket}
  end

  def handle_event("mounted_canvas", _params, socket) do
    {:noreply, push_event(socket, "canvas_updated", %{canvas_data: socket.assigns.canvas})}
  end

  def preload([assigns] = list_of_assigns) do
    PubSub.subscribe(Gamenite.PubSub, "canvas_updated:" <> assigns.slug)
    list_of_assigns
  end

  def render(assigns) do
    ~F"""
    <div x-data="window.drawingCanvas" phx-hook="UpdateCanvas">
      {#if @drawing_user_id == @user_id}
      <canvas id="canvas" class="h-full w-full bg-white" @mouseup="window.drawingCanvas.mouseUp()" @mousedown="window.drawingCanvas.mouseDown($event)" @mousemove="window.drawingCanvas.draw($event)"/>
      <div class="flex space-x-4 md:space-x-8 justify-center items-center pt-4">

        <button :style="`background-color: ${color}`" class="h-14 w-14 border-0 rounded-none"/>
        <div class="grid grid-cols-6">
        {#for color <- @canvas_hex_colors}
          <button style={"background-color: #{color}"} class="h-7 w-7 border-0 rounded-none" @click={"color = '#{color}'"}/>
        {/for}
        </div>

        <div class="flex space-x-1">
          <button :class="drawingType == 'pen' ? 'bg-blurple' : 'bg-white'" class="h-16 w-16 border-0 shadow-md" @click="drawingType = 'pen';">
            <div class="flex justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-14 w-14" fill="none" viewBox="0 0 24 24" :stroke="drawingType == 'pen' ? '#FFFFFF' : '#000000'">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
            </div>
          </button>
          <button :class="drawingType == 'fill' ? 'bg-blurple' : 'bg-white'" class="h-16 w-16 border-0 shadow-md" @click="drawingType = 'fill'">
            <div class="flex justify-center items-center">
              <svg class="h-14 w-14" viewBox="0 0 32 32" :stroke="drawingType == 'fill' ? '#FFFFFF' : '#000000'" xmlns="http://www.w3.org/2000/svg">
                <style type="text/css">
                .st0{fill:none;stroke-width:2;stroke-miterlimit:10;}
                .st1{fill:none;stroke-width:2;stroke-linejoin:round;stroke-miterlimit:10;}
                .st2{fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}
                .st3{fill:none;stroke-width:2;stroke-linecap:round;stroke-miterlimit:10;}
                .st4{fill:none;stroke-width:2;stroke-linejoin:round;stroke-miterlimit:10;stroke-dasharray:3;}
                </style>
                <path class="st1" d="M19.1,17.9c-0.7,0.7-1.9,0.7-2.6,0c-0.7-0.7-0.7-1.9,0-2.6c0.7-0.7,1.9-0.7,2.6,0c4.7-4.7,7.4-9.8,5.9-11.2
                  c-0.6-0.6-2-0.5-3.7,0.3"/>
                <path class="st1" d="M7,27c0,1.1-0.9,2-2,2s-2-0.9-2-2s2-3,2-3S7,25.9,7,27z"/>
                <path class="st1" d="M3.6,19.6L3.6,19.6c0.9,0.9,2.3,0.9,3.2,0L19.8,6.7l0,0c-1.1-1.1-2.9-1.1-4,0l-4,4c-2.2,2.2-4.7,4-7.6,5.2l0,0
                  C2.8,16.6,2.5,18.5,3.6,19.6z"/>
                <path class="st1" d="M19.8,6.7L28,16c1.3,1.5,1.2,3.7-0.2,5.1l-5.6,5.6c-1.4,1.4-3.6,1.5-5.1,0.2l-9.3-8.2"/>
              </svg>
              <!-- Icon by www.wishforge.games on freeicons.io -->
            </div>
          </button>
          <button :class="drawingType == 'eraser' ? 'bg-blurple' : 'bg-white'" class="h-16 w-16 border-0 shadow-md" @click="drawingType = 'eraser'">
            <div class="flex justify-center">
              <svg class="h-14 w-14" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg" :stroke="drawingType == 'eraser' ? '#FFFFFF' : '#000000'">
                <style type="text/css">.st0{fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}</style>
                <path class="st0" d="M28,12.5c0.8-0.8,0.8-2,0-2.8L22.4,4c-0.8-0.8-2-0.8-2.8,0L5,18.5c-0.8,0.8-0.8,2,0,2.8l3.8,3.8h6.6L28,12.5z"/>
                <line class="st0" x1="12.5" y1="11.1" x2="20.9" y2="19.5"/>
              </svg>
            </div>
          <!-- Icon by Gayrat Muminov on freeicons.io -->
          </button>
        </div>

        <div class="flex space-x-1">
          <button class="h-16 w-16 border-0 shadow-md content-center" :class="brushWidth == 1 ? 'bg-blurple' : 'bg-white'" @click="brushWidth = 1">
          <div class="flex justify-center">
            <span class="h-2 w-2 bg-black rounded-full inline-block"></span>
            </div>
          </button>
          <button class="h-16 w-16 border-0 shadow-md" :class="brushWidth == 2 ? 'bg-blurple' : 'bg-white'" @click="brushWidth = 2">
            <div class="flex justify-center">
              <span class="h-4 w-4 bg-black rounded-full inline-block"></span>
            </div>
          </button>
          <button class="h-16 w-16 border-0 shadow-md" :class="brushWidth == 4 ? 'bg-blurple' : 'bg-white'" @click="brushWidth = 4">
            <div class="flex justify-center">
              <span class="h-8 w-8 bg-black rounded-full inline-block"></span>
            </div>
          </button>
          <button class="h-16 w-16 border-0 shadow-md" :class="brushWidth == 8 ? 'bg-blurple' : 'bg-white'" @click="brushWidth = 8">
            <div class="flex justify-center">
              <span class="h-12 w-12 bg-black rounded-full inline-block"></span>
            </div>
          </button>
        </div>

        <button class="h-16 w-16 bg-white border-0 shadow-md" @click="clear()">
          <div class="flex justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-14 w-14" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
          </div>
        </button>
      </div>
      {#else}
        <canvas id="canvas" class="h-full w-full bg-white"/>
      {/if}
    </div>
    """
  end
end
