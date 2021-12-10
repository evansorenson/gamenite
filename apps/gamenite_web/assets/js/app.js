import topbar from "topbar"
// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// import Alpine from "alpinejs"
// window.Alpine = Alpine
// Alpine.start()

import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let userToken = document.querySelector('meta[name="channel_token"]').getAttribute('content')

let Hooks = {}

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken, user_token: userToken },
  hooks: Hooks,
  // dom: {
  //   onBeforeElUpdated(from, to){
  //     if(from._x_dataStack){ 
  //       window.Alpine.clone(from, to); 
  //     }
  //   }
  // },
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