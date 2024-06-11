import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class SourceTile extends StatelessWidget {
  final void Function() setSource;
  final void Function() play;
  final void Function(Widget sourceWidget) removeSource;
  final Source Function() getSource;
  final void Function() onEditSave;
  String title;
  String? subtitle;
  final Key? setSourceKey;
  final Key? playKey;
  final Color? buttonColor;

  SourceTile({
    super.key,
    required this.setSource,
    required this.play,
    required this.removeSource,
    required this.getSource,
    required this.onEditSave,
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
          IconButton(
            onPressed: () => edit(context),
            icon: const Icon(Icons.edit),
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
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
