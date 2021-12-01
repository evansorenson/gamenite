import { MEDIA_CONSTRAINTS, LOCAL_PEER_ID } from "./consts";
import {
  addVideoElement,
  removeVideoElement,
  setErrorMessage,
  setParticipantsList,
  attachStream
} from "./room_ui";
import {
  MembraneWebRTC,
  Peer,
  SerializedMediaEvent,
} from "membrane_rtc_engine";
import {LiveSocket, Push} from "phoenix_live_view"
import { parse } from "query-string";

export class Room {
  private peers: Peer[] = [];
  private displayName: string;
  private localStream: MediaStream | undefined;
  private webrtc: MembraneWebRTC;

  private webrtcSocketRefs: string[] = [];
  private webrtcChannel;
  private socket: LiveSocket;

  constructor(socket: LiveSocket, slug: string, user_id: string) {
    this.socket = socket
    this.displayName = user_id;
    this.webrtcChannel = this.socket.channel(`room:${slug}`);

    // this.webrtcSocketRefs.push(this.socket.onError(this.leave));
    // this.webrtcSocketRefs.push(this.socket.onClose(this.leave));

    this.webrtc = new MembraneWebRTC({
      callbacks: {
        onSendMediaEvent: (mediaEvent: SerializedMediaEvent) => {
          this.webrtcChannel.push("mediaEvent", { data: mediaEvent });
        },
        onConnectionError: setErrorMessage,
        onJoinSuccess: (peerId, peersInRoom) => {
          this.localStream!.getTracks().forEach((track) =>
            this.webrtc.addTrack(track, this.localStream!)
          );

          this.peers = peersInRoom;
          this.peers.forEach((peer) => {
            addVideoElement(peer.id, peer.metadata.displayName, false);
          });
        },
        onJoinError: (metadata) => {
          throw `Peer denied.`;
        },
        onTrackReady: ({ stream, peer, metadata }) => {
          attachStream(stream!, peer.id);
        },
        onTrackAdded: (ctx) => {},
        onTrackRemoved: (ctx) => {},
        onPeerJoined: (peer) => {
          this.peers.push(peer);
          addVideoElement(peer.id, peer.metadata.displayName, false);
        },
        onPeerLeft: (peer) => {
          this.peers = this.peers.filter((p) => p.id !== peer.id);
          removeVideoElement(peer.id);
        },
        onPeerUpdated: (ctx) => {},
      },
    });

    this.webrtcChannel.on("mediaEvent", (event) =>
      this.webrtc.receiveMediaEvent(event.data)
    );
  }

  public join = async () => {
    try {
      await this.init();
      this.webrtc.join({ displayName: this.displayName });
    } catch (error) {
      console.error("Error while joining to the room:", error);
    }
  };

  private init = async () => {
    try {
      this.localStream = await navigator.mediaDevices.getUserMedia(
        MEDIA_CONSTRAINTS
      );
    } catch (error) {
      console.error(error);
      setErrorMessage(
        "Failed to setup video room, make sure to grant camera and microphone permissions"
      );
      throw "error";
    }

    addVideoElement(LOCAL_PEER_ID, "Me", true);
    attachStream(this.localStream!, LOCAL_PEER_ID);

    await this.phoenixChannelPushResult(this.webrtcChannel.join(this.displayName));
  };

  private leave = () => {
    this.webrtc.leave();
    this.webrtcChannel.leave();
    this.socket.off(this.webrtcSocketRefs);
    while (this.webrtcSocketRefs.length > 0) {
      this.webrtcSocketRefs.pop();
    }
  };

  private updateParticipantsList = (): void => {
    const participantsNames = this.peers.map((p) => p.metadata.displayName);

    if (this.displayName) {
      participantsNames.push(this.displayName);
    }

  };

  private phoenixChannelPushResult = async (push: Push): Promise<any> => {
    return new Promise((resolve, reject) => {
      push
        .receive("ok", (response: any) => resolve(response))
        .receive("error", (response: any) => reject(response));
    });
  };
}