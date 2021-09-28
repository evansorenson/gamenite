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
import "phoenix_html"
import {Socket} from "phoenix"
import topbar from "topbar"
import {LiveSocket} from "phoenix_live_view"

var localStream

async function initStream() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({audio: true, video: true, width: "1280"})
    localStream = stream;
    document.getElementById("local-video").srcObject = stream
  } catch (e) {
    console.log(e)
  }
}

let Hooks = {}
Hooks.JoinCall = {
  mounted () {
    initStream()
  }
}

Hooks.InitUser = {
  mounted () {
    addUserConnection(this.el.dataset.username)
  },

  destroyed () {
    removeUserConnection(this.el.dataset.username)
  }
}

Hooks.HandleOfferRequest = {
  mounted() {
    let fromUser = this.el.dataset.fromUsername
    console.log("new offer request from", fromUser)
    createPeerConnection(this, fromUser)
  }
}

Hooks.HandleIceCandidateOffer = {
  mounted () {
    let data = this.el.dataset
    let fromUser = data.fromUsername
    let iceCandidate = JSON.parse(data.iceCandidate)
    let peerConnection = users[fromUser].peerConnection

    console.log("new ice candidate from", fromUser, iceCandidate)

    peerConnection.addIceCandidate(iceCandidate)
  }
}

Hooks.HandleSdpOffer = {
  mounted () {
    let data = this.el.dataset
    let fromUser = data.fromUsername
    let sdp = data.sdp

    if (sdp != "") {
      console.log("new sdp OFFER from", data.fromUsername, data.sdp)

      createPeerConnection(this, fromUser, sdp)
    }
  }
}

Hooks.HandleAnswer = {
  mounted () {
    let data = this.el.dataset
    let fromUser = data.fromUsername
    let sdp = data.sdp
    let peerConnection = users[fromUser].peerConnection

    if (sdp != "") {
      console.log("new sdp ANSWER from", fromUser, sdp)
      peerConnection.setRemoteDescription({type: "answer", sdp: sdp})
    }
  }
}

var users = {}

function addUserConnection(username) {
  if (users[username] === undefined) {
    users[username] = {
      peerConnection: null
    }
  }
  
  return users
}

function removeUserConnection(username) {
  delete users[username]

  return users
}

// lv       - Our LiveView hook's `this` object.
// fromUser - The user to create the peer connection with.
// offer    - Stores an SDP offer if it was passed to the function.
function createPeerConnection(lv, fromUser, offer) {
  // Creates a variable for our peer connection to reference within
  // this function's scope.
  let newPeerConnection = new RTCPeerConnection({
    iceServers: [
      { urls: "stun:myserver.com:3478" }
    ]
  })

  console.log(fromUser)
  console.log(users)
  // Add this new peer connection to our `users` object.
  users[fromUser].peerConnection = newPeerConnection;

  // Add each local track to the RTCPeerConnection.
  localStream.getTracks().forEach(track => newPeerConnection.addTrack(track, localStream))

  // If creating an answer, rather than an initial offer.
  if (offer !== undefined) {
    newPeerConnection.setRemoteDescription({type: "offer", sdp: offer})
    newPeerConnection.createAnswer()
      .then((answer) => {
        newPeerConnection.setLocalDescription(answer)
        console.log("Sending this ANSWER to the requester:", answer)
        lv.pushEvent("new_answer", {toUser: fromUser, description: answer})
      })
      .catch((err) => console.log(err))
  }

  newPeerConnection.onicecandidate = async ({candidate}) => {
    // fromUser is the new value for toUser because we're sending this data back
    // to the sender
    lv.pushEvent("new_ice_candidate", {toUser: fromUser, candidate})
  }

  // Don't add the `onnegotiationneeded` callback when creating an answer due to
  // a bug in Chrome's implementation of WebRTC.
  if (offer === undefined) {
    newPeerConnection.onnegotiationneeded = async () => {
      try {
        newPeerConnection.createOffer()
          .then((offer) => {
            newPeerConnection.setLocalDescription(offer)
            console.log("Sending this OFFER to the requester:", offer)
            lv.pushEvent("new_sdp_offer", {toUser: fromUser, description: offer})
          })
          .catch((err) => console.log(err))
      }
      catch (error) {
        console.log(error)
      }
    }
  }

  // When the data is ready to flow, add it to the correct video.
  newPeerConnection.ontrack = async (event) => {
    console.log("Track received:", event)
    document.getElementById(`video-remote-${fromUser}`).srcObject = event.streams[0]
  }

  return newPeerConnection;
}


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

// import Alpine from 'alpinejs'
// window.Alpine = Alpine
// Alpine.start()

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket('/live', Socket, {
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.__x) {
        window.Alpine.clone(from.__x, to)
      }
    }
  },
  params: {
    _csrf_token: csrfToken
  },
  hooks: Hooks
})

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
