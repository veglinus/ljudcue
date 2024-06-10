import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SourceTile extends StatelessWidget {
  final void Function() setSource;
  final void Function() play;
  final void Function(Widget sourceWidget) removeSource;
  final Source Function() getSource;
  final String title;
  final String? subtitle;
  final Key? setSourceKey;
  final Key? playKey;
  final Color? buttonColor;

  const SourceTile({
    required this.setSource,
    required this.play,
    required this.removeSource,
    required this.getSource,
    required this.title,
    this.subtitle,
    this.setSourceKey,
    this.playKey,
    this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      onTap: () {
        setSource();
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          /*
          IconButton(
            tooltip: 'Set Source',
            key: setSourceKey,
            onPressed: setSource,
            icon: const Icon(Icons.upload_file),
            color: buttonColor ?? Theme.of(context).primaryColor,
          ),*/
          /*
          IconButton(
            key: playKey,
            tooltip: 'Play',
            onPressed: play,
            icon: const Icon(Icons.play_arrow),
            color: buttonColor ?? Theme.of(context).primaryColor,
          ),*/
          IconButton(
            tooltip: 'Remove',
            onPressed: () => removeSource(this),
            icon: const Icon(Icons.delete),
            color: buttonColor ?? Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }
}
