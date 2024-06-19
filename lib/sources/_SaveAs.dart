import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:ljudcue/ProjectManager.dart';
import 'package:ljudcue/sources/SourceTile.dart';

Future<void> saveAs(BuildContext context, ProjectManager project,
    List<SourceTile> sourceWidgets) async {
  debugPrint('Saving session as');
  String projectName = '';
  String? folderPath;

  await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Enter project name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Project name',
              ),
              onChanged: (value) => projectName = value,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: const Text('Pick a folder'),
              onPressed: () async {
                folderPath = await FilePicker.platform.getDirectoryPath(
                  dialogTitle:
                      "Pick where to save project (a new folder will be made)",
                  lockParentWindow: true,
                );
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () {
              Navigator.of(context).pop(projectName);
            },
          ),
        ],
      );
    },
  );

  if (projectName.isNotEmpty) {
    project.save(sourceWidgets, projectName,
        saveAs: true, folderPath: folderPath);

    File file = File("$folderPath/$projectName/data.json");
    if (file.existsSync()) {
      project.currentProject.value = "$folderPath/$projectName/data.json";
    }
    // TODO: URGENT: This doesnt seem to set current project properly
  }
}
