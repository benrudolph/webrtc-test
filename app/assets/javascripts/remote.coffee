# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

navigator.getUserMedia = navigator.getUserMedia ||
    navigator.webkitGetUserMedia || navigator.mozGetUserMedia

class WebRTC.RemoteMachine
    room: 'webrtc-test'

    rtcConfig:
        iceServers: [
            urls: 'stun:localhost:8888'
        ]

    start: ->
        @socket = io('http://localhost:8888', (socket) =>
            socket.join(@room)
        )
        @socket.emit 'join', @room
        @socket.on 'message', (message) =>
            console.log message
            console.log message.machine
            if message.machine != 'local'
                return
            @peerConnection.setRemoteDescription(message.desc)
                .then(
                    () -> console.log('successfully set remote description'),
                    () -> console.log('failed'),
                )
            @peerConnection.createAnswer()
                .then(
                    (desc) =>
                        console.log 'successfully created answer'
                        console.log(desc)
                        @peerConnection.setLocalDescription desc

                        # Now that we have our answer let's send our desc back to LocalMachine
                        @socket.emit 'message',
                            to: @room
                            desc: desc
                            machine: 'remote'


                )

        @socket.on 'ice', (ice) =>
            console.log 'ice'
            console.log ice.machine
            if ice.machine != 'local'
                return
            @peerConnection.addIceCandidate ice.candidate

        @peerConnection = new RTCPeerConnection @rtcConfig
        @peerConnection.onaddstream = @onReceiveRemoteStream
        @peerConnection.onicecandidate = (e) =>
            console.log 'remote ice'
            @onIceCandidate e

    onIceCandidate: (e) =>
        if e.candidate
            @socket.emit 'ice',
                to: @room
                candidate: e.candidate
                machine: 'remote'

    onReceiveRemoteStream: (e) =>
        console.log 'received remote stream'
        $('#remote')[0].srcObject = e.stream
