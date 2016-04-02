import 'package:test/test.dart';
import 'package:jefe/src/project/intellij_commands.dart';
import 'package:xml/xml.dart';

main() {
  final mapping1 = new IntellijVcsMapping('/foo/bar/blah', '/foo/bar');
  group('IntellijVcsMapping.toXml()', () {
    test('produces xml element', () {
      expect(mapping1.toXml(), new isInstanceOf<XmlElement>());
    }, skip: false);
  }, skip: false);
}
