// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"
import 'regenerator-runtime/runtime'

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import topbar from "topbar"


let Hooks = {}

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())



window.onload = () => {
  const removeElement = ({target}) => {
    let el = document.getElementById(target.dataset.id);
    let li = el.parentNode;
    li.parentNode.removeChild(li);
  }
  console.log("hi");
  set_onclick();
  function set_onclick() {
    Array.from(document.querySelectorAll(".remove-form-field"))
    .forEach(el => {
      console.log(el)
      el.onclick = (e) => {
        removeElement(e);
      }
    });
  }
  Array.from(document.querySelectorAll(".add-form-field"))
    .forEach(el => {
      el.onclick = ({target}) => {
        let container = document.getElementById(target.dataset.container);
        let index = container.dataset.index;
        let newRow = target.dataset.prototype;
        container.insertAdjacentHTML('beforeend', newRow.replace(/__name__/g, index));
        container.dataset.index = parseInt(container.dataset.index) + 1;
        container.querySelectorAll('a.remove-form-field').forEach(el => {
          el.onclick = (e) => {
            removeElement(e);
          }
        });
        set_onclick();
      }
    });
};

// assets/js/app.js
import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Connect if there are any LiveViews on the page
liveSocket.connect()

// Expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
// The latency simulator is enabled for the duration of the browser session.
// Call disableLatencySim() to disable:
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

