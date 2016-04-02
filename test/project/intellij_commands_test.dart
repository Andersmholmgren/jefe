import 'package:test/test.dart';
import 'package:jefe/src/project/intellij_commands.dart';
import 'package:xml/xml.dart';

main() {
  final mapping1 = new IntellijVcsMapping('/foo/bar/blah', '/foo/bar');
  group('IntellijVcsMapping.toXml()', () {
    test('produces xml element', () {
      expect(mapping1.toXml(), new isInstanceOf<XmlElement>());
    }, skip: false);

    group('produces xml element', () {
      XmlElement element;

      setUp(() {
        element = mapping1.toXml() as XmlElement;
      });

      test('with correct name', () {
        expect(element.name.local, 'mapping');
      }, skip: false);

      test('with correct number of attributes', () {
        expect(element.attributes, hasLength(2));
      }, skip: false);

      test('with correct attributes names', () {
        expect(element.attributes.map((a) => a.name.local),
            unorderedEquals(['directory', 'vcs']));
      }, skip: false);

      test('with correct directory attribute', () {
        expect(
            element.attributes
                .firstWhere((a) => a.name.local == 'directory')
                .value,
            equals(r'$PROJECT_DIR$/blah'));
      }, skip: false);

      test('with correct vcs attribute', () {
        expect(
            element.attributes.firstWhere((a) => a.name.local == 'vcs').value,
            equals('Git'));
      }, skip: false);
    }, skip: false);
  }, skip: false);

  group('IntellijVcsMappings.toXml()', () {
    final mappings = new IntellijVcsMappings([mapping1]);

    test('produces xml element', () {
      expect(mappings.toXml(), new isInstanceOf<XmlElement>());
    }, skip: false);

    group('produces xml element', () {
      XmlElement element;

      setUp(() {
        element = mappings.toXml() as XmlElement;
//        print(element.toXmlString(pretty: true));
      });

      test('with correct name', () {
        expect(element.name.local, 'component');
      }, skip: false);

      test('with correct number of attributes', () {
        expect(element.attributes, hasLength(1));
      }, skip: false);

      test('with correct attributes names', () {
        expect(element.attributes.map((a) => a.name.local),
            unorderedEquals(['name']));
      }, skip: false);

      test('with correct name attribute', () {
        expect(
            element.attributes.firstWhere((a) => a.name.local == 'name').value,
            equals('VcsDirectoryMappings'));
      }, skip: false);
    }, skip: false);
  }, skip: false);

  group('IntellijVcsMappings.toXmlString()', () {
    final mappings = new IntellijVcsMappings([mapping1]);
    final String expectedXmlString = r'''
<?xml version="1.0" encoding="UTF-8"?>
<project version="4">
  <component name="VcsDirectoryMappings">
    <mapping directory="$PROJECT_DIR$/blah" vcs="Git" />
  </component>
</project>''';

    test('produces xml element', () {
      expect(mappings.toXmlString(), expectedXmlString);
    }, skip: false);
  }, skip: false);
}
