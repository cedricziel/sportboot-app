class CatalogInfo {
  final String id;
  final String name;
  final String description;
  final String url;
  final String? alternateUrl;
  final int questionCount;

  const CatalogInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    this.alternateUrl,
    required this.questionCount,
  });

  factory CatalogInfo.fromMap(String id, Map<String, dynamic> map) {
    return CatalogInfo(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String,
      url: map['url'] as String,
      alternateUrl: map['alternateUrl'] as String?,
      questionCount: map['questionCount'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'url': url,
      if (alternateUrl != null) 'alternateUrl': alternateUrl,
      'questionCount': questionCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CatalogInfo &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.url == url &&
        other.alternateUrl == alternateUrl &&
        other.questionCount == questionCount;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        url.hashCode ^
        (alternateUrl?.hashCode ?? 0) ^
        questionCount.hashCode;
  }
}