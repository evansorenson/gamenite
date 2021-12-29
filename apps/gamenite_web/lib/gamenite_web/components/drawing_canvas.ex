defmodule GameniteWeb.Components.DrawingCanvas do
  use Surface.LiveComponent

  prop user_id, :any, required: true
  prop drawing_user_id, :any, required: true
  prop phrase_to_draw, :string, required: true

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

  def render(assigns) do
    ~F"""
    <div x-data="{ down: false, color: '#000000', brush_width: 1, drawing_type: 'pen' }">
      <script>
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

        function mouseDown(e, drawing_type, color) {
          var canvas = document.getElementById('canvas');
          var ctx = get_canvas_ref();
          let {x, y} = getMousePos(e);

          if (drawing_type == 'fill') {
            const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
            floodFill(imageData, hexToRGB(color), Math.round(x), Math.round(y));
            ctx.putImageData(imageData, 0, 0);
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
        }

        function clear() {
          ctx = get_canvas_ref();
          ctx.clearRect(0, 0, canvas.width, canvas.height);
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

      <canvas id="canvas" class="h-full w-full bg-white" @mouseup="down = false; mouseUp()" @mousedown="if ($store.drawing_type != 'fill') { down = true; } mouseDown($event, $store.drawing_type, $store.color);" @mousemove="draw($event, down, $store.color, $store.brush_width)"/>
      <div class="flex space-x-4 justify-center items-center">

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
            <div class="flex justify-center items-center pt-2">
              <svg class="h-14 w-14" version="1.1" viewBox="0 0 700 700" :stroke="drawing_type == 'fill' ? '#FFFFFF' : '#000000'" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
                <g>
                  <path  d="m292.32 41.441v101.92l-159.04 159.04c-8.8906 8.9219-13.887 21.004-13.887 33.602s4.9961 24.68 13.887 33.602l116.48 116.48c8.9219 8.8945 21.004 13.887 33.598 13.887 12.598 0 24.68-4.9922 33.602-13.887l190.96-190.96-182-182.56v-71.117zm30.801 231.28v-0.003906c0 5.6641-3.4102 10.77-8.6445 12.938-5.2305 2.1641-11.254 0.96875-15.258-3.0352s-5.1992-10.027-3.0312-15.258c2.1641-5.2305 7.2695-8.6445 12.934-8.6445 3.7109 0 7.2734 1.4766 9.8984 4.1016s4.1016 6.1875 4.1016 9.8984zm137.76 21.84-167.44 167.44c-2.7109 2.6016-6.3242 4.0547-10.082 4.0547s-7.3672-1.4531-10.078-4.0547l-116.48-116.48c-2.7383-2.6367-4.2852-6.2773-4.2852-10.078 0-3.8047 1.5469-7.4414 4.2852-10.082l135.52-134.4v37.52c-14.012 5.2852-24.723 16.859-28.906 31.238-4.1836 14.383-1.3555 29.891 7.6367 41.871 8.9883 11.977 23.094 19.027 38.07 19.027 14.977 0 29.078-7.0508 38.07-19.027 8.9883-11.98 11.816-27.488 7.6328-41.871-4.1836-14.379-14.891-25.953-28.902-31.238v-68.32z"/>
                  <path  stroke-width="2" d="m564.48 404.32v-1.1211l-1.6797-2.2383-45.922-58.801-45.359 58.801-1.6797 2.2383v1.1211c-10.777 13.32-16.473 30.039-16.062 47.172 0.41016 17.129 6.8984 33.559 18.301 46.348 11.594 13.234 28.328 20.824 45.922 20.824s34.328-7.5898 45.922-20.824c11.164-12.992 17.352-29.527 17.453-46.656s-5.8867-33.738-16.895-46.863zm-26.879 70.559c-5.2148 6.1992-12.902 9.7773-21 9.7773-8.1016 0-15.789-3.5781-21-9.7773-5.8984-6.7969-9.2344-15.441-9.4414-24.438-0.20312-8.9961 2.7383-17.781 8.3203-24.84h1.1211l2.8008-3.3594 18.477-24.641 18.48 24.078 2.8008 3.3594v0.5625c5.6562 6.9922 8.6992 15.742 8.5977 24.738-0.10547 8.9961-3.3438 17.676-9.1562 24.539z"/>
                </g>
              </svg>
              <!-- Bucket by juli from NounProject.com -->
            </div>
          </button>
          <button :class="drawing_type == 'eraser' ? 'bg-blurple' : 'bg-white'" class="h-16 w-16 border-0 shadow-md" @click="drawing_type = 'eraser'; $store.drawing_type = 'eraser';">
            <svg class="h-14 w-14"  version="1.1" viewBox="0 0 700 700" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
            <g>
              <path d="m480.44 234.52-84.965-84.965c-6.5508-6.5508-17.203-6.5508-23.754 0l-149.84 149.84c-10.914 10.902-10.977 28.629 0 39.602l69.121 69.121c10.902 10.914 28.629 10.977 39.602 0l149.84-149.84c6.5469-6.5508 6.5469-17.211-0.003906-23.758zm-157.76 165.68c-6.5508 6.5508-17.207 6.5508-23.762 0l-69.121-69.117c-6.5508-6.5508-6.5508-17.207 0-23.762l19.398-19.402 92.883 92.883zm149.84-149.84-122.52 122.52-92.883-92.883 122.52-122.52c2.1992-2.1836 5.7188-2.1836 7.918 0l84.965 84.965c2.1836 2.1992 2.1836 5.7188 0 7.918z"/>
            </g>
            </svg>
          <!-- Eraser by Setyo Ari Wibowo from NounProject.com -->
          </button>
        </div>

        <div class="flex">
          <button :class="brush_width == 1 ? 'bg-blurple' : 'bg-white'" @click="brush_width = 1; $store.brush_width = 1;">1</button>
          <button :class="brush_width == 2 ? 'bg-blurple' : 'bg-white'" @click="brush_width = 2; $store.brush_width = 2;">2</button>
          <button :class="brush_width == 4 ? 'bg-blurple' : 'bg-white'" @click="brush_width = 4; $store.brush_width = 4;">4</button>
          <button :class="brush_width == 8 ? 'bg-blurple' : 'bg-white'" @click="brush_width = 8; $store.brush_width = 8;">8</button>
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
