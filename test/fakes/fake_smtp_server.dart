import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// One message the [FakeSmtpServer] accepted.
class FakeSmtpMessage {
  const FakeSmtpMessage({
    required this.from,
    required this.to,
    required this.data,
  });

  final String from;
  final String to;

  /// Everything between `DATA` and the closing lone `.`, one string per line.
  final String data;
}

/// A small SMTP server on a local port, just enough for `ImapMailService.send`
/// to log in and hand off one message (`EHLO`, `AUTH PLAIN`, `MAIL FROM`,
/// `RCPT TO`, `DATA`). Answers like a real one so the real client library is
/// what the test exercises.
class FakeSmtpServer {
  FakeSmtpServer({required this.user, required this.password});

  final String user;
  final String password;

  /// Every message accepted, in order.
  final List<FakeSmtpMessage> sent = <FakeSmtpMessage>[];

  /// Set to make the next `RCPT TO` refused (a bad address).
  bool rejectRecipient = false;

  late final ServerSocket _server;
  final List<Socket> _sockets = <Socket>[];

  int get port => _server.port;

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_serve);
  }

  Future<void> stop() async {
    for (final Socket socket in _sockets) {
      socket.destroy();
    }
    await _server.close();
  }

  void _serve(Socket socket) {
    _sockets.add(socket);
    socket.write('220 fake.smtp ready\r\n');
    String from = '';
    String to = '';
    final List<String> data = <String>[];
    bool inData = false;
    socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          if (inData) {
            if (line == '.') {
              inData = false;
              sent.add(
                FakeSmtpMessage(from: from, to: to, data: data.join('\n')),
              );
              socket.write('250 OK: queued\r\n');
              return;
            }
            data.add(line);
            return;
          }
          final String upper = line.toUpperCase();
          if (upper.startsWith('EHLO')) {
            socket.write('250-fake.smtp\r\n250 AUTH PLAIN\r\n');
          } else if (upper.startsWith('AUTH PLAIN')) {
            final String encoded = line.substring('AUTH PLAIN '.length).trim();
            final List<String> parts = utf8
                .decode(base64.decode(encoded))
                .split('\u0000');
            final bool ok =
                parts.length == 3 && parts[1] == user && parts[2] == password;
            socket.write(
              ok
                  ? '235 Authentication successful\r\n'
                  : '535 Authentication failed\r\n',
            );
          } else if (upper.startsWith('MAIL FROM:')) {
            from = _address(line);
            socket.write('250 OK\r\n');
          } else if (upper.startsWith('RCPT TO:')) {
            to = _address(line);
            socket.write(
              rejectRecipient ? '550 no such user\r\n' : '250 OK\r\n',
            );
          } else if (upper == 'DATA') {
            inData = true;
            data.clear();
            socket.write('354 Start mail input\r\n');
          } else if (upper == 'QUIT') {
            socket.write('221 bye\r\n');
            unawaited(socket.close());
          } else {
            socket.write('500 unrecognized command\r\n');
          }
        });
  }

  static String _address(String line) {
    final int lt = line.indexOf('<');
    final int gt = line.indexOf('>');
    if (lt < 0 || gt < 0 || gt <= lt) return '';
    return line.substring(lt + 1, gt);
  }
}
