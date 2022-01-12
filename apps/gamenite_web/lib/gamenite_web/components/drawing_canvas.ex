defmodule GameniteWeb.Components.DrawingCanvas do
  use Surface.LiveComponent

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

  def handle_event("update_canvas", canvas_data_url, socket) do
    Gamenite.SaladBowl.API.update_canvas(socket.assigns.slug, canvas_data_url)
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
    <div x-init="initCanvas()" x-data="{ down: false, color: '#000000', brush_width: 1, drawing_type: 'pen' }" phx-hook="UpdateCanvas">
      <script>

        function initCanvas() {
          var canvas= document.getElementById('canvas');

          canvas.addEventListener("canvas_updated", e => {
            console.log("hallelujah");
          })
        }

        function get_canvas_ref() {
          var canvas= document.getElementById('canvas');
          var ctx = canvas.getContext('2d');

          return ctx;
        }

        function  getMousePos(event) {
          var canvas = document.getElementById('canvas');
          var rect = canvas.getBoundingClientRect(); // abs. size of element
          var scaleX = canvas.width / rect.width; // relationship bitmap vs. element for X
          var scaleY = canvas.height / rect.height;  // relationship bitmap vs. element for Y

          return {x: (event.clientX - rect.left) * scaleX, y: (event.clientY - rect.top) * scaleY}
        }

        // Throttle function: Input as function which needs to be throttled and delay is the time interval in milliseconds
        function throttle(func, delay) {
          // If setTimeout is already scheduled, no need to do anything
          if (timerId) {
            return
          }

          // Schedule a setTimeout after delay seconds
          timerId  =  setTimeout(function () {
            func()

            // Once setTimeout function execution is finished, timerId = undefined so that in <br>
            // the next scroll event function execution can be scheduled by the setTimeout
            timerId  =  undefined;
          }, delay)
        }


        function updateCanvas() {
          var canvas = document.getElementById('canvas');
          var ctx = get_canvas_ref();

          imageData =  ctx.getImageData(0, 0, canvas.width, canvas.height);
          window.dispatchEvent(new CustomEvent('update_canvas', { detail: canvas.toDataURL()}));
        }

        function mouseDown(e, drawing_type, color) {
          var canvas = document.getElementById('canvas');
          var ctx = get_canvas_ref();
          let {x, y} = getMousePos(e);

          if (drawing_type == 'fill') {
            const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
            floodFill(imageData, hexToRGB(color), Math.round(x), Math.round(y));
            ctx.putImageData(imageData, 0, 0);
            updateCanvas();
            return;
          }
          else if (drawing_type == 'eraser') {
            ctx.globalCompositeOperation = 'destination-out';
          }
          else {
            ctx.globalCompositeOperation = 'source-over';
          }

          ctx.beginPath();
          ctx.moveTo(x, y);
        }

        function mouseUp() {
          ctx = get_canvas_ref();
          ctx.closePath();
        }

        function draw(e, down, color, brushWidth) {
          if (!down) return;

          ctx = get_canvas_ref();

          let {x, y} = getMousePos(e);
          ctx.lineTo(x, y);
          ctx.lineWidth = brushWidth;
          ctx.lineCap = 'round';
          ctx.strokeStyle = color;
          ctx.stroke();


          updateCanvas(ctx);
        }

        function clear() {
          ctx = get_canvas_ref();
          ctx.clearRect(0, 0, canvas.width, canvas.height);
          updateCanvas();
        }

        // Canvas flood fill, taken from: https://codepen.io/Geeyoam/pen/vLGZzG
        function getColorAtPixel(imageData, x, y) {
          const { width, data } = imageData;

          return {
            r: data[4 * (width * y + x) + 0],
            g: data[4 * (width * y + x) + 1],
            b: data[4 * (width * y + x) + 2],
            a: data[4 * (width * y + x) + 3]
          };
        }

        function loadCanvas(strDataURI) {
          ctx = get_canvas_ref();
          var img = new Image;
          img.onload = function(){
            ctx.drawImage(img,0,0); // Or at whatever offset you like
          };
          img.src = strDataURI;
        }

        function setColorAtPixel(imageData, color, x, y) {
          const { width, data } = imageData;

          data[4 * (width * y + x) + 0] = color.r & 0xff;
          data[4 * (width * y + x) + 1] = color.g & 0xff;
          data[4 * (width * y + x) + 2] = color.b & 0xff;
          data[4 * (width * y + x) + 3] = color.a & 0xff;
        }

        function colorMatch(a, b) {
          return a.r === b.r && a.g === b.g && a.b === b.b && a.a === b.a;
        }

        function floodFill(imageData, newColor, x, y) {
          const { width, height } = imageData;

          const stack = [];
          const baseColor = getColorAtPixel(imageData, x, y);
          let operator = { x, y };
          // Check if base color and new color are the same
          if (colorMatch(baseColor, newColor)) return;

          // Add the clicked location to stack
          stack.push({ x: operator.x, y: operator.y });

          while (stack.length) {
            operator = stack.pop();
            let contiguousDown = true; // Vertical is assumed to be true
            let contiguousUp = true; // Vertical is assumed to be true
            let contiguousLeft = false;
            let contiguousRight = false;

            // Move to top most contiguousDown pixel
            while (contiguousUp && operator.y >= 0) {
              operator.y--;
              contiguousUp = colorMatch(getColorAtPixel(imageData, operator.x, operator.y), baseColor);
            }

            // Move downward
            while (contiguousDown && operator.y < height) {
              setColorAtPixel(imageData, newColor, operator.x, operator.y);

              // Check left
              if (operator.x - 1 >= 0 && colorMatch(getColorAtPixel(imageData, operator.x - 1, operator.y), baseColor)) {
                if (!contiguousLeft) {
                  contiguousLeft = true;
                  stack.push({ x: operator.x - 1, y: operator.y });
                }
              } else {
                contiguousLeft = false;
              }

              // Check right
              if (operator.x + 1 < width && colorMatch(getColorAtPixel(imageData, operator.x + 1, operator.y), baseColor)) {
                if (!contiguousRight) {
                  stack.push({ x: operator.x + 1, y: operator.y });
                  contiguousRight = true;
                }
              } else {
                contiguousRight = false;
              }

              operator.y++;
              contiguousDown = colorMatch(getColorAtPixel(imageData, operator.x, operator.y), baseColor);
            }
          }
        }

        const hexToRGB = (hex) => {
          const r = parseInt(hex.slice(1, 3), 16);
          const g = parseInt(hex.slice(3, 5), 16);
          const b = parseInt(hex.slice(5, 7), 16);

          return { r, g, b, a: 0xff };
        };
      </script>

      <canvas id="canvas" x-init="$store.color = '#000000';" class="h-full w-full bg-white" @mouseup="down = false; mouseUp()" @mousedown="if ($store.drawing_type != 'fill') { down = true; } mouseDown($event, $store.drawing_type, $store.color);" @mousemove="draw($event, down, $store.color, $store.brush_width)"/>
      <div class="flex space-x-4 md:space-x-8 justify-center items-center pt-4">

        <button :style="`background-color: ${color}`" class="h-14 w-14 border-0 rounded-none"/>
        <div class="grid grid-cols-6">
        {#for color <- @canvas_hex_colors}
          <button style={"background-color: #{color}"} class="h-7 w-7 border-0 rounded-none" @click={"color = '#{color}'; $store.color = '#{color}';"}/>
        {/for}
        </div>

        <div class="flex space-x-1">
          <button :class="drawing_type == 'pen' ? 'bg-blurple' : 'bg-white'" class="h-16 w-16 border-0 shadow-md" @click="drawing_type = 'pen'; $store.drawing_type = 'pen';">
            <div class="flex justify-center">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-14 w-14" fill="none" viewBox="0 0 24 24" :stroke="drawing_type == 'pen' ? '#FFFFFF' : '#000000'">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
              </svg>
            </div>
          </button>
          <button :class="drawing_type == 'fill' ? 'bg-blurple' : 'bg-white'" class="h-16 w-16 border-0 shadow-md" @click="drawing_type = 'fill'; $store.drawing_type = 'fill';">
            <div class="flex justify-center items-center">
              <svg class="h-14 w-14" viewBox="0 0 32 32" :stroke="drawing_type == 'fill' ? '#FFFFFF' : '#000000'" xmlns="http://www.w3.org/2000/svg">
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
          <button :class="drawing_type == 'eraser' ? 'bg-blurple' : 'bg-white'" class="h-16 w-16 border-0 shadow-md" @click="drawing_type = 'eraser'; $store.drawing_type = 'eraser';">
            <div class="flex justify-center">
              <svg class="h-14 w-14" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg" :stroke="drawing_type == 'eraser' ? '#FFFFFF' : '#000000'">
                <style type="text/css">.st0{fill:none;stroke-width:2;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:10;}</style>
                <path class="st0" d="M28,12.5c0.8-0.8,0.8-2,0-2.8L22.4,4c-0.8-0.8-2-0.8-2.8,0L5,18.5c-0.8,0.8-0.8,2,0,2.8l3.8,3.8h6.6L28,12.5z"/>
                <line class="st0" x1="12.5" y1="11.1" x2="20.9" y2="19.5"/>
              </svg>
            </div>
          <!-- Icon by Gayrat Muminov on freeicons.io -->
          </button>
        </div>

        <div class="flex space-x-1">
          <button class="h-16 w-16 border-0 shadow-md content-center" :class="brush_width == 1 ? 'bg-blurple' : 'bg-white'" @click="brush_width = 1; $store.brush_width = 1;">
          <div class="flex justify-center">
            <span class="h-2 w-2 bg-black rounded-full inline-block"></span>
            </div>
          </button>
          <button class="h-16 w-16 border-0 shadow-md" :class="brush_width == 2 ? 'bg-blurple' : 'bg-white'" @click="brush_width = 2; $store.brush_width = 2;">
            <div class="flex justify-center">
              <span class="h-4 w-4 bg-black rounded-full inline-block"></span>
            </div>
          </button>
          <button class="h-16 w-16 border-0 shadow-md" :class="brush_width == 4 ? 'bg-blurple' : 'bg-white'" @click="brush_width = 4; $store.brush_width = 4;">
            <div class="flex justify-center">
              <span class="h-8 w-8 bg-black rounded-full inline-block"></span>
            </div>
          </button>
          <button class="h-16 w-16 border-0 shadow-md" :class="brush_width == 8 ? 'bg-blurple' : 'bg-white'" @click="brush_width = 8; $store.brush_width = 8;">
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
    </div>
    """
  end
end
