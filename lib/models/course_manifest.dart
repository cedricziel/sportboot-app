import 'catalog_info.dart';

class CourseCategory {
  final String id;
  final String name;
  final String description;
  final List<String> catalogRefs;
  final String? type;

  const CourseCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.catalogRefs,
    this.type,
  });

  factory CourseCategory.fromMap(Map<String, dynamic> map) {
    return CourseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      catalogRefs: List<String>.from(map['catalogRefs'] ?? []),
      type: map['type'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'catalogRefs': catalogRefs,
      if (type != null) 'type': type,
    };
  }
}

class CourseManifest {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final String icon;
  final List<String> catalogIds;
  final int totalQuestions;
  final List<CourseCategory> categories;
  final Map<String, dynamic>? examConfig;

  const CourseManifest({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.icon,
    required this.catalogIds,
    required this.totalQuestions,
    required this.categories,
    this.examConfig,
  });

  factory CourseManifest.fromMap(String id, Map<String, dynamic> map) {
    // Parse catalog IDs
    final catalogIds = <String>[];
    final catalogs = map['catalogs'] as List?;
    if (catalogs != null) {
      for (final catalog in catalogs) {
        if (catalog is String) {
          catalogIds.add(catalog);
        } else if (catalog is Map) {
          catalogIds.add(catalog['id'] as String);
        }
      }
    }

    // Parse categories
    final categories = <CourseCategory>[];
    final categoriesList = map['categories'] as List?;
    if (categoriesList != null) {
      for (final category in categoriesList) {
        categories.add(
          CourseCategory.fromMap(category as Map<String, dynamic>),
        );
      }
    }

    return CourseManifest(
      id: id,
      name: map['name'] as String,
      shortName: map['shortName'] as String,
      description: map['description'] as String,
      icon: map['icon'] as String? ?? '📚',
      catalogIds: catalogIds,
      totalQuestions: map['totalQuestions'] as int,
      categories: categories,
      examConfig: map['exam'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortName': shortName,
      'description': description,
      'icon': icon,
      'catalogs': catalogIds,
      'totalQuestions': totalQuestions,
      'categories': categories.map((c) => c.toMap()).toList(),
      if (examConfig != null) 'exam': examConfig,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CourseManifest &&
        other.id == id &&
        other.name == name &&
        other.shortName == shortName &&
        other.description == description &&
        other.icon == icon &&
        other.totalQuestions == totalQuestions;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        shortName.hashCode ^
        description.hashCode ^
        icon.hashCode ^
        totalQuestions.hashCode;
  }
}

class Manifest {
  final Map<String, CatalogInfo> catalogs;
  final Map<String, CourseManifest> courses;
  final Map<String, dynamic>? metadata;

  const Manifest({
    required this.catalogs,
    required this.courses,
    this.metadata,
  });

  factory Manifest.fromMap(Map<String, dynamic> map) {
    // Parse catalogs
    final catalogs = <String, CatalogInfo>{};
    final catalogsMap = map['catalogs'] as Map<String, dynamic>?;
    if (catalogsMap != null) {
      catalogsMap.forEach((id, data) {
        catalogs[id] = CatalogInfo.fromMap(id, data as Map<String, dynamic>);
      });
    }

    // Parse courses
    final courses = <String, CourseManifest>{};
    final coursesMap = map['courses'] as Map<String, dynamic>?;
    if (coursesMap != null) {
      coursesMap.forEach((id, data) {
        courses[id] = CourseManifest.fromMap(id, data as Map<String, dynamic>);
      });
    }

    return Manifest(
      catalogs: catalogs,
      courses: courses,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'catalogs': catalogs.map((id, catalog) => MapEntry(id, catalog.toMap())),
      'courses': courses.map((id, course) => MapEntry(id, course.toMap())),
      if (metadata != null) 'metadata': metadata,
    };
  }
}
