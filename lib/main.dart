import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:playsound/controls.dart';
import 'package:playsound/sources.dart';
import 'package:playsound/utils.dart';

const defaultPlayerCount = 1;

typedef OnError = void Function(Exception exception);

void main() {
  runApp(const MaterialApp(home: _ExampleApp()));
}

class _ExampleApp extends StatefulWidget {
  const _ExampleApp();

  @override
  _ExampleAppState createState() => _ExampleAppState();
}

class _ExampleAppState extends State<_ExampleApp> {
  List<AudioPlayer> audioPlayers = List.generate(
    defaultPlayerCount,
    (_) => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
  );
  int selectedPlayerIdx = 0;

  AudioPlayer get selectedAudioPlayer => audioPlayers[selectedPlayerIdx];
  List<StreamSubscription> streams = [];

  @override
  void initState() {
    super.initState();

/*
    audioPlayers.asMap().forEach((index, player) {
      streams.add(
        player.onPlayerStateChanged.listen(
          (it) {
            switch (it) {
              case PlayerState.stopped:
                debugPrint("Player stopped!");
                setState(() {});
                toast(
                  'Player stopped!',
                  textKey: Key('toast-player-stopped-$index'),
                );
                break;
              case PlayerState.completed:
                debugPrint("Player complete!");
                setState(() {});
                toast(
                  'Player complete!',
                  textKey: Key('toast-player-complete-$index'),
                );
                break;
              default:
                break;
            }
          },
        ),
      );
      streams.add(
        player.onSeekComplete.listen((it) {
          debugPrint("Seek complete!");
        }),
      );
    });*/
  }

  @override
  void dispose() {
    for (var it in streams) {
      it.cancel();
    }
    super.dispose();
  }

/*
  void _handleAction(PopupAction value) {
    switch (value) {
      case PopupAction.add:
        setState(() {
          audioPlayers.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
        });
        break;
      case PopupAction.remove:
        setState(() {
          if (audioPlayers.isNotEmpty) {
            selectedAudioPlayer.dispose();
            audioPlayers.removeAt(selectedPlayerIdx);
          }
          // Adjust index to be in valid range
          if (audioPlayers.isEmpty) {
            selectedPlayerIdx = 0;
          } else if (selectedPlayerIdx >= audioPlayers.length) {
            selectedPlayerIdx = audioPlayers.length - 1;
          }
        });
        break;
    }
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlaySound', textAlign: TextAlign.center),
        actions: const [
          /*
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    audioPlayers: audioPlayers,
                    selectedPlayerIdx: selectedPlayerIdx,
                  ),
                ),
              );
            },
          ),*/

          // TODO: Turn this into a FAB
          /*
          PopupMenuButton<PopupAction>(
            onSelected: _handleAction,
            itemBuilder: (BuildContext context) {
              return PopupAction.values.map((PopupAction choice) {
                return PopupMenuItem<PopupAction>(
                  value: choice,
                  child: Text(
                    choice == PopupAction.add
                        ? 'Add player'
                        : 'Remove selected player',
                  ),
                );
              }).toList();
            },
          ),*/
        ],
      ),
      body: Column(
        children: [
          ControlsTab(player: selectedAudioPlayer),
          Expanded(
            child: audioPlayers.isEmpty
                ? const Text('No AudioPlayer available!')
                : SourcesTab(
                    player: selectedAudioPlayer,
                  ),
          ),
        ],
      ),
    );
  }
}

enum PopupAction {
  add,
  remove,
}
