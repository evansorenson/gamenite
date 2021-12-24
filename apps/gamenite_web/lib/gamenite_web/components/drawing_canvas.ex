defmodule GameniteWeb.Components.DrawingCanvas do
  use Surface.LiveComponent

  prop(user_id, :any, required: true)
  prop(drawing_user_id, :any, required: true)
  prop(phrase_to_draw, :string, required: true)

  def render(assigns) do
    ~F"""

    <div x-data="{ down: false }">
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

        function mouseDown(e, fill) {
          if (fill) {
            //floodFill(event, canvasRef.current, ctxRef.current, brushColor);
            //dispatch({ type: HANDLE_CANVAS_UPDATE, payload: canvasRef?.current?.toDataURL() });
            return;
          }
          let {x, y} = getMousePos(e);

          ctx = get_canvas_ref();
          ctx.beginPath();
          ctx.moveTo(x, y);
        }

        function mouseUp() {
          ctx = get_canvas_ref();
          ctx.closePath();
        }

        function draw(e, down) {
          if (!down) return;

          ctx = get_canvas_ref();

          let {x, y} = getMousePos(e);
          ctx.lineTo(x, y);
          ctx.fillStyle = "#FF0000";
          ctx.lineWidth = 1;
          ctx.stroke();
        }

        function clear() {
          ctx = get_canvas_ref();
          ctx.clearRect(0, 0, canvas.width, canvas.height);
        }
      </script>

      <canvas id="canvas" class="h-full w-full bg-white" @mouseup="down = false; mouseUp()" @mousedown="down = true; mouseDown($event, false)" @mousemove="draw($event, down)"/>
      <div>
      </div>
    </div>
    """
  end
end
