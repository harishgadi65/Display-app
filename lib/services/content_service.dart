import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_item.dart';

class ContentService {
  static const _key = 'blink_board_content';

  static final ContentService _instance = ContentService._();
  factory ContentService() => _instance;
  ContentService._();

  List<ContentItem> _items = [];

  List<ContentItem> get items => List.unmodifiable(_items);
  List<ContentItem> get selectedItems =>
      _items.where((e) => e.isSelected).toList();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null && json.isNotEmpty) {
      _items = ContentItem.listFromJson(json);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, ContentItem.listToJson(_items));
  }

  Future<void> add(ContentItem item) async {
    _items.add(item);
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _save();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _items.removeAt(oldIndex);
    _items.insert(newIndex, item);
    await _save();
  }

  Future<void> toggleSelected(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _items[idx].isSelected = !_items[idx].isSelected;
      await _save();
    }
  }
}
