import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:playsound/components/_SourceTile.dart';
import 'package:playsound/utils.dart';
import 'package:playsound/components/_SourceDialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'dart:html' as html;

const useLocalServer = bool.fromEnvironment('USE_LOCAL_SERVER');

final localhost = kIsWeb || !Platform.isAndroid ? 'localhost' : '10.0.2.2';
final host = useLocalServer ? 'http://$localhost:8080' : 'https://luan.xyz';

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
  final List<String> savedProjects = [];
  ValueNotifier<String> currentProject = ValueNotifier<String>('');

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

  Future<void> saveWidgetData() async {
    try {
      List<Map> saveData = [];

      for (var widget in sourceWidgets) {
        if (widget is SourceTile) {
          Source source = widget.getSource();

          debugPrint("Saving widget: $widget");
          debugPrint("Saving source: $source");

          Map<String, dynamic> widgetData = {
            //'setSourceKey': widget.setSourceKey.toString(),
            'title': widget.title,
            'subtitle': widget.subtitle,
            'type': source.runtimeType.toString(),
          };
          if (source is DeviceFileSource) {
            widgetData['source'] = source.path;
          } else if (source is UrlSource) {
            widgetData['source'] = source.url;
          } else if (source is AssetSource) {
            widgetData['source'] = source.path;
          } else {
            debugPrint("Invalid source type: ${source.runtimeType}");
          }

          saveData.add(widgetData);
        }
      }

      String json = jsonEncode(saveData);

      // TODO: Implement app file saving

      if (kIsWeb) {
        // Web file saving logic
      } else {
        if (currentProject.value.isEmpty) {
          String? filePath = await FilePicker.platform.saveFile(
            dialogTitle: 'Save your session', // custom title for the dialog
            bytes: utf8.encode(json), // data to be saved (for mobile platforms)
            fileName: 'session.json', // default file name
            //initialDirectory: '/path/to/initial/directory', // initial directory (for desktop platforms)
            type: FileType.any, // file type filter
            allowedExtensions: ['json'], // allowed extensions
            lockParentWindow: true, // lock parent window (for Windows desktop)
          );

          if (filePath != null) {
            File file = File(filePath);
            await file.writeAsBytes(utf8.encode(json));
            debugPrint('File saved at: $filePath');

            setState(() {
              savedProjects.add(filePath);
            });
            final prefs = await SharedPreferences.getInstance();
            prefs.setStringList('savedProjects', savedProjects);
          } else {
            // The user aborted the file picker
            debugPrint('File save aborted');
          }
        } else {
          File file = File(currentProject.value);
          await file.writeAsBytes(utf8.encode(json));
          debugPrint('File saved at: $currentProject');
        }
      }
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  Future<void> loadProjectFromStorage() async {
    /**
     * Loads project with file picker from storage
     */
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['json'],
          allowMultiple: false,
          withData: true);

      if (result != null && result.files.isNotEmpty) {
        final fileBytes = result.files.first.bytes;
        String jsonData = String.fromCharCodes(fileBytes!);

        debugPrint("Loaded data: $jsonData");
        setDataToView(jsonData);
        currentProject.value = result.files.first.path!;
      }
    } catch (e) {
      debugPrint("Error loading session: $e");
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> loadProject(String filePath) async {
    /**
     * Loads project with provided file path
     */
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('File does not exist: $filePath');
        return;
      }

      String json = await file.readAsString();
      setDataToView(json);
      currentProject.value = filePath;
    } catch (e) {
      debugPrint("Error loading project: $e");
    }
  }

  void checkIfSavedToRecent() async {
    // If the project is not in the savedProjects list, add it
    if (!savedProjects.contains(currentProject.value)) {
      setState(() {
        savedProjects.add(currentProject.value);
      });

      // And save the list of saved projects to shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('savedProjects', savedProjects);
    }
  }

  void setDataToView(String jsonData) async {
    List<dynamic> data = jsonDecode(jsonData);

    for (var item in data) {
      debugPrint("Drawing widget: $item");
      Widget widget = await getCorrectWidget2(item);
      sourceWidgets.add(widget);
    }
    setState(() {});
  }

  Future<Widget> getCorrectWidget2(dynamic input) async {
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
      return _createSourceTile(
        //setSourceKey: const Key('setSource-asset-invalid'),
        title: "Invalid Asset - ${input['title']}",
        subtitle: input['subtitle'],
        source: source,
        buttonColor: Colors.red,
      );
    } else {
      return _createSourceTile(
        //setSourceKey: input['setSourceKey'],
        title: input['title'],
        subtitle: input['subtitle'],
        source: source,
      );
    }
  }

  Widget _createSourceTile({
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
        title: title,
        subtitle: subtitle,
        setSourceKey: setSourceKey,
        playKey: playKey,
        buttonColor: buttonColor,
      );

  Future<void> _setSourceBytesAsset(
    Future<void> Function(Source) fun, {
    required String asset,
    String? mimeType,
  }) async {
    final bytes = await AudioCache.instance.loadAsBytes(asset);
    await fun(BytesSource(bytes, mimeType: mimeType));
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

  Future<void> _loadSavedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProjectsFromPrefs = prefs.getStringList('savedProjects') ?? [];
    setState(() {
      savedProjects.addAll(savedProjectsFromPrefs);
    });
  }

  Future<void> _loadMostRecentProject() async {
    final prefs = await SharedPreferences.getInstance();
    final currentProjectFromPrefs = prefs.getString('currentProject');
    if (currentProjectFromPrefs != null) {
      debugPrint("Loading latest project from prefs..");
      loadProject(currentProjectFromPrefs);
      toast("Loaded latest opened project! $currentProjectFromPrefs");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSavedProjects();
    _loadMostRecentProject();
    //addTestWidgets();

    currentProject.addListener(() async {
      checkIfSavedToRecent();
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('currentProject', currentProject.value);
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
                            saveWidgetData();
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
                    Column(
                      children: sourceWidgets
                          .expand((element) => [element, const Divider()])
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              dialog(
                SourceDialog(
                  onAdd: (Source source, String path) {
                    setState(() {
                      sourceWidgets.add(
                        _createSourceTile(
                          title: source.runtimeType.toString(),
                          subtitle: path,
                          source: source,
                        ),
                      );
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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
                  onPressed: loadProjectFromStorage,
                  child: const Text("Load project from storage"),
                ),
                Expanded(
                  child: savedProjects.isNotEmpty
                      ? ListView.builder(
                          itemCount: savedProjects.length,
                          itemBuilder: (BuildContext context, int index) {
                            return ListTile(
                              title: Text(savedProjects[index]),
                              onTap: () {
                                Navigator.of(context).pop(savedProjects[index]);
                              },
                            );
                          },
                        )
                      : const Center(child: Text("No projects found")),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (pickedProject != null) {
      // Load the picked project
      await loadProject(pickedProject);
    }
  }

  @override
  bool get wantKeepAlive => true;

  void addTestWidgets() {
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
      _createSourceTile(
        setSourceKey: const Key('setSource-url-remote-wav-1'),
        title: 'Remote URL WAV 1',
        subtitle: 'coins.wav',
        source: UrlSource(wavUrl1),
      ),
      _createSourceTile(
        setSourceKey: const Key('setSource-url-remote-wav-2'),
        title: 'Remote URL WAV 2',
        subtitle: 'laser.wav',
        source: UrlSource(wavUrl2),
      ),
      _createSourceTile(
        setSourceKey: const Key('setSource-url-remote-mp3-1'),
        title: 'Remote URL MP3 1 (VBR)',
        subtitle: 'ambient_c_motion.mp3',
        source: UrlSource(mp3Url1),
      ),
      _createSourceTile(
        setSourceKey: const Key('setSource-url-remote-mp3-2'),
        title: 'Remote URL MP3 2',
        subtitle: 'nasa_on_a_mission.mp3',
        source: UrlSource(mp3Url2),
      ),
      _createSourceTile(
        setSourceKey: const Key('setSource-url-remote-m3u8'),
        title: 'Remote URL M3U8',
        subtitle: 'BBC stream',
        source: UrlSource(m3u8StreamUrl),
      ),
      _createSourceTile(
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
      _createSourceTile(
        setSourceKey: const Key('setSource-asset-wav'),
        title: 'Asset WAV',
        subtitle: 'laser.wav',
        source: AssetSource(wavAsset2),
      ),
      _createSourceTile(
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
      _createSourceTile(
        setSourceKey: const Key('setSource-asset-invalid'),
        title: 'Invalid Asset',
        subtitle: 'invalid.txt',
        source: AssetSource(invalidAsset),
        buttonColor: Colors.red,
      ),
    ]);
  }
}
