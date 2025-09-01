import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/models/course_manifest.dart';
import 'package:sportboot_app/models/catalog_info.dart';

void main() {
  group('CourseCategory', () {
    test('should create instance from map', () {
      final map = {
        'id': 'all',
        'name': 'Alle Fragen',
        'description': 'Kompletter Fragenkatalog',
        'catalogRefs': ['basisfragen', 'spezifische-see'],
        'type': 'standard',
      };

      final category = CourseCategory.fromMap(map);

      expect(category.id, 'all');
      expect(category.name, 'Alle Fragen');
      expect(category.description, 'Kompletter Fragenkatalog');
      expect(category.catalogRefs, ['basisfragen', 'spezifische-see']);
      expect(category.type, 'standard');
    });

    test('should create instance without optional fields', () {
      final map = {
        'id': 'basics',
        'name': 'Basisfragen',
        'description': '72 grundlegende Fragen',
        'catalogRefs': ['basisfragen'],
      };

      final category = CourseCategory.fromMap(map);

      expect(category.id, 'basics');
      expect(category.type, isNull);
      expect(category.catalogRefs.length, 1);
    });

    test('should convert to map', () {
      const category = CourseCategory(
        id: 'test',
        name: 'Test Category',
        description: 'Test Description',
        catalogRefs: ['catalog1', 'catalog2'],
        type: 'special',
      );

      final map = category.toMap();

      expect(map['id'], 'test');
      expect(map['name'], 'Test Category');
      expect(map['description'], 'Test Description');
      expect(map['catalogRefs'], ['catalog1', 'catalog2']);
      expect(map['type'], 'special');
    });
  });

  group('CourseManifest', () {
    test('should create instance from map with string catalog IDs', () {
      final map = {
        'name': 'Sportbootführerschein See',
        'shortName': 'SBF-See',
        'description': 'Amtlicher Sportbootführerschein',
        'icon': '🌊',
        'catalogs': ['basisfragen', 'spezifische-see'],
        'totalQuestions': 284,
        'categories': [
          {
            'id': 'all',
            'name': 'Alle Fragen',
            'description': 'Kompletter Fragenkatalog',
            'catalogRefs': ['basisfragen', 'spezifische-see'],
          },
        ],
        'exam': {
          'questionCount': 30,
          'passingScore': 0.8,
        },
      };

      final course = CourseManifest.fromMap('sbf-see', map);

      expect(course.id, 'sbf-see');
      expect(course.name, 'Sportbootführerschein See');
      expect(course.shortName, 'SBF-See');
      expect(course.icon, '🌊');
      expect(course.catalogIds, ['basisfragen', 'spezifische-see']);
      expect(course.totalQuestions, 284);
      expect(course.categories.length, 1);
      expect(course.categories[0].id, 'all');
      expect(course.examConfig?['questionCount'], 30);
      expect(course.examConfig?['passingScore'], 0.8);
    });

    test('should create instance from map with object catalog IDs', () {
      final map = {
        'name': 'Test Course',
        'shortName': 'TC',
        'description': 'Test Description',
        'catalogs': [
          {'id': 'catalog1', 'startNumber': 1, 'endNumber': 50},
          {'id': 'catalog2', 'startNumber': 51, 'endNumber': 100},
        ],
        'totalQuestions': 100,
        'categories': [],
      };

      final course = CourseManifest.fromMap('test', map);

      expect(course.catalogIds, ['catalog1', 'catalog2']);
      expect(course.icon, '📚'); // Default icon
      expect(course.examConfig, isNull);
    });

    test('should convert to map', () {
      final course = CourseManifest(
        id: 'test',
        name: 'Test Course',
        shortName: 'TC',
        description: 'Test Description',
        icon: '📖',
        catalogIds: ['catalog1', 'catalog2'],
        totalQuestions: 100,
        categories: const [
          CourseCategory(
            id: 'all',
            name: 'All',
            description: 'All questions',
            catalogRefs: ['catalog1', 'catalog2'],
          ),
        ],
        examConfig: {'questionCount': 20},
      );

      final map = course.toMap();

      expect(map['name'], 'Test Course');
      expect(map['shortName'], 'TC');
      expect(map['icon'], '📖');
      expect(map['catalogs'], ['catalog1', 'catalog2']);
      expect(map['totalQuestions'], 100);
      expect(map['categories'], isA<List>());
      expect(map['exam'], {'questionCount': 20});
    });

    test('should correctly implement equality', () {
      const course1 = CourseManifest(
        id: 'test',
        name: 'Test',
        shortName: 'T',
        description: 'Desc',
        icon: '📚',
        catalogIds: ['c1'],
        totalQuestions: 50,
        categories: [],
      );

      const course2 = CourseManifest(
        id: 'test',
        name: 'Test',
        shortName: 'T',
        description: 'Desc',
        icon: '📚',
        catalogIds: ['c1'],
        totalQuestions: 50,
        categories: [],
      );

      const course3 = CourseManifest(
        id: 'different',
        name: 'Test',
        shortName: 'T',
        description: 'Desc',
        icon: '📚',
        catalogIds: ['c1'],
        totalQuestions: 50,
        categories: [],
      );

      expect(course1, equals(course2));
      expect(course1, isNot(equals(course3)));
    });
  });

  group('Manifest', () {
    test('should create instance from map', () {
      final map = {
        'catalogs': {
          'basisfragen': {
            'name': 'Basisfragen',
            'description': 'Basic questions',
            'url': 'https://example.com',
            'questionCount': 72,
          },
        },
        'courses': {
          'sbf-see': {
            'name': 'SBF-See',
            'shortName': 'See',
            'description': 'Sea license',
            'icon': '🌊',
            'catalogs': ['basisfragen'],
            'totalQuestions': 72,
            'categories': [],
          },
        },
        'metadata': {
          'version': '2024.01',
          'source': 'ELWIS',
        },
      };

      final manifest = Manifest.fromMap(map);

      expect(manifest.catalogs.length, 1);
      expect(manifest.catalogs['basisfragen']?.name, 'Basisfragen');
      expect(manifest.courses.length, 1);
      expect(manifest.courses['sbf-see']?.name, 'SBF-See');
      expect(manifest.metadata?['version'], '2024.01');
    });

    test('should create instance with empty collections', () {
      final map = <String, dynamic>{};

      final manifest = Manifest.fromMap(map);

      expect(manifest.catalogs, isEmpty);
      expect(manifest.courses, isEmpty);
      expect(manifest.metadata, isNull);
    });

    test('should convert to map', () {
      final manifest = Manifest(
        catalogs: {
          'test': const CatalogInfo(
            id: 'test',
            name: 'Test',
            description: 'Test catalog',
            url: 'https://example.com',
            questionCount: 10,
          ),
        },
        courses: {
          'course1': const CourseManifest(
            id: 'course1',
            name: 'Course 1',
            shortName: 'C1',
            description: 'First course',
            icon: '📚',
            catalogIds: ['test'],
            totalQuestions: 10,
            categories: [],
          ),
        },
        metadata: const {'version': '1.0'},
      );

      final map = manifest.toMap();

      expect(map['catalogs'], isA<Map>());
      expect(map['courses'], isA<Map>());
      expect(map['metadata'], {'version': '1.0'});
    });
  });
}