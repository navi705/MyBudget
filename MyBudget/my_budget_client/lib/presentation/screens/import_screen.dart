import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  Future<void> _pickCsvFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      // For now, just print the path of the selected file.
      // In a real implementation, you would parse the CSV file here.
      debugPrint('Selected file path: ${result.files.single.path}');
    } else {
      // User canceled the picker
      debugPrint('No file selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.monetization_on),
            title: const Text('OneMoney Import'),
            onTap: _pickCsvFile,
          ),
        ],
      ),
    );
  }
}
