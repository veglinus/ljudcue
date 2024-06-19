import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ljudcue/components/btn.dart';
import 'package:ljudcue/components/drop_down.dart';

class SourceDialog extends StatefulWidget {
  final void Function(Source source, String path) onAdd;

  const SourceDialog({super.key, required this.onAdd});

  @override
  State<SourceDialog> createState() => _SourceDialogState();
}

class _SourceDialogState extends State<SourceDialog> {
  Type sourceType = UrlSource;
  String path = '';

  final Map<String, String> assetsList = {'': 'Nothing selected'};

  @override
  void initState() {
    super.initState();

    AssetManifest.loadFromAssetBundle(rootBundle).then((assetManifest) {
      setState(() {
        assetsList.addAll(
          assetManifest
              .listAssets()
              .map((e) => e.replaceFirst('assets/', ''))
              .toList()
              .asMap()
              .map((key, value) => MapEntry(value, value)),
        );
      });
    });
  }

  Widget _buildSourceValue() {
    switch (sourceType) {
      case const (AssetSource):
        return Row(
          children: [
            const Text('Asset path'),
            const SizedBox(width: 16),
            Expanded(
              child: CustomDropDown<String>(
                options: assetsList,
                selected: path,
                onChange: (value) => setState(() {
                  path = value ?? '';
                }),
              ),
            ),
          ],
        );
      case const (BytesSource):
      case const (DeviceFileSource):
        return Row(
          children: [
            const Text('Device File path'),
            const SizedBox(width: 16),
            Expanded(child: Text(path)),
            TextButton.icon(
              onPressed: () async {
                final result = await FilePicker.platform.pickFiles();
                final path = result?.files.single.path;
                if (path != null) {
                  setState(() {
                    this.path = path;
                  });
                }
              },
              icon: const Icon(Icons.file_open),
              label: const Text('Browse'),
            ),
          ],
        );
      default:
        return Row(
          children: [
            const Text('URL'),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'https://example.com/myFile.wav',
                ),
                onChanged: (String? url) => path = url ?? '',
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LabeledDropDown<Type>(
          label: 'Source type',
          options: const {
            AssetSource: 'Asset',
            DeviceFileSource: 'Device File',
            UrlSource: 'Url',
            BytesSource: 'Byte Array',
          },
          selected: sourceType,
          onChange: (Type? value) {
            setState(() {
              if (value != null) {
                sourceType = value;
              }
            });
          },
        ),
        ListTile(title: _buildSourceValue()),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Btn(
              onPressed: () async {
                switch (sourceType) {
                  case const (BytesSource):
                    widget.onAdd(
                      BytesSource(await File(path).readAsBytes()),
                      path,
                    );
                  case const (AssetSource):
                    widget.onAdd(AssetSource(path), path);
                  case const (DeviceFileSource):
                    widget.onAdd(DeviceFileSource(path), path);
                  default:
                    widget.onAdd(UrlSource(path), path);
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              txt: 'Add',
            ),
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ],
    );
  }
}
