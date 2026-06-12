import 'dart:io';

import 'package:flutter/foundation.dart';

class SingleInstanceService {
  static const _lockPort = kDebugMode ? 51934 : 51933;

  ServerSocket? _server;
  void Function()? onSecondInstanceLaunched;

  Future<bool> acquire() async {
    try {
      _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, _lockPort);
      _server!.listen((socket) {
        onSecondInstanceLaunched?.call();
        socket.destroy();
      });
      return true;
    } on SocketException {
      await _notifyPrimaryInstance();
      return false;
    }
  }

  Future<void> _notifyPrimaryInstance() async {
    try {
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, _lockPort);
      socket.destroy();
    } on SocketException catch (_) {
      return;
    }
  }
}
