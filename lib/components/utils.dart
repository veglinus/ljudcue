import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ljudcue/components/btn.dart';

extension StateExt<T extends StatefulWidget> on State<T> {
  void toast(String message, {Key? textKey}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, key: textKey),
        duration: Duration(milliseconds: message.length * 25),
      ),
    );
  }

  void simpleDialog(String message, [String action = 'Ok']) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return SimpleDlg(message: message, action: action);
      },
    );
  }

  void dialog(Widget child) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dlg(child: child);
      },
    );
  }
}

extension PlayerStateIcon on PlayerState {
  IconData getIcon() {
    return this == PlayerState.playing
        ? Icons.play_arrow
        : (this == PlayerState.paused
            ? Icons.pause
            : (this == PlayerState.stopped ? Icons.stop : Icons.stop_circle));
  }
}

class SimpleDlg extends StatelessWidget {
  final String message;
  final String action;

  const SimpleDlg({
    required this.message,
    required this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dlg(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          Btn(
            txt: action,
            onPressed: Navigator.of(context).pop,
          ),
        ],
      ),
    );
  }
}

class Dlg extends StatelessWidget {
  final Widget child;

  const Dlg({
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
