// Copyright (c) 2015, Anders Holmgren. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library jefe.project.dependency.test;

import 'package:jefe/src/project/project.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';
import 'package:jefe/src/project/jefe_project.dart';
import 'package:jefe/src/project/dependency_graph.dart';
import 'dart:async';

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
  hierarchicalLoggingEnabled = true;

//
//  Chain.capture(() {
//    runDaTests();
//  }, onError: (error, stackChain) {
//    print("Caught error $error\n"
//        "${stackChain.terse}");
//  });
//}
//
//runDaTests() {
  group('depthFirst', () {
    group(
        'when no projects provided',
        () =>
            expectThat(withTheseProjects: () => [], weGetTheseInvocations: []));

    group('for a single project that has no dependencies', () {
      final project1 = aProject('project1');

      expectThat(withTheseProjects: () => [project1], weGetTheseInvocations: [
        () => new TestProcessInvocation(project1, const [])
      ]);
    });

    group('for two projects with a single dependency', () {
      final project1 = aProject('project1');
      final project2 = aProject('project2', dependencies: [project1]);

      expectThat(
          withTheseProjects: () => [project1, project2],
          weGetTheseInvocations: [
            () => new TestProcessInvocation(project1, []),
            () => new TestProcessInvocation(project2, [project1])
          ]);
    });

    group('for 4 projects with a several dependency', () {
      final project1 = aProject('project1');
      final project2 = aProject('project2', dependencies: [project1]);
      final project3 = aProject('project3');
      final project4 = aProject('project3', dependencies: [project3, project2]);

      expectThat(
          withTheseProjects: () => [project1, project4, project3, project2],
          weGetTheseInvocations: [
            () => new TestProcessInvocation(project3, []),
            () => new TestProcessInvocation(project1, []),
            () => new TestProcessInvocation(project2, [project1]),
            () => new TestProcessInvocation(project4, [project2, project3])
          ]);
    });
  });
}

class TestProcessor {
  final List<TestProcessInvocation> invocations = [];
  Future call(JefeProject project) async {
    invocations.add(new TestProcessInvocation(project, project.directDependencies));
  }

  static createTests(
      TestProcessor processor(), List<TestProcessInvocationFactory> expected) {
    test('has expected number of invocations', () {
      expect(processor().invocations, hasLength(expected.length));
    });

    group('each invocation matches expectation', () {
      for (int i = 0; i < expected.length; i++) {
        TestProcessInvocation.createTests(
            () => processor().invocations[i], expected[i]);
      }
    });
  }
}

typedef TestProcessInvocation TestProcessInvocationFactory();

class TestProcessInvocation {
  final Project project;
  final Iterable<Project> dependencies;

  TestProcessInvocation(this.project, this.dependencies);

  static createTests(
      TestProcessInvocation actual(), TestProcessInvocationFactory expected) {
    test('invocation has expected project', () {
      expect(actual().project, equals(expected().project));
    });

    test('invocation has expected dependencies', () {
      expect(actual().dependencies, unorderedEquals(expected().dependencies));
    });
  }
}

expectThat(
    {String thatWhen,
    Iterable<Project> withTheseProjects(),
    List<TestProcessInvocationFactory> weGetTheseInvocations}) {
  TestProcessor processor;
  Iterable<Project> theProjects;

  scheduleForProjects(Iterable<Project> projects()) async {
    theProjects = projects();
    processor = new TestProcessor();
    final JefeProjectGraph graph =
        await getRootProjects(theProjects.toSet());
    return graph.processDepthFirst(processor);
  }

  setUpForProjects(Iterable<Project> projects()) {
    setUp(() => scheduleForProjects(projects));
  }

  setUpForProjects(withTheseProjects);
  TestProcessor.createTests(() => processor, weGetTheseInvocations);
}
