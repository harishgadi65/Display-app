import 'dart:async';
import 'dart:convert';
import 'dart:io';

enum WsMessageType {
  startGame,
  startBurgerGame,
  moveLeft,
  stopMoveLeft,
  moveRight,
  stopMoveRight,
  playAgain,
  unknown,
}

class WsMessage {
  final WsMessageType type;
  WsMessage(this.type);

  factory WsMessage.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'start_game':
        return WsMessage(WsMessageType.startGame);
      case 'start_burger_game':
        return WsMessage(WsMessageType.startBurgerGame);
      case 'move_left':
        return WsMessage(WsMessageType.moveLeft);
      case 'stop_move_left':
        return WsMessage(WsMessageType.stopMoveLeft);
      case 'move_right':
        return WsMessage(WsMessageType.moveRight);
      case 'stop_move_right':
        return WsMessage(WsMessageType.stopMoveRight);
      case 'play_again':
        return WsMessage(WsMessageType.playAgain);
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
          cancelOnError: false,
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
body{background:#050516;color:#fff;font-family:system-ui,sans-serif;display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:100vh;gap:20px;padding:24px}
h1{color:#00e5ff;font-size:28px;letter-spacing:4px;font-weight:900}
#status{font-size:13px;padding:8px 16px;border-radius:20px;border:1px solid #333}
.connected{background:#00ff8820;border-color:#00ff88!important;color:#00ff88}
.disconnected{background:#ff174420;border-color:#ff1744!important;color:#ff1744}
.btn{font-weight:bold;border:none;border-radius:16px;cursor:pointer;letter-spacing:2px;touch-action:manipulation;-webkit-tap-highlight-color:transparent;user-select:none;transition:transform 0.1s,opacity 0.1s}
.btn:active{transform:scale(0.95);opacity:0.85}
#screen-idle{display:flex;flex-direction:column;align-items:center;gap:24px;width:100%;max-width:320px}
.btn-start{background:linear-gradient(135deg,#ff6b00,#ffcc00);color:#050516;font-size:22px;letter-spacing:3px;padding:30px 48px;width:100%}
.idle-hint{color:#ffffff55;font-size:13px;text-align:center}
#screen-playing{display:none;flex-direction:column;align-items:center;gap:20px;width:100%;max-width:320px}
.score-wrap{text-align:center}
.score-label{color:#ffffff55;font-size:12px;letter-spacing:3px}
.score-val{font-size:48px;font-weight:900;color:#fff;letter-spacing:2px;line-height:1}
.btn-row{display:flex;gap:16px;width:100%}
.btn-move{flex:1;background:#0d0d2b;border:2px solid #00e5ff;color:#00e5ff;font-size:48px;padding:36px 0;border-radius:20px}
.btn-move:active{background:#00e5ff30}
.play-hint{color:#ffffff55;font-size:13px;text-align:center}
#screen-gameover{display:none;flex-direction:column;align-items:center;gap:24px;width:100%;max-width:320px}
.gameover-title{font-size:22px;font-weight:900;color:#ff6b00;letter-spacing:3px}
.final-score-label{color:#ffffff55;font-size:12px;letter-spacing:3px}
.final-score-val{font-size:64px;font-weight:900;color:#fff;letter-spacing:2px;line-height:1}
.btn-again{background:linear-gradient(135deg,#7c3aed,#00e5ff);color:#fff;font-size:20px;letter-spacing:3px;padding:28px 48px;width:100%}
</style>
</head>
<body>
<h1>BLINK BOARD</h1>
<span id="status" class="disconnected">Connecting...</span>

<div id="screen-idle">
  <button class="btn btn-start" id="startBtn" onclick="startBurgerGame()">▶ START GAME</button>
  <p class="idle-hint">Scan the QR on the display,<br>then tap Start to play!</p>
</div>

<div id="screen-playing">
  <div class="score-wrap">
    <div class="score-label">SCORE</div>
    <div class="score-val" id="score-display">00000</div>
  </div>
  <div class="btn-row">
    <button class="btn btn-move" id="leftBtn">◀</button>
    <button class="btn btn-move" id="rightBtn">▶</button>
  </div>
  <p class="play-hint">Hold ◀ ▶ to move the tray</p>
</div>

<div id="screen-gameover">
  <div class="gameover-title">GAME OVER</div>
  <div>
    <div class="final-score-label">FINAL SCORE</div>
    <div class="final-score-val" id="final-score">00000</div>
  </div>
  <button class="btn btn-again" onclick="playAgain()">▶ PLAY AGAIN</button>
</div>

<script>
var ws, connected=false;
var host=location.hostname+':${port}';
var state='idle';

function showScreen(s){
  state=s;
  document.getElementById('screen-idle').style.display=s==='idle'?'flex':'none';
  document.getElementById('screen-playing').style.display=s==='playing'?'flex':'none';
  document.getElementById('screen-gameover').style.display=s==='gameover'?'flex':'none';
}

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
      document.getElementById('final-score').textContent=String(msg.score).padStart(5,'0');
      showScreen('gameover');
    }
  };
}

function send(obj){if(connected&&ws.readyState===1)ws.send(JSON.stringify(obj));}
function startBurgerGame(){send({type:'start_burger_game'});document.getElementById('score-display').textContent='00000';showScreen('playing');}
function playAgain(){send({type:'play_again'});document.getElementById('score-display').textContent='00000';showScreen('playing');}

var leftBtn=document.getElementById('leftBtn');
var rightBtn=document.getElementById('rightBtn');
function addHold(btn,dir){
  btn.addEventListener('touchstart',function(e){e.preventDefault();send({type:'move_'+dir});},{passive:false});
  btn.addEventListener('touchend',function(e){e.preventDefault();send({type:'stop_move_'+dir});},{passive:false});
  btn.addEventListener('touchcancel',function(e){e.preventDefault();send({type:'stop_move_'+dir});},{passive:false});
  btn.addEventListener('mousedown',function(){send({type:'move_'+dir});});
  btn.addEventListener('mouseup',function(){send({type:'stop_move_'+dir});});
  btn.addEventListener('mouseleave',function(){send({type:'stop_move_'+dir});});
}
addHold(leftBtn,'left');
addHold(rightBtn,'right');

showScreen('idle');
connect();
setInterval(function(){ send({type:'keepalive'}); }, 5000);
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
