# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

class WebRTC.LocalMachine

    rtcConfig:
        iceServers: [
            urls: 'stun:localhost:8888'
        ]

    room: 'webrtc-test'

    offerOptions:
        offerToReceiveVideo: 1
        offerToReceiveAudio: 1

    start: =>
        @socket = io('http://localhost:8888')
        @socket.emit 'join', @room

        @socket.on 'message', (message) =>
            console.log 'setting remote desc'
            console.log message.machine
            if message.machine != 'remote'
                return

            @peerConnection.setRemoteDescription message.desc

        @socket.on 'ice', (ice) =>
            console.log 'ice socket'
            console.log ice
            if ice.machine != 'remote'
                return
            @peerConnection.addIceCandidate ice.candidate

        $('#call').click @call

        navigator.mediaDevices.getUserMedia(
            audio: false
            video: true
        ).then @onReceiveStream

    onReceiveStream: (stream) =>
        $('#local-video')[0].srcObject = @stream = stream

    call: =>
        if not @stream
            console.log 'No stream available to call'
            return

        videoTracks = @stream.getVideoTracks()
        # First thing to do is to establish an RTC connection
        @peerConnection = new RTCPeerConnection @rtcConfig
        @peerConnection.onicecandidate = (e) =>
            console.log 'local ice'
            @onIceCandidate e

        @peerConnection.addStream @stream
        @peerConnection.createOffer()
            .then(@onCreateOffer)
            .catch((err) ->
                console.log err
            )

    onCreateOffer: (localDescription) =>
        @peerConnection.setLocalDescription(localDescription)
        @socket.emit('message',
            to: @room
            desc: localDescription
            machine: 'local'
        )

    onIceCandidate: (e) =>
        if e.candidate
            @socket.emit 'ice',
                to: @room
                candidate: e.candidate
                machine: 'local'

