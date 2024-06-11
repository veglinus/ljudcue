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

  Future<void> save(List<Widget> sourceWidgets) async {
    try {
      debugPrint("Saving session..");
      List<Map> saveData = [];

      for (var widget in sourceWidgets) {
        if (widget is SourceTile) {
          Source source = widget.getSource();

          //debugPrint("Saving widget: $widget");
          //debugPrint("Saving source: $source");

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

      // TODO: Implement android/ios app file saving

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

            //setState(() {
            savedProjects.add(filePath);
            //});
            final prefs = await SharedPreferences.getInstance();
            prefs.setStringList('savedProjects', savedProjects);
          } else {
            // The user aborted the file picker
            debugPrint('File save aborted');
          }
        } else {
          // Autosave in current project file
          File file = File(currentProject.value);
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
}
