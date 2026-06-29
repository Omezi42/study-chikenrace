const WebSocket = require('ws');
const http = require('http');

const PORT = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    if (req.url === '/api/status') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            online_users: wss.clients.size,
            waiting_users: matchmakingQueue.size
        }));
        return;
    }
    res.writeHead(200);
    res.end('Study Chicken Race Signaling Server is running.');
});
const wss = new WebSocket.Server({ server });

// roomCode -> Map<peerId, WebSocket>
const rooms = new Map();

// Random Matchmaking State
const matchmakingQueue = new Set();
let matchTimer = null;
let soloTimer = null;

wss.on('connection', (ws) => {
    ws.currentRoom = null;
    ws.peerId = null;

    ws.on('message', (messageAsString) => {
        let msg;
        try {
            msg = JSON.parse(messageAsString);
        } catch (e) {
            return;
        }

        switch (msg.type) {
            case 'join': {
                const roomCode = msg.room;
                if (!rooms.has(roomCode)) {
                    rooms.set(roomCode, new Map());
                }
                const room = rooms.get(roomCode);
                
                let assignedId;
                if (room.size === 0) {
                    assignedId = 1;
                } else {
                    assignedId = Math.max(1, ...Array.from(room.keys())) + 1;
                }
                
                ws.currentRoom = roomCode;
                ws.peerId = assignedId;
                room.set(assignedId, ws);
                
                ws.send(JSON.stringify({ type: 'id', id: assignedId }));

                for (const [otherId, otherWs] of room.entries()) {
                    if (otherId !== assignedId) {
                        otherWs.send(JSON.stringify({ type: 'peer_connected', id: assignedId }));
                        ws.send(JSON.stringify({ type: 'peer_connected', id: otherId }));
                    }
                }
                break;
            }

            case 'random_join': {
                matchmakingQueue.add(ws);
                processMatchmaking();
                break;
            }

            case 'message': {
                if (ws.currentRoom && rooms.has(ws.currentRoom)) {
                    const roomPeers = rooms.get(ws.currentRoom);
                    const targetWs = roomPeers.get(msg.id);
                    if (targetWs && targetWs.readyState === WebSocket.OPEN) {
                        targetWs.send(JSON.stringify({
                            type: 'message',
                            id: ws.peerId,
                            data: msg.data
                        }));
                    }
                }
                break;
            }
                
            case 'leave': {
                leaveRoom(ws);
                matchmakingQueue.delete(ws);
                checkQueueEmpty();
                break;
            }
        }
    });

    ws.on('close', () => {
        leaveRoom(ws);
        matchmakingQueue.delete(ws);
        checkQueueEmpty();
    });
});

function checkQueueEmpty() {
    if (matchmakingQueue.size < 2 && matchTimer) {
        clearTimeout(matchTimer);
        matchTimer = null;
    }
    if (matchmakingQueue.size < 1 && soloTimer) {
        clearTimeout(soloTimer);
        soloTimer = null;
    }
}

function leaveRoom(ws) {
    if (ws.currentRoom && rooms.has(ws.currentRoom)) {
        const room = rooms.get(ws.currentRoom);
        room.delete(ws.peerId);
        
        for (const [otherId, otherWs] of room.entries()) {
            if (otherWs.readyState === WebSocket.OPEN) {
                otherWs.send(JSON.stringify({ type: 'peer_disconnected', id: ws.peerId }));
            }
        }
        
        if (room.size === 0) {
            rooms.delete(ws.currentRoom);
        }
    }
    ws.currentRoom = null;
    ws.peerId = null;
}

function processMatchmaking() {
    if (matchmakingQueue.size >= 4) {
        createMatch(4);
    } else if (matchmakingQueue.size >= 1) {
        if (!matchTimer && matchmakingQueue.size >= 2) {
            matchTimer = setTimeout(() => {
                matchTimer = null;
                if (matchmakingQueue.size >= 2) {
                    createMatch(Math.min(4, matchmakingQueue.size));
                }
            }, 25000);
        }
        if (!soloTimer) {
            soloTimer = setTimeout(() => {
                soloTimer = null;
                if (matchmakingQueue.size >= 1) {
                    createMatch(Math.min(4, matchmakingQueue.size));
                }
            }, 35000);
        }
    }
}

function createMatch(playerCount) {
    if (matchTimer) {
        clearTimeout(matchTimer);
        matchTimer = null;
    }
    if (soloTimer) {
        clearTimeout(soloTimer);
        soloTimer = null;
    }

    const roomCode = 'RND' + Math.floor(Math.random() * 100000);
    rooms.set(roomCode, new Map());
    const room = rooms.get(roomCode);
    
    let assignedId = 1;
    const matchedPeers = [];
    for (const ws of matchmakingQueue) {
        if (assignedId > playerCount) break;
        
        ws.currentRoom = roomCode;
        ws.peerId = assignedId;
        room.set(assignedId, ws);
        matchmakingQueue.delete(ws);
        matchedPeers.push(ws);
        assignedId++;
    }
    
    for (const ws of matchedPeers) {
        ws.send(JSON.stringify({ type: 'id', id: ws.peerId }));
        ws.send(JSON.stringify({ type: 'room_joined', room: roomCode, match_count: matchedPeers.length }));
        
        for (const other of matchedPeers) {
            if (other.peerId !== ws.peerId) {
                ws.send(JSON.stringify({ type: 'peer_connected', id: other.peerId }));
            }
        }
    }
    
    if (matchmakingQueue.size >= 2) {
        processMatchmaking();
    }
}

server.listen(PORT, () => {
    console.log(`Signaling server listening on port ${PORT}`);
});
