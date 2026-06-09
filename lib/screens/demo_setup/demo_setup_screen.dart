import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../models/content_item.dart';
import '../../services/content_service.dart';

class DemoSetupScreen extends StatefulWidget {
  const DemoSetupScreen({super.key});

  @override
  State<DemoSetupScreen> createState() => _DemoSetupScreenState();
}

class _DemoSetupScreenState extends State<DemoSetupScreen> {
  final _service = ContentService();
  final _uuid = const Uuid();
  List<ContentItem> _items = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => _items = List.from(_service.items));

  Future<void> _pickFiles(ContentType type) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: type == ContentType.video ? FileType.video : FileType.image,
    );
    if (result == null) return;

    for (final file in result.files) {
      if (file.path == null) continue;
      await _service.add(ContentItem(
        id: _uuid.v4(),
        path: file.path!,
        type: type,
        name: file.name,
      ));
    }
    _refresh();
  }

  Future<void> _delete(String id) async {
    await _service.remove(id);
    _refresh();
  }

  Future<void> _toggle(String id) async {
    await _service.toggleSelected(id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08081A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D2B),
        title: const Text(
          'Demo Content Setup',
          style: TextStyle(color: Color(0xFF00E5FF)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => _pickFiles(ContentType.image),
            icon: const Icon(Icons.image, color: Color(0xFF00E5FF)),
            label: const Text('Add Image', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
          TextButton.icon(
            onPressed: () => _pickFiles(ContentType.video),
            icon: const Icon(Icons.videocam, color: Color(0xFF00E5FF)),
            label: const Text('Add Video', style: TextStyle(color: Color(0xFF00E5FF))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _items.isEmpty
          ? _emptyState()
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              onReorder: (oldIndex, newIndex) async {
                await _service.reorder(oldIndex, newIndex);
                _refresh();
              },
              itemBuilder: (context, index) {
                final item = _items[index];
                return _ContentTile(
                  key: ValueKey(item.id),
                  item: item,
                  onDelete: () => _delete(item.id),
                  onToggle: () => _toggle(item.id),
                );
              },
            ),
    );
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.perm_media_outlined, color: Color(0xFF333366), size: 64),
            const SizedBox(height: 16),
            const Text(
              'No content added yet',
              style: TextStyle(color: Colors.white54, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap "Add Image" or "Add Video" to get started',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      );
}

class _ContentTile extends StatelessWidget {
  final ContentItem item;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _ContentTile({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F0F2E),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isSelected ? const Color(0xFF00E5FF) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: _thumbnail(),
        title: Text(
          item.name,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.type == ContentType.video ? 'Video' : 'Image',
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: item.isSelected,
              onChanged: (_) => onToggle(),
              activeColor: const Color(0xFF00E5FF),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
            const Icon(Icons.drag_handle, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _thumbnail() {
    if (item.type == ContentType.image) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 40,
          child: Image.file(
            File(item.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1A1A3E),
              child: const Icon(Icons.broken_image, color: Colors.white38, size: 20),
            ),
          ),
        ),
      );
    }
    return Container(
      width: 56,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A3E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.videocam, color: Color(0xFF00E5FF), size: 22),
    );
  }
}
