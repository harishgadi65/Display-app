import 'dart:convert';

enum ContentType { video, image }

class ContentItem {
  final String id;
  final String path;
  final ContentType type;
  final String name;
  bool isSelected;
  final String? webUrl;

  ContentItem({
    required this.id,
    required this.path,
    required this.type,
    required this.name,
    this.isSelected = true,
    this.webUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'type': type.name,
        'name': name,
        'isSelected': isSelected,
        'webUrl': webUrl,
      };

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        id: json['id'] as String,
        path: json['path'] as String,
        type: ContentType.values.firstWhere((e) => e.name == json['type']),
        name: json['name'] as String,
        isSelected: json['isSelected'] as bool? ?? true,
        webUrl: json['webUrl'] as String?,
      );

  static List<ContentItem> listFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    return list.map((e) => ContentItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<ContentItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());
}
