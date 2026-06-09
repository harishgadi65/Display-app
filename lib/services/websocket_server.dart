import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum WsMessageType { startGame, moveLeft, moveRight, unknown }

class WsMessage {
  final WsMessageType type;
  WsMessage(this.type);

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'start_game':
        return WsMessage(WsMessageType.startGame);
      case 'move_left':
        return WsMessage(WsMessageType.moveLeft);
      case 'move_right':
        return WsMessage(WsMessageType.moveRight);
      default:
        return WsMessage(WsMessageType.unknown);
    }
  }
}

class WebSocketServer {
  static final WebSocketServer _instance = WebSocketServer._();
  factory WebSocketServer() => _instance;
  WebSocketServer._();

  HttpServer? _server;
  WebSocket? _clientSocket;
  int port = 8765;

  final _messageController = StreamController<WsMessage>.broadcast();
  Stream<WsMessage> get messages => _messageController.stream;

  bool get hasClient => _clientSocket != null;

  Future<String?> start() async {
    try {
      await stop();
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _listen();
      return await _getLocalIp();
    } catch (e) {
      return null;
    }
  }

  void _listen() async {
    await for (final request in _server!) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final socket = await WebSocketTransformer.upgrade(request);
        _clientSocket?.close();
        _clientSocket = socket;
        socket.listen(
          (data) {
            try {
              final json = jsonDecode(data as String) as Map<String, dynamic>;
              _messageController.add(WsMessage.fromJson(json));
            } catch (_) {}
          },
          onDone: () {
            if (_clientSocket == socket) _clientSocket = null;
          },
          cancelOnError: true,
        );
      } else {
        _serveControlPage(request);
      }
    }
  }

  void _serveControlPage(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write(_mobileControlHtml())
      ..close();
  }

  String _mobileControlHtml() => '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Blink Board Controller</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{background:#050516;color:#fff;font-family:system-ui,sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;gap:24px;padding:24px}
h1{color:#00e5ff;font-size:28px;letter-spacing:4px;font-weight:900}
p{color:#ffffff88;font-size:14px;text-align:center}
#status{font-size:13px;padding:8px 16px;border-radius:20px;border:1px solid #333}
.connected{background:#00ff8820;border-color:#00ff88!important;color:#00ff88}
.disconnected{background:#ff174420;border-color:#ff1744!important;color:#ff1744}
#controls{display:flex;gap:16px;flex-direction:column;width:100%;max-width:320px}
.btn{padding:28px;font-size:20px;font-weight:bold;border:none;border-radius:16px;cursor:pointer;letter-spacing:2px;touch-action:manipulation;-webkit-tap-highlight-color:transparent;user-select:none}
.btn-start{background:linear-gradient(135deg,#7c3aed,#00e5ff);color:#fff;font-size:22px;letter-spacing:3px}
.btn-row{display:flex;gap:16px}
.btn-left,.btn-right{flex:1;background:#0d0d2b;border:2px solid #00e5ff;color:#00e5ff;font-size:32px}
.btn-left:active,.btn-right:active{background:#00e5ff20;transform:scale(0.95)}
.btn-start:active{opacity:0.85;transform:scale(0.97)}
#score-display{font-size:36px;font-weight:900;color:#fff;letter-spacing:2px}
#score-label{color:#ffffff55;font-size:13px;letter-spacing:3px}
</style>
</head>
<body>
<h1>BLINK BOARD</h1>
<span id="status" class="disconnected">Connecting...</span>
<div id="score-label">SCORE</div>
<div id="score-display">00000</div>
<div id="controls">
  <button class="btn btn-start" id="startBtn" onclick="startGame()">▶ START GAME</button>
  <div class="btn-row">
    <button class="btn btn-left" id="leftBtn" ontouchstart="move('left')" onmousedown="move('left')">◀</button>
    <button class="btn btn-right" id="rightBtn" ontouchstart="move('right')" onmousedown="move('right')">▶</button>
  </div>
</div>
<p>Tap ◀ ▶ to move your character<br>Avoid obstacles to score!</p>
<script>
var ws;
var connected=false;
var host=location.hostname+':${port}';
function connect(){
  ws=new WebSocket('ws://'+host);
  ws.onopen=function(){
    connected=true;
    document.getElementById('status').textContent='Connected';
    document.getElementById('status').className='connected';
  };
  ws.onclose=function(){
    connected=false;
    document.getElementById('status').textContent='Disconnected - Reconnecting...';
    document.getElementById('status').className='disconnected';
    setTimeout(connect,2000);
  };
  ws.onmessage=function(e){
    var msg=JSON.parse(e.data);
    if(msg.type==='score_update'){
      document.getElementById('score-display').textContent=String(msg.score).padStart(5,'0');
    } else if(msg.type==='game_over'){
      document.getElementById('score-display').textContent=String(msg.score).padStart(5,'0');
      document.getElementById('startBtn').textContent='▶ PLAY AGAIN';
    }
  };
}
function send(obj){if(connected && ws.readyState===1)ws.send(JSON.stringify(obj));}
function startGame(){send({type:'start_game'});}
function move(dir){send({type:'move_'+dir});}
connect();
</script>
</body>
</html>''';

  void sendGameOver(int score) {
    _clientSocket?.add(jsonEncode({'type': 'game_over', 'score': score}));
  }

  void sendScoreUpdate(int score) {
    _clientSocket?.add(jsonEncode({'type': 'score_update', 'score': score}));
  }

  Future<String?> _getLocalIp() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (!addr.isLoopback) return addr.address;
      }
    }
    return null;
  }

  Future<void> stop() async {
    await _clientSocket?.close();
    await _server?.close(force: true);
    _clientSocket = null;
    _server = null;
  }

  void dispose() {
    stop();
    _messageController.close();
  }
}
