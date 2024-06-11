import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:playsound/SettingsPage.dart';
import 'package:playsound/controls.dart';
import 'package:playsound/sources.dart';

typedef OnError = void Function(Exception exception);

void main() {
  runApp(
      const MaterialApp(home: _PlaySound(), debugShowCheckedModeBanner: false));
}

class _PlaySound extends StatefulWidget {
  const _PlaySound();

  @override
  _PlaySoundState createState() => _PlaySoundState();
}

class _PlaySoundState extends State<_PlaySound> {
  AudioPlayer myAudioPlayer = AudioPlayer();
  List<StreamSubscription> streams = [];

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlaySound', textAlign: TextAlign.center),
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
            child: SourcesTab(player: myAudioPlayer),
          ),
        ],
      ),
    );
  }
}
