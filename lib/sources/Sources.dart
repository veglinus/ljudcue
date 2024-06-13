import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:playsound/sources/SourceTile.dart';
import 'package:playsound/ProjectManager.dart';
import 'package:playsound/main.dart';
import 'package:playsound/sources/_WidgetParser.dart';
import 'package:playsound/components/utils.dart';
import 'package:playsound/sources/_SourceDialog.dart';
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
  late ValueNotifier<List<SourceTile>> sourceWidgetsNotifier;
  int rebuildCounter = 0;
  ProjectManager project = ProjectManager();
  ValueNotifier<Source?> currentlyPlayingSource = ValueNotifier<Source?>(null);
  final _playerState = ValueNotifier<PlayerState>(PlayerState.stopped);
  // ignore: unused_field
  StreamSubscription? _playerStateChangeSubscription;
  bool isReorderingEnabled = false;

  /* METHODS USED BY SOURCETILE */
  Future<void> _removeSourceWidget(Widget sourceWidget) async {
    setState(() {
      sourceWidgets.remove(sourceWidget);
    });
    toast('Source removed.');
  }

  Future<void> saveAndUpdate() async {
    await save();
    setState(() {
      rebuildCounter++;
    });
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

    int index = 1;
    for (var item in data) {
      //debugPrint("Drawing widget: $item");
      SourceTile widget = await getCorrectWidget(
        item,
        player,
        project,
        _removeSourceWidget,
        saveAndUpdate,
        _playerState,
        currentlyPlayingSource,
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

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      //debugPrint("onPlayerStateChanged: $state");
      setState(() {
        _playerState.value = state;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    project.loadSavedProjects();
    _loadMostRecentProject();
    //addTestWidgets();
    _initListeners();
    player.setReleaseMode(ReleaseMode.stop);
  }

  @override
  void dispose() {
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Center(
          child: Container(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
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
                          save();
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
                                        Expanded(child: sourceWidgets[i]),
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
              ),
            ),
          ),
        ),
        customFAB(),
      ],
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
                    save();
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
                      save();
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

  /* UNUSED FUNCTIONALITY */

  /*
  Future<void> _setSourceBytesAsset(
    Future<void> Function(Source) fun, {
    required String asset,
    String? mimeType,
  }) async {
    final bytes = await AudioCache.instance.loadAsBytes(asset);
    await fun(BytesSource(bytes, mimeType: mimeType));
  }


  Future<void> _setSourceBytesRemote(
    Future<void> Function(Source) fun, {
    required String url,
    String? mimeType,
  }) async {
    final bytes = await http.readBytes(Uri.parse(url));
    await fun(BytesSource(bytes, mimeType: mimeType));
  }

  void addTestWidgets() {
    const useLocalServer = bool.fromEnvironment('USE_LOCAL_SERVER');

    final localhost = kIsWeb || !Platform.isAndroid ? 'localhost' : '10.0.2.2';
    final host = useLocalServer ? 'http://$localhost:8080' : 'https://luan.xyz';
    final wavUrl1 = '$host/files/audio/coins.wav';
    final wavUrl2 = '$host/files/audio/laser.wav';
    //final wavUrl3 = '$host/files/audio/coins_non_ascii_и.wav';
    final mp3Url1 = '$host/files/audio/ambient_c_motion.mp3';
    final mp3Url2 = '$host/files/audio/nasa_on_a_mission.mp3';
    final m3u8StreamUrl = useLocalServer
        ? '$host/files/live_streams/nasa_power_of_the_rovers.m3u8'
        : 'https://a.files.bbci.co.uk/media/live/manifesto/audio/simulcast/hls/nonuk/sbr_low/ak/bbc_world_service.m3u8';
    final mpgaStreamUrl = useLocalServer
        ? '$host/stream/mpeg'
        : 'https://timesradio.wireless.radio/stream';

    //const wavAsset1 = 'coins.wav';
    const wavAsset2 = 'laser.wav';
    const mp3Asset = 'nasa_on_a_mission.mp3';
    const invalidAsset = 'invalid.txt';
    //const specialCharAsset = 'coins_non_ascii_и.wav';
    //const noExtensionAsset = 'coins_no_extension';

    sourceWidgets.addAll([
      createSourceTile(
        setSourceKey: const Key('setSource-url-remote-wav-1'),
        title: 'Remote URL WAV 1',
        subtitle: 'coins.wav',
        source: UrlSource(wavUrl1),
      ),
      createSourceTile(
        setSourceKey: const Key('setSource-url-remote-wav-2'),
        title: 'Remote URL WAV 2',
        subtitle: 'laser.wav',
        source: UrlSource(wavUrl2),
      ),
      createSourceTile(
        setSourceKey: const Key('setSource-url-remote-mp3-1'),
        title: 'Remote URL MP3 1 (VBR)',
        subtitle: 'ambient_c_motion.mp3',
        source: UrlSource(mp3Url1),
      ),
      createSourceTile(
        setSourceKey: const Key('setSource-url-remote-mp3-2'),
        title: 'Remote URL MP3 2',
        subtitle: 'nasa_on_a_mission.mp3',
        source: UrlSource(mp3Url2),
      ),
      createSourceTile(
        setSourceKey: const Key('setSource-url-remote-m3u8'),
        title: 'Remote URL M3U8',
        subtitle: 'BBC stream',
        source: UrlSource(m3u8StreamUrl),
      ),
      createSourceTile(
        setSourceKey: const Key('setSource-url-remote-mpga'),
        title: 'Remote URL MPGA',
        subtitle: 'Times stream',
        source: UrlSource(mpgaStreamUrl),
      ),
      /*
        _createSourceTile(
          setSourceKey: const Key('setSource-url-data-wav'),
          title: 'Data URI WAV',
          subtitle: 'coins.wav',
          source: UrlSource(wavDataUri),
        ),
        _createSourceTile(
          setSourceKey: const Key('setSource-url-data-mp3'),
          title: 'Data URI MP3',
          subtitle: 'coins.mp3',
          source: UrlSource(mp3DataUri),
        ),*/
      createSourceTile(
        setSourceKey: const Key('setSource-asset-wav'),
        title: 'Asset WAV',
        subtitle: 'laser.wav',
        source: AssetSource(wavAsset2),
      ),
      createSourceTile(
        setSourceKey: const Key('setSource-asset-mp3'),
        title: 'Asset MP3',
        subtitle: 'nasa.mp3',
        source: AssetSource(mp3Asset),
      ),
      SourceTile(
        setSource: () => _setSourceBytesAsset(
          _setSource,
          asset: wavAsset2,
          mimeType: 'audio/wav',
        ),
        setSourceKey: const Key('setSource-bytes-local'),
        play: () => _setSourceBytesAsset(
          _play,
          asset: wavAsset2,
          mimeType: 'audio/wav',
        ),
        removeSource: _removeSourceWidget,
        getSource: () => BytesSource(
          File(wavAsset2).readAsBytesSync(),
          mimeType: 'audio/wav',
        ),
        onEditSave: save,
        title: 'Bytes - Local',
        subtitle: 'laser.wav',
      ),
      /*
      // TODO: Support remote mp3
      _SourceTile(
        setSource: () => _setSourceBytesRemote(
          _setSource,
          url: mp3Url1,
          mimeType: 'audio/mpeg',
        ),
        setSourceKey: const Key('setSource-bytes-remote'),
        play: () => _setSourceBytesRemote(
          _play,
          url: mp3Url1,
          mimeType: 'audio/mpeg',
        ),
        getSource: () => BytesSource(
          http.readBytes(Uri.parse(mp3Url1)),
          mimeType: 'audio/mpeg',
        ),
        removeSource: _removeSourceWidget,
        title: 'Bytes - Remote',
        subtitle: 'ambient.mp3',
      ),*/
      createSourceTile(
        setSourceKey: const Key('setSource-asset-invalid'),
        title: 'Invalid Asset',
        subtitle: 'invalid.txt',
        source: AssetSource(invalidAsset),
        buttonColor: Colors.red,
      ),
    ]);
  }*/
}
