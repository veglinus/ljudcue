import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:playsound/components/_SourceTile.dart';
import 'package:playsound/ProjectManager.dart';
import 'package:playsound/utils.dart';
import 'package:playsound/components/_SourceDialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'dart:html' as html;

class SourcesTab extends StatefulWidget {
  final AudioPlayer player;

  const SourcesTab({
    required this.player,
    super.key,
  });

  @override
  State<SourcesTab> createState() => _SourcesTabState();
}

class _SourcesTabState extends State<SourcesTab>
    with AutomaticKeepAliveClientMixin<SourcesTab> {
  AudioPlayer get player => widget.player;

  final List<Widget> sourceWidgets = [];
  //final List<String> savedProjects = [];
  //ValueNotifier<String> currentProject = ValueNotifier<String>('');
  int rebuildCounter = 0;

  ProjectManager project = ProjectManager();

  Future<void> _setSource(Source source) async {
    try {
      await player.setSource(source);
      await player.stop();

      toast(
        'Completed setting source.',
        textKey: const Key('toast-set-source'),
      );
    } catch (e) {
      toast(
        'Error setting source: $e',
        textKey: const Key('toast-set-source-error'),
      );
    }
  }

  Future<void> _play(Source source) async {
    //await player.stop();
    //await player.play(source);

    await player.resume();

    toast(
      'Set and playing source.',
      textKey: const Key('toast-set-play'),
    );
  }

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

  Future<void> save() async {
    project.save(sourceWidgets);
  }

  Future<void> loadProjectFromStorage() async {
    String? jsonData = await project.loadProjectFromStorage();
    if (jsonData != null) {
      setDataToView(jsonData);
    }
  }

  void setDataToView(String jsonData) async {
    List<dynamic> data = jsonDecode(jsonData);

    for (var item in data) {
      //debugPrint("Drawing widget: $item");
      Widget widget = await getCorrectWidget(item);
      sourceWidgets.add(widget);
    }
    setState(() {});
  }

  Future<Widget> getCorrectWidget(dynamic input) async {
    Source source;
    bool invalid = false;

    switch (input['type']) {
      case 'AssetSource':
        source = AssetSource(input['source']);
        break;
      case 'DeviceFileSource':
        source = DeviceFileSource(input['source']);
        break;
      case 'UrlSource':
        source = UrlSource(input['source']);
        break;
      default:
        source = AssetSource('Invalid asset');
        invalid = true;
        break;
    }

    if (invalid) {
      return createSourceTile(
        //setSourceKey: const Key('setSource-asset-invalid'),
        title: "Invalid Asset - ${input['title']}",
        subtitle: input['subtitle'],
        source: source,
        buttonColor: Colors.red,
      );
    } else {
      return createSourceTile(
        //setSourceKey: input['setSourceKey'],
        title: input['title'],
        subtitle: input['subtitle'],
        source: source,
      );
    }
  }

/*
  Future<void> _setSourceBytesRemote(
    Future<void> Function(Source) fun, {
    required String url,
    String? mimeType,
  }) async {
    final bytes = await http.readBytes(Uri.parse(url));
    await fun(BytesSource(bytes, mimeType: mimeType));
  }*/

  Widget createSourceTile({
    required String title,
    required String subtitle,
    required Source source,
    Key? setSourceKey,
    Color? buttonColor,
    Key? playKey,
  }) =>
      SourceTile(
        setSource: () => _setSource(source),
        play: () => _play(source),
        removeSource: _removeSourceWidget,
        getSource: () => source,
        onEditSave: () => saveAndUpdate(),
        title: title,
        subtitle: subtitle,
        setSourceKey: setSourceKey,
        playKey: playKey,
        buttonColor: buttonColor,
      );

  Future<void> _loadMostRecentProject() async {
    final prefs = await SharedPreferences.getInstance();
    final currentProjectFromPrefs = prefs.getString('currentProject');
    if (currentProjectFromPrefs != null) {
      debugPrint("Loading latest saved project");
      String? jsonData = await project.loadProject(currentProjectFromPrefs);
      if (jsonData != null) {
        setDataToView(jsonData);
        toast("Loaded latest opened project! $currentProjectFromPrefs");
      }
    }
  }

  @override
  void initState() {
    super.initState();
    project.loadSavedProjects();
    _loadMostRecentProject();
    //addTestWidgets();

    project.currentProject.addListener(() async {
      project.checkIfSavedToRecent();
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('currentProject', project.currentProject.value);
    });
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
            child: SingleChildScrollView(
              controller: ScrollController(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: const Text('Save Session'),
                          onPressed: () {
                            debugPrint('Saving session');
                            save();
                          },
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          child: const Text('Load session'),
                          onPressed: () {
                            //debugPrint('Loading session');
                            //loadWidgetData();
                            _showProjectPicker();
                          },
                        ),
                      ],
                    ),
                    Column(key: ValueKey(rebuildCounter), children: [
                      for (var i = 0; i < sourceWidgets.length; i++) ...[
                        sourceWidgets[i],
                        const Divider(),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
        Align(
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
                        sourceWidgets.add(
                          createSourceTile(
                            title: 'Device File',
                            subtitle: path,
                            source: DeviceFileSource(path),
                          ),
                        );
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
                          sourceWidgets.add(
                            createSourceTile(
                              title: source.runtimeType.toString(),
                              subtitle: path,
                              source: source,
                            ),
                          );
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
        ),
      ],
    );
  }

  // TODO: Build into a menu or something instead (drawer)
  Future<void> _showProjectPicker() async {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    String? pickedProject = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
            title: const Text('Pick a project'),
            content: SizedBox(
              width: screenWidth * 0.6,
              height: screenHeight * 0.6,
              child: Column(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () async {
                      await loadProjectFromStorage();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text("Load project from storage"),
                  ),
                  Expanded(
                    child: project.savedProjects.isNotEmpty
                        ? ListView.builder(
                            itemCount: project.savedProjects.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                title: Text(project.savedProjects[index]),
                                onTap: () {
                                  Navigator.of(context)
                                      .pop(project.savedProjects[index]);
                                },
                              );
                            },
                          )
                        : const Center(child: Text("No projects found")),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ]);
      },
    );

    if (pickedProject != null) {
      // Load the picked project
      await project.loadProject(pickedProject);
    }
  }

  @override
  bool get wantKeepAlive => true;

  /**
   * UNUSED FUNCTIONALITY
   */

  Future<void> _setSourceBytesAsset(
    Future<void> Function(Source) fun, {
    required String asset,
    String? mimeType,
  }) async {
    final bytes = await AudioCache.instance.loadAsBytes(asset);
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
  }
}
