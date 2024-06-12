import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:playsound/components/_SourceTile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProjectManager {
  final List<String> savedProjects = [];
  ValueNotifier<String> currentProject = ValueNotifier<String>('');

  Future<void> save(List<Widget> sourceWidgets, String projectName,
      {bool? saveAs, String? folderPath}) async {
    try {
      // TODO: Implement android/ios app file saving

      if (kIsWeb) {
        // Web file saving logic
      } else {
        if (currentProject.value.isEmpty ||
            saveAs == true && folderPath != null) {
          if (folderPath != null) {
            String projectFolderPath = '$folderPath/$projectName';

            // Create the new project folder
            await Directory(projectFolderPath).create(recursive: true);

            // Parse widgets into JSON and get files to copy
            var (json, filesToCopy) = await widgetsIntoJson(sourceWidgets);

            // Create the data file
            File file = File('$projectFolderPath/data.json');
            await file.writeAsBytes(utf8.encode(json));

            // Copy the files
            for (var fileToCopy in filesToCopy) {
              File file = File(fileToCopy);
              String fileName = file.path.split('/').last;
              await file.copy('$projectFolderPath/$fileName');
            }
            debugPrint('Files saved at: $folderPath');

            savedProjects.add(folderPath);
            final prefs = await SharedPreferences.getInstance();
            prefs.setStringList('savedProjects', savedProjects);
          } else {
            // The user aborted the file picker
            debugPrint('File save aborted');
          }
        } else {
          // Autosave in current project file
          File file = File(currentProject.value);
          var (json, _) = await widgetsIntoJson(sourceWidgets);
          await file.writeAsBytes(utf8.encode(json));
          debugPrint('Autosaved: ${currentProject.value}');
        }
      }
    } catch (e) {
      debugPrint("Error saving session: $e");
    } finally {
      debugPrint("Done saving session!");
    }
  }

  Future<(String, List<String>)> widgetsIntoJson(
      List<Widget> sourceWidgets) async {
    debugPrint("Parsing widgets into json..");
    List<Map> saveData = [];
    List<String> filesToCopy = [];
    for (var widget in sourceWidgets) {
      if (widget is SourceTile) {
        Source source = widget.source;
        Map<String, dynamic> widgetData = {
          //'setSourceKey': widget.setSourceKey.toString(),
          'title': widget.title,
          'subtitle': widget.subtitle,
          'type': source.runtimeType.toString(),
        };
        if (source is DeviceFileSource) {
          filesToCopy.add(source.path);
          String fileName = source.path.split("/").last;
          debugPrint("Copying file: $fileName");

          widgetData['source'] = fileName;
          widgetData['projectCopied'] = true;
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
    return (json, filesToCopy);
  }

  Future<String?> loadProjectFromStorage() async {
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
        //setDataToView(jsonData);
        currentProject.value = result.files.first.path!;
        return jsonData;
        //return;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Error loading session: $e");
      return null;
    }
  }

  Future<String?> loadProject(String filePath) async {
    /**
     * Loads project with provided file path
     */
    try {
      File file = File(filePath);
      if (!file.existsSync()) {
        debugPrint('File does not exist: $filePath');
        return null;
      }
      String json = await file.readAsString();
      //setDataToView(json);
      currentProject.value = filePath;
      return json;
    } catch (e) {
      debugPrint("Error loading project: $e");
      return null;
    }
  }

  void checkIfSavedToRecent() async {
    // If the project is not in the savedProjects list, add it
    if (!savedProjects.contains(currentProject.value)) {
      //setState(() {
      savedProjects.add(currentProject.value);
      //});

      // And save the list of saved projects to shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setStringList('savedProjects', savedProjects);
    }
  }

  Future<void> loadSavedProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final savedProjectsFromPrefs = prefs.getStringList('savedProjects') ?? [];
    //setState(() {
    savedProjects.addAll(savedProjectsFromPrefs);
    //});
  }

  Future<String?> loadMostRecentProject() async {
    final prefs = await SharedPreferences.getInstance();
    final currentProjectFromPrefs = prefs.getString('currentProject');
    if (currentProjectFromPrefs != null) {
      debugPrint("Loading latest saved project");
      String? jsonData = await loadProject(currentProjectFromPrefs);
      return jsonData;
    }
    return null;
  }

  // TODO: Build into a menu or something instead (drawer)
  // or just move it to a separate file
  Future<void> showProjectPicker(BuildContext context) async {
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
                    child: savedProjects.isNotEmpty
                        ? ListView.builder(
                            itemCount: savedProjects.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                title: Text(savedProjects[index]),
                                onTap: () {
                                  Navigator.of(context)
                                      .pop(savedProjects[index]);
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
      await loadProject(pickedProject);
    }
  }
}
