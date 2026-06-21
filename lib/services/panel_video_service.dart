import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_item.dart';

class PanelVideoService {
  static final _instances = <String, PanelVideoService>{};

  factory PanelVideoService(String panelKey, {ContentItem? defaultItem}) =>
      _instances.putIfAbsent(
          panelKey, () => PanelVideoService._(panelKey, defaultItem));

  PanelVideoService._(this._key, this._defaultItem);

  final String _key;
  final ContentItem? _defaultItem;
  List<ContentItem> _items = [];

  List<ContentItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null && json.isNotEmpty) {
      _items = ContentItem.listFromJson(json);
    } else if (_defaultItem != null) {
      _items = [_defaultItem];
      await _save();
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
}
