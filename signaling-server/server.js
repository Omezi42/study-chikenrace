const WebSocket = require('ws');
const http = require('http');

const PORT = process.env.PORT || 9080;
const server = http.createServer((req, res) => {
    res.writeHead(200);
    res.end('Study Chicken Race Signaling Server is running.');
});
const wss = new WebSocket.Server({ server });

// roomCode -> Map<peerId, WebSocket>
const rooms = new Map();
let nextPeerId = 1;

wss.on('connection', (ws) => {
    let currentRoom = null;
    let peerId = nextPeerId++;
    
    // We send an initial ID just in case, but Godot uses 1 for host.
    // However, Godot WebRTCMultiplayerPeer needs to know its unique ID.
    // Wait, Godot's WebRTCMultiplayerPeer typically assigns 1 to the host.
    // In our case, the host will create the room and get ID 1.
    // Guests will get ID > 1.
    
    ws.on('message', (messageAsString) => {
        let msg;
        try {
            msg = JSON.parse(messageAsString);
        } catch (e) {
            return;
        }

        switch (msg.type) {
            case 'join':
                const roomCode = msg.room;
                if (!rooms.has(roomCode)) {
                    rooms.set(roomCode, new Map());
                }
                const room = rooms.get(roomCode);
                
                // If it's the first peer, assign ID 1 (Host)
                if (room.size === 0) {
                    peerId = 1;
                } else {
                    // Assign a new ID > 1
                    peerId = Math.max(1, ...Array.from(room.keys())) + 1;
                }
                
                currentRoom = roomCode;
                room.set(peerId, ws);
                
                // Tell the client its assigned ID
                ws.send(JSON.stringify({ type: 'id', id: peerId }));

                // Notify others in the room that this peer joined
                for (const [otherId, otherWs] of room.entries()) {
                    if (otherId !== peerId) {
                        otherWs.send(JSON.stringify({ type: 'peer_connected', id: peerId }));
                        ws.send(JSON.stringify({ type: 'peer_connected', id: otherId }));
                    }
                }
                break;

            case 'message':
                // msg.id is the target peer ID
                // msg.data is the payload (SDP or ICE)
                if (currentRoom && rooms.has(currentRoom)) {
                    const roomPeers = rooms.get(currentRoom);
                    const targetWs = roomPeers.get(msg.id);
                    if (targetWs && targetWs.readyState === WebSocket.OPEN) {
                        targetWs.send(JSON.stringify({
                            type: 'message',
                            id: peerId, // sender ID
                            data: msg.data
                        }));
                    }
                }
                break;
                
            case 'leave':
                leaveRoom(ws, currentRoom, peerId);
                currentRoom = null;
                break;
        }
    });

    ws.on('close', () => {
        leaveRoom(ws, currentRoom, peerId);
    });
});

function leaveRoom(ws, roomCode, peerId) {
    if (roomCode && rooms.has(roomCode)) {
        const room = rooms.get(roomCode);
        room.delete(peerId);
        
        // Notify remaining peers
        for (const [otherId, otherWs] of room.entries()) {
            if (otherWs.readyState === WebSocket.OPEN) {
                otherWs.send(JSON.stringify({ type: 'peer_disconnected', id: peerId }));
            }
        }
        
        // Cleanup empty rooms
        if (room.size === 0) {
            rooms.delete(roomCode);
        }
    }
}

server.listen(PORT, () => {
    console.log(`Signaling server listening on port ${PORT}`);
});
