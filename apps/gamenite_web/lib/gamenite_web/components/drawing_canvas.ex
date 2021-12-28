defmodule GameniteWeb.Components.DrawingCanvas do
  use Surface.LiveComponent

  prop user_id, :any, required: true
  prop drawing_user_id, :any, required: true
  prop phrase_to_draw, :string, required: true

  prop canvas_hex_colors, :list,
    default: [
      "000000",
      "FFFFFF",
      "964B00",
      "FF0000",
      "FF9900",
      "FFFF00",
      "00FF00",
      "00FFFF",
      "0000FF",
      "9900FF",
      "FF00FF"
    ]

  def render(assigns) do
    ~F"""
    <div x-data="{ down: false }" data-color="'#000000'" data-drawing-type="pen">
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

        function draw(e, down, color) {
          if (!down) return;

          ctx = get_canvas_ref();

          let {x, y} = getMousePos(e);
          ctx.lineTo(x, y);
          ctx.fillStyle = color;
          ctx.strokeStyle = color;
          ctx.lineWidth = 1;
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
          console.log(x, y);
          const baseColor = getColorAtPixel(imageData, x, y);
          console.log(baseColor);
          let operator = { x, y };
          // Check if base color and new color are the same
          if (colorMatch(baseColor, newColor)) return;
          console.log(newColor);

          // Add the clicked location to stack
          stack.push({ x: operator.x, y: operator.y });

          while (stack.length) {
            console.log(stack.length);
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

      <canvas id="canvas" class="h-full w-full bg-white" @mouseup="down = false; mouseUp()" @mousedown="if ($root.dataset.drawing_type != 'fill') { down = true; } mouseDown($event, $root.dataset.drawing_type, $root.dataset.color)" @mousemove="draw($event, down, $root.dataset.color)"/>
      <div class="flex">
        {#for color <- @canvas_hex_colors}
          <button style={"background-color:##{color}"} class="h-12 w-12 border-0 rounded-none" @click={"$root.dataset.color = '##{color}'; $root.dataset.drawing_type = 'pen'"}></button>
        {/for}

        <button @click="$root.dataset.drawing_type = 'fill'">Fill</button>
        <button @click="$root.dataset.drawing_type = 'eraser'">Eraser</button>


        <button @click="clear()">Clear</button>
      </div>
    </div>
    """
  end
end
