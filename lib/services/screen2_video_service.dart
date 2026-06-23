import 'package:shared_preferences/shared_preferences.dart';
import '../models/content_item.dart';

class Screen2VideoService {
  static const _key = 'screen2_top_bar_videos';

  static final Screen2VideoService _instance = Screen2VideoService._();
  factory Screen2VideoService() => _instance;
  Screen2VideoService._();

  List<ContentItem> _items = [];

  List<ContentItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json != null && json.isNotEmpty) {
      _items = ContentItem.listFromJson(json);
    } else {
      _items = [
        ContentItem(
          id: 'top_default_2',
          path: 'assets/videos/top_bar.mp4',
          type: ContentType.video,
          name: 'top (2).mp4',
          webUrl: 'videos/top_2.mp4',
        ),
      ];
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
