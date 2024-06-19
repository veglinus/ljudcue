import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ljudcue/SettingsPage.dart';
import 'package:ljudcue/controls.dart';
import 'package:ljudcue/sources/_SaveAs.dart';
import 'package:ljudcue/sources/Sources.dart';
import 'package:provider/provider.dart';

typedef OnError = void Function(Exception exception);

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppBarNotifier(),
      child: const MaterialApp(
          home: _LjudCue(), debugShowCheckedModeBanner: false),
    ),
  );
}

class _LjudCue extends StatefulWidget {
  const _LjudCue();

  @override
  _LjudCueState createState() => _LjudCueState();
}

class _LjudCueState extends State<_LjudCue> {
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
    bool isReorderingEnabled = myKey.currentState?.isReorderingEnabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarNotifier.title),
        centerTitle: true,
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (String result) {
            switch (result) {
              case 'new':
                myKey.currentState?.autoSave();
                myKey.currentState?.project.currentProject.value = '';
                myKey.currentState?.sourceWidgets.clear();
                myKey.currentState?.currentlyPlayingIndex.value = -1;
                myKey.currentState?.rebuildCounter++;
                break;
              case 'save':
                myKey.currentState?.save();
                break;
              case 'saveAs':
                saveAs(context, myKey.currentState!.project,
                    myKey.currentState!.sourceWidgets);
                break;
              case 'load':
                myKey.currentState?.showLoadPickerAndLoadToView();
                break;
              case 'reorder':
                if (isReorderingEnabled) {
                  myKey.currentState?.autoSave();
                }

                isReorderingEnabled = !isReorderingEnabled;
                setState(() {
                  myKey.currentState!.isReorderingEnabled = isReorderingEnabled;
                });
                break;
              default:
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'new',
              child: Text('New'),
            ),
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
                    player: myAudioPlayer,
                  ),
                ),
              ).then((_) {
                myKey.currentState?.updateConfig();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          ControlsTab(player: myAudioPlayer, callback: setSourceIndex),
          Expanded(
            child: SourcesTab(player: myAudioPlayer, key: myKey),
          ),
        ],
      ),
    );
  }

  void setSourceIndex(int index) {
    var currentState = myKey.currentState;
    var currentIndex = currentState?.currentlyPlayingIndex.value ?? 0;
    var sourceWidgetsLength = currentState?.sourceWidgets.length ?? 0;

    if (index >= sourceWidgetsLength) {
      debugPrint("Index out of bounds: $index");
      currentState?.currentlyPlayingIndex.value = 0;
    } else {
      debugPrint("Changing source index: $index");
      currentState?.currentlyPlayingIndex.value =
          currentIndex == -1 ? 0 : currentIndex + index;
    }
  }
}

class AppBarNotifier extends ChangeNotifier {
  String _title = 'LjudCue';

  String get title => _title;

  void setTitle(String title) {
    _title = title;
    notifyListeners();
  }
}
