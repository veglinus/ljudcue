import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class SourceTile extends StatelessWidget {
  final void Function() setSource;
  final void Function() play;
  final void Function(Widget sourceWidget) removeSource;
  final Source source;
  final void Function() onEditSave;
  String title;
  String? subtitle;
  int? index;
  //final Key? setSourceKey;
  final Key? playKey;
  final Color? buttonColor;
  final ValueNotifier<Source?> sourceNotifier;
  final ValueNotifier<PlayerState> playerState;

  SourceTile({
    super.key,
    required this.setSource,
    required this.play,
    required this.removeSource,
    required this.source,
    required this.onEditSave,
    required this.title,
    required this.sourceNotifier,
    this.subtitle,
    this.index,
    //this.setSourceKey,
    this.playKey,
    this.buttonColor,
    required this.playerState,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Source?>(
      valueListenable: sourceNotifier,
      builder: (context, value, child) {
        return ValueListenableBuilder<PlayerState>(
          valueListenable: playerState,
          builder: (context, state, child) {
            Color? tileColor;
            Widget? leading = index != null ? Text('$index.') : null;
            if (value == source) {
              if (state == PlayerState.playing) {
                tileColor = Colors.green.shade200;
                leading = const Icon(Icons.play_arrow_outlined);
              } else if (state == PlayerState.paused) {
                tileColor = Colors.orange.shade200;
                leading = const Icon(Icons.pause_outlined);
              } else {
                tileColor = Colors.yellow.shade200;
              }
            }

            return ListTile(
              tileColor: tileColor,
              leading: leading,
              title: Text(title),
              subtitle: subtitle != null ? Text(subtitle!) : null,
              onTap: () {
                setSource();
              },
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => edit(context),
                    icon: const Icon(Icons.edit),
                    //color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  edit(BuildContext context) {
    String newTitle = title;
    String? newSubtitle = subtitle;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Source'),
          content: Column(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  newTitle = value;
                },
                controller: TextEditingController(text: title),
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              TextField(
                onChanged: (value) {
                  newSubtitle = value;
                },
                controller: TextEditingController(text: subtitle ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Subtitle',
                ),
              ),
              /*
              const SizedBox(height: 16),
              ElevatedButton.icon(
                label: const Text('Play'),
                icon: const Icon(Icons.play_arrow),
                key: playKey,
                onPressed: () {
                  setSource();
                  play();
                },
              ),*/
              // TODO: Implement changing the source file via filepicker
              const SizedBox(height: 100),
              ElevatedButton.icon(
                label: const Text('Delete'),
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // Remove the source
                  removeSource(this);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
                onPressed: Navigator.of(context).pop,
                child: const Text("Cancel")),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                title = newTitle;
                subtitle = newSubtitle;
                onEditSave();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
