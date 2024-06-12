import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:playsound/SettingsPage.dart';
import 'package:playsound/controls.dart';
import 'package:playsound/sources.dart';
import 'package:provider/provider.dart';

typedef OnError = void Function(Exception exception);

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppBarNotifier(),
      child: const MaterialApp(
          home: _PlaySound(), debugShowCheckedModeBanner: false),
    ),
  );
}

class _PlaySound extends StatefulWidget {
  const _PlaySound();

  @override
  _PlaySoundState createState() => _PlaySoundState();
}

class _PlaySoundState extends State<_PlaySound> {
  AudioPlayer myAudioPlayer = AudioPlayer();
  List<StreamSubscription> streams = [];
  final GlobalKey<SourcesTabState> myKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var it in streams) {
      it.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppBarNotifier appBarNotifier = Provider.of<AppBarNotifier>(context);
    bool isReorderingEnabled = false;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarNotifier.title),
        centerTitle: true,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (String result) {
            switch (result) {
              case 'save':
                myKey.currentState?.save();
                break;
              case 'saveAs':
                myKey.currentState?.saveAs();
                break;
              case 'load':
                myKey.currentState?.load();
                break;
              case 'reorder':
                myKey.currentState?.reorderToggle();
                isReorderingEnabled = !isReorderingEnabled;
                break;
              default:
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'save',
              child: Text('Save'),
            ),
            const PopupMenuItem<String>(
              value: 'saveAs',
              child: Text('Save as'),
            ),
            const PopupMenuItem<String>(
              value: 'load',
              child: Text('Load'),
            ),
            PopupMenuItem<String>(
              value: 'reorder',
              child: Text(isReorderingEnabled ? 'Done reordering' : 'Reorder'),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    audioPlayer: myAudioPlayer,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ControlsTab(player: myAudioPlayer),
          Expanded(
            child: SourcesTab(player: myAudioPlayer, key: myKey),
          ),
        ],
      ),
    );
  }
}

class AppBarNotifier extends ChangeNotifier {
  String _title = 'PlaySound';

  String get title => _title;

  void setTitle(String title) {
    _title = title;
    notifyListeners();
  }
}
