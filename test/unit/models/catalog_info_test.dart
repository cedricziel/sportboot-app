import 'package:flutter_test/flutter_test.dart';
import 'package:sportboot_app/models/catalog_info.dart';

void main() {
  group('CatalogInfo', () {
    test('should create instance from map', () {
      final map = {
        'name': 'Basisfragen',
        'description': 'Grundlegende Fragen für alle Sportbootführerscheine',
        'url': 'https://example.com/basisfragen',
        'alternateUrl': 'https://example.com/alt/basisfragen',
        'questionCount': 72,
      };

      final catalog = CatalogInfo.fromMap('basisfragen', map);

      expect(catalog.id, 'basisfragen');
      expect(catalog.name, 'Basisfragen');
      expect(
        catalog.description,
        'Grundlegende Fragen für alle Sportbootführerscheine',
      );
      expect(catalog.url, 'https://example.com/basisfragen');
      expect(catalog.alternateUrl, 'https://example.com/alt/basisfragen');
      expect(catalog.questionCount, 72);
    });

    test('should create instance from map without optional fields', () {
      final map = {
        'name': 'Test Catalog',
        'description': 'Test Description',
        'url': 'https://example.com',
        'questionCount': 50,
      };

      final catalog = CatalogInfo.fromMap('test', map);

      expect(catalog.id, 'test');
      expect(catalog.name, 'Test Catalog');
      expect(catalog.alternateUrl, isNull);
      expect(catalog.questionCount, 50);
    });

    test('should convert to map', () {
      const catalog = CatalogInfo(
        id: 'test',
        name: 'Test Catalog',
        description: 'Test Description',
        url: 'https://example.com',
        alternateUrl: 'https://example.com/alt',
        questionCount: 100,
      );

      final map = catalog.toMap();

      expect(map['name'], 'Test Catalog');
      expect(map['description'], 'Test Description');
      expect(map['url'], 'https://example.com');
      expect(map['alternateUrl'], 'https://example.com/alt');
      expect(map['questionCount'], 100);
      expect(map.containsKey('id'), isFalse); // ID is not included in toMap
    });

    test('should convert to map without optional fields', () {
      const catalog = CatalogInfo(
        id: 'test',
        name: 'Test Catalog',
        description: 'Test Description',
        url: 'https://example.com',
        questionCount: 50,
      );

      final map = catalog.toMap();

      expect(map.containsKey('alternateUrl'), isFalse);
      expect(map['questionCount'], 50);
    });

    test('should correctly implement equality', () {
      const catalog1 = CatalogInfo(
        id: 'test',
        name: 'Test',
        description: 'Description',
        url: 'https://example.com',
        questionCount: 10,
      );

      const catalog2 = CatalogInfo(
        id: 'test',
        name: 'Test',
        description: 'Description',
        url: 'https://example.com',
        questionCount: 10,
      );

      const catalog3 = CatalogInfo(
        id: 'different',
        name: 'Test',
        description: 'Description',
        url: 'https://example.com',
        questionCount: 10,
      );

      expect(catalog1, equals(catalog2));
      expect(catalog1, isNot(equals(catalog3)));
    });

    test('should correctly implement hashCode', () {
      const catalog1 = CatalogInfo(
        id: 'test',
        name: 'Test',
        description: 'Description',
        url: 'https://example.com',
        questionCount: 10,
      );

      const catalog2 = CatalogInfo(
        id: 'test',
        name: 'Test',
        description: 'Description',
        url: 'https://example.com',
        questionCount: 10,
      );

      expect(catalog1.hashCode, equals(catalog2.hashCode));
    });
  });
}
