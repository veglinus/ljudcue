import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ljudcue/sources/SourceTile.dart';
import 'package:ljudcue/ProjectManager.dart';
import 'package:ljudcue/main.dart';
import 'package:ljudcue/sources/_WidgetParser.dart';
import 'package:ljudcue/components/utils.dart';
import 'package:ljudcue/sources/_SourceDialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class SourcesTab extends StatefulWidget {
  final AudioPlayer player;

  const SourcesTab({
    required this.player,
    super.key,
  });

  @override
  State<SourcesTab> createState() => SourcesTabState();
}

class SourcesTabState extends State<SourcesTab>
    with AutomaticKeepAliveClientMixin<SourcesTab> {
  AudioPlayer get player => widget.player;
  final List<SourceTile> sourceWidgets = [];
  int rebuildCounter = 0;
  ProjectManager project = ProjectManager();
  ValueNotifier<Source?> currentlyPlayingSource = ValueNotifier<Source?>(null);
  final _playerState = ValueNotifier<PlayerState>(PlayerState.stopped);
  // ignore: unused_field
  StreamSubscription? _playerStateChangeSubscription;
  bool isReorderingEnabled = false;
  bool autoPlay = false;
  bool stayAwake = true;
  bool autoSavePref = true;
  String playerMode = "PlayerMode.mediaPlayer";

  ValueNotifier<int> currentlyPlayingIndex = ValueNotifier<int>(-1);

  /* METHODS USED BY SOURCETILE */
  Future<void> _removeSourceWidget(Widget sourceWidget) async {
    setState(() {
      sourceWidgets.remove(sourceWidget);
    });
    toast('Source removed.');
  }

  Future<void> saveAndUpdate() async {
    await autoSave();
    setState(() {
      rebuildCounter++;
    });
  }

  Future<void> autoSave() async {
    if (autoSavePref) {
      await save();
    }
  }
  /* END OF SOURCETILE METHODS */

  Future<void> save() async {
    project.save(sourceWidgets, project.currentProject.value);
  }

  Future<void> _loadMostRecentProject() async {
    String? jsonData = await project.loadMostRecentProject();
    if (jsonData != null) {
      setDataToView(jsonData);
      toast("Loaded latest opened project!");
    }
  }

  void setDataToView(String jsonData) async {
    List<dynamic> data = jsonDecode(jsonData);

    int index = 0;
    for (var item in data) {
      //debugPrint("Drawing widget: $item");
      SourceTile widget = await getCorrectWidget(
        index = index++,
        item,
        player,
        project,
        _removeSourceWidget,
        saveAndUpdate,
        _playerState,
        currentlyPlayingSource,
        currentlyPlayingIndex,
      );

      widget.index = index++;
      sourceWidgets.add(widget);
    }

    if (mounted) {
      setState(() {
        rebuildCounter++;
      });
    }
  }

  Future<void> setSourceWidgetsIndexes() async {
    for (var i = 0; i < sourceWidgets.length; i++) {
      sourceWidgets[i].index = i + 1;
    }
    setState(() {});
  }

  void showLoadPickerAndLoadToView() async {
    String? data = await project.showProjectPicker(context);
    if (data != null) {
      sourceWidgets.clear();
      setDataToView(data);
    } else {
      debugPrint("Data is null not loading");
    }
  }

  void _initListeners() {
    AppBarNotifier appBarNotifier =
        Provider.of<AppBarNotifier>(context, listen: false);

    project.currentProject.addListener(() async {
      project.checkIfSavedToRecent();
      debugPrint("Current project changed to: ${project.currentProject.value}");
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('currentProject', project.currentProject.value);

      String parentDirectory = path.dirname(project.currentProject.value);
      String parentFolderName = path.basename(parentDirectory);
      appBarNotifier.setTitle(parentFolderName);
    });

    currentlyPlayingIndex.addListener(() {
      if (currentlyPlayingIndex.value != -1) {
        if (currentlyPlayingSource.value !=
            sourceWidgets[currentlyPlayingIndex.value].source) {
          player.setSource(sourceWidgets[currentlyPlayingIndex.value].source);
          debugPrint("Set the source of new file automatically.");
          setState(() {
            currentlyPlayingSource.value =
                sourceWidgets[currentlyPlayingIndex.value].source;
          });
        }
      }
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      debugPrint("onPlayerStateChanged: $state");
      debugPrint(
          "Current position: ${player.getCurrentPosition()} of ${player.getDuration()}");

      if (state == PlayerState.completed) {
        if (autoPlay) {
          debugPrint("Autoplaying next stem");
          if (currentlyPlayingIndex.value + 1 < sourceWidgets.length) {
            currentlyPlayingIndex.value++;
            player.play(sourceWidgets[currentlyPlayingIndex.value].source);
          }
        }
      }

      setState(() {
        _playerState.value = state;
      });
    });
  }

  void updateConfig() {
    // Any settings changes can be refreshed here
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        autoPlay = prefs.getBool('autoPlay') ?? false;
        stayAwake = prefs.getBool('stayAwake') ?? true;
        autoSavePref = prefs.getBool('autoSave') ?? true;
        playerMode = prefs.getString('playerMode') ?? "mediaPlayer";
      });

      player.setPlayerMode(playerMode == "mediaPlayer"
          ? PlayerMode.mediaPlayer
          : PlayerMode.lowLatency);

      //player.setAudioContext(AudioContextConfig(stayAwake: stayAwake).build());
      // TODO: This setting doesnt work
    });
  }

  @override
  void initState() {
    super.initState();
    project.loadSavedProjects();
    _loadMostRecentProject();
    updateConfig();
    //addTestWidgets();
    _initListeners();
    player.setReleaseMode(ReleaseMode.stop); // TODO: Make this a setting later
  }

  @override
  void dispose() {
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DropTarget(
      onDragDone: (details) {
        dragDropHandler(details);
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Center(
            child: Container(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: sourceWidgets.isNotEmpty
                    ? Column(
                        children: [
                          Expanded(
                            child: ReorderableListView(
                              buildDefaultDragHandles: false,
                              key: ValueKey(rebuildCounter),
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) {
                                    newIndex -= 1;
                                  }
                                  final SourceTile item =
                                      sourceWidgets.removeAt(oldIndex);
                                  sourceWidgets.insert(newIndex, item);
                                  setSourceWidgetsIndexes();
                                  //autoSave();
                                });
                              },
                              children: [
                                for (var i = 0; i < sourceWidgets.length; i++)
                                  KeyedSubtree(
                                    key: ValueKey(i),
                                    child: isReorderingEnabled
                                        ? ReorderableDragStartListener(
                                            index: i,
                                            child: Row(
                                              children: [
                                                const Icon(Icons.drag_handle),
                                                Expanded(
                                                    child: sourceWidgets[i]),
                                              ],
                                            ),
                                          )
                                        : Row(
                                            children: [
                                              Expanded(child: sourceWidgets[i]),
                                            ],
                                          ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                                onPressed: () => showLoadPickerAndLoadToView(),
                                child: const Text("Load project")),
                            const SizedBox(height: 16),
                            const Text(
                                'Load to get started or add a file in the bottom right!'),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          customFAB(),
        ],
      ),
    );
  }

  Align customFAB() {
    return Align(
      // TODO: Move this to separate file
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SpeedDial(
          icon: Icons.add,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.music_note),
              label: 'File',
              onTap: () async {
                try {
                  // Handle tap for the first button
                  final result = await FilePicker.platform.pickFiles();
                  final path = result?.files.single.path;
                  if (path != null) {
                    addNewSource(path);
                  } else {
                    debugPrint('No file selected');
                  }
                } catch (e) {
                  debugPrint('Error picking file: $e');
                }
              },
            ),
            SpeedDialChild(
              child: const Icon(Icons.add),
              label: 'Advanced',
              onTap: () {
                dialog(
                  SourceDialog(
                    onAdd: (Source source, String path) {
                      sourceWidgets.add(SourceTile(
                        key: UniqueKey(),
                        setSource: () {
                          debugPrint("set source");
                          player.setSource(source);
                          currentlyPlayingSource.value = source;
                        },
                        play: () => player.play(source),
                        removeSource: _removeSourceWidget,
                        source: source,
                        onEditSave: () => saveAndUpdate(),
                        title: source.runtimeType.toString(),
                        subtitle: path,
                        currentlyPlayingSource: currentlyPlayingSource,
                        playerState: _playerState,
                      ));
                      setSourceWidgetsIndexes();
                      setState(() {});
                      autoSave();
                    },
                  ),
                );
                // Handle tap for the second button
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void dragDropHandler(DropDoneDetails details) async {
    AudioPlayer testPlayer = AudioPlayer();
    for (var file in details.files) {
      bool isPlayable = await isFilePlayable(testPlayer, file.path);
      if (isPlayable) {
        addNewSource(file.path);
      } else {
        debugPrint("A file wasn't playable: $file");
      }
    }
    testPlayer.dispose();
  }

  Future<bool> isFilePlayable(AudioPlayer newPlayer, String path) async {
    try {
      await newPlayer.setSource(DeviceFileSource(path));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> addNewSource(String path) async {
    File file = File(path);
    if (!file.existsSync()) {
      debugPrint('File does not exist: $path');
    } else {
      sourceWidgets.add(SourceTile(
        key: UniqueKey(),
        setSource: () {
          player.setSource(DeviceFileSource(path));
          currentlyPlayingSource.value = DeviceFileSource(path);
        },
        play: () => player.play(DeviceFileSource(path)),
        removeSource: _removeSourceWidget,
        source: DeviceFileSource(path),
        onEditSave: () => saveAndUpdate(),
        title: 'Device File',
        subtitle: path,
        currentlyPlayingSource: currentlyPlayingSource,
        playerState: _playerState,
      ));
      setSourceWidgetsIndexes();
      setState(() {});
      autoSave();
    }
  }
}
