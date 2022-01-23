import topbar from "topbar"
// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

import Alpine from "alpinejs"
window.Alpine = Alpine
Alpine.start()

import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let userToken = document.querySelector('meta[name="channel_token"]').getAttribute('content')

let Hooks = {}

Hooks.UpdateCanvas = {
  mounted() {

    this.pushEventTo("canvas", "mounted_canvas");
    window.addEventListener("update_canvas", e => {
      this.pushEventTo("canvas", "update_canvas", e.detail);
    });

    function drawCanvas(imageData) {
      var canvas = document.getElementById('canvas');

      if (imageData == "") {
        console.log("cleared");
        var ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        return;
      }

      var img = new window.Image();
      img.addEventListener("load", function () {
        var ctx = canvas.getContext('2d');
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        ctx.drawImage(img, 0, 0);
      });
      img.setAttribute("src", imageData);
    }

    this.handleEvent("canvas_updated", (payload) => drawCanvas(payload.canvas_data))
  }
}


let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken, user_token: userToken },
  hooks: Hooks,
  dom: {
    onBeforeElUpdated(from, to){
      if(from._x_dataStack){ 
        window.Alpine.clone(from, to); 
      }
    }
  },
})


// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
// The latency simulator is enabled for the duration of the browser session.
// Call disableLatencySim() to disable:
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket





// window.onload = () => {
//   const removeElement = ({target}) => {
//     let el = document.getElementById(target.dataset.id);
//     let li = el.parentNode;
//     li.parentNode.removeChild(li);
//   }
//   console.log("hi");
//   set_onclick();
//   function set_onclick() {
//     Array.from(document.querySelectorAll(".remove-form-field"))
//     .forEach(el => {
//       console.log(el)
//       el.onclick = (e) => {
//         removeElement(e);
//       }
//     });
//   }
//   Array.from(document.querySelectorAll(".add-form-field"))
//     .forEach(el => {
//       el.onclick = ({target}) => {
//         let container = document.getElementById(target.dataset.container);
//         let index = container.dataset.index;
//         let newRow = target.dataset.prototype;
//         container.insertAdjacentHTML('beforeend', newRow.replace(/__name__/g, index));
//         container.dataset.index = parseInt(container.dataset.index) + 1;
//         container.querySelectorAll('a.remove-form-field').forEach(el => {
//           el.onclick = (e) => {
//             removeElement(e);
//           }
//         });
//         set_onclick();
//       }
//     });
// };

// assets/js/app.js


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

var timerId;
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

  throttle(updateCanvas, 250);
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