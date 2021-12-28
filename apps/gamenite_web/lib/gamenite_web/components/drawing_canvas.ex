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
          var canvas= document.getElementById('canvas');
          var rect = canvas.getBoundingClientRect(); // abs. size of element
          var scaleX = canvas.width / rect.width; // relationship bitmap vs. element for X
          var scaleY = canvas.height / rect.height;  // relationship bitmap vs. element for Y

          return {x: (event.clientX - rect.left) * scaleX, y: (event.clientY - rect.top) * scaleY}
        }

        function mouseDown(e, drawing_type, color) {
          ctx = get_canvas_ref();
          if (drawing_type == 'fill') {
            ctx.beginPath();
            ctx.fillStyle = color;
            ctx.fill();
            return;
          }
          else if (drawing_type == 'eraser') {
            ctx.globalCompositeOperation = 'destination-out';
          }
          else {
            ctx.globalCompositeOperation = 'source-over';
          }
          let {x, y} = getMousePos(e);

          ctx.beginPath();
          ctx.moveTo(x, y);
        }

        function mouseUp() {
          ctx = get_canvas_ref();
          ctx.closePath();
        }

        function draw(e, down, color) {
          console.log(color);
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
