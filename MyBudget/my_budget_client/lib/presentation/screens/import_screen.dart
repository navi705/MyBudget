import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  List<PlatformFile> _selectedFiles = [];

  Future<void> _pickCsvFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        // Add only new files, preventing duplicates
        for (var file in result.files) {
          if (!_selectedFiles.any((existing) => existing.path == file.path)) {
            _selectedFiles.add(file);
          }
        }
      });
    } else {
      debugPrint('No file selected.');
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _startImport() {
    // TODO: Implement the import logic in a later step.
    final filePaths = _selectedFiles.map((f) => f.path!).toList();
    debugPrint('Starting import for: $filePaths');
    // For now, just show a confirmation dialog.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Started'),
        content: Text('Processing ${_selectedFiles.length} file(s). This will be implemented in the next step.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text('Select CSV Files'),
              onPressed: _pickCsvFiles,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const Text(
              'Selected Files:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _selectedFiles.isEmpty
                  ? const Center(child: Text('No files selected.'))
                  : ListView.builder(
                      itemCount: _selectedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _selectedFiles[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.description_outlined),
                            title: Text(file.name, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '${(file.size / 1024).toStringAsFixed(2)} KB',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: () => _removeFile(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedFiles.isNotEmpty ? _startImport : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Start Import'),
            ),
          ],
        ),
      ),
    );
  }
}
