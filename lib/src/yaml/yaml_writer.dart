library devops.yaml;

String toYamlString(node) {
  var sb = new StringBuffer();
  writeYamlString(node, sb);
  return sb.toString();
}

void writeYamlString(node, StringSink ss) {
  _writeYamlString(node, 0, ss, true);
}

_writeYamlString(node, int indent, StringSink ss, bool isTopLevel) {
  if (node is Map) {
    _mapToYamlString(node, indent, ss, isTopLevel);
  } else if (node is Iterable) {
    _listToYamlString(node, indent, ss, isTopLevel);
  } else {
    ss..writeln(node);
  }
}

_mapToYamlString(Map node, int indent, StringSink ss, bool isTopLevel) {
  if (!isTopLevel) {
    ss.writeln();
    indent += 2;
  }

  node.forEach((k, v) {
    _writeIndent(indent, ss);
    ss
      ..write(k)
      ..write(': ');
    _writeYamlString(v, indent, ss, false);
  });
}

_listToYamlString(Iterable node, int indent, StringSink ss, bool isTopLevel) {
  if (!isTopLevel) {
    ss.writeln();
    indent += 2;
  }

  node.forEach((v) {
    _writeIndent(indent, ss);
    ss.write('- ');
    _writeYamlString(v, indent, ss, false);
  });
}

void _writeIndent(int indent, StringSink ss) {
  for (int i = 0; i < indent; i++) {
    ss.write(' ');
  }
}
