library devops.project.dependency.test;

import 'package:devops/src/dependency_graph.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:devops/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:devops/src/pubspec/pubspec.dart';
import 'dart:async';
import 'package:devops/src/pubspec/dependency.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:logging/logging.dart';

main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);
  hierarchicalLoggingEnabled = true;

  Chain.capture(() {
    runDaTests();
  }, onError: (error, stackChain) {
    print("Caught error $error\n"
        "${stackChain.terse}");
  });
}

runDaTests() {
  TestProcessor processor;

  group('depthFirst', () {
    scheduleForProjects(Iterable<Project> projects) {
      return schedule(() async {
        processor = new TestProcessor();
        final DependencyGraph graph =
            await getDependencyGraph(projects.toSet());
        return graph.depthFirst(processor);
      });
    }

    setUpForProjects(Iterable<Project> projects) {
      setUp(() => scheduleForProjects(projects));
    }

//    group('for empty projects', () {
//      setUpForProjects([]);
//
//      test('does not call processor', () {
//        schedule(() => expect(processor.invocations, isEmpty));
//      });
//    });
//
//    group('for one project with no dependencies', () {
//      MockProject project1;
//
//      setUp(() {
//        project1 = new MockProject('project1', new PubSpec());
//        scheduleForProjects([project1]);
//      });
//
//      test('calls processor once', () {
//        schedule(() => expect(processor.invocations, hasLength(1)));
//      });
//
//      test('calls processor once with expected project', () {
//        schedule(() =>
//            expect(processor.invocations.first.project, equals(project1)));
//      });
//
//      test('calls processor once with no dependencies', () {
//        schedule(
//            () => expect(processor.invocations.first.dependencies, isEmpty));
//      });
//    });
//
//    group('for two projects with one path dependency', () {
//      MockProject project1;
//      MockProject project2;
//
//      setUp(() {
//        project1 = new MockProject('project1', new PubSpec(name: 'project1'));
//        final pubspec2 = new PubSpec(
//            name: 'project2',
//            dependencies: {'project1': new PathReference('project1')});
//        project2 = new MockProject('project2', pubspec2);
//
//        scheduleForProjects([project1, project2]);
//      });
//
//      test('calls processor twice', () {
//        schedule(() => expect(processor.invocations, hasLength(2)));
//      });
//
//      test('calls processor first with project1', () {
//        schedule(() =>
//            expect(processor.invocations.first.project, equals(project1)));
//      });
//
//      test('calls processor first with no dependencies', () {
//        schedule(
//            () => expect(processor.invocations.first.dependencies, isEmpty));
//      });
//
//      test('calls processor second with project2', () {
//        schedule(() => expect(
//            processor.invocations.elementAt(1).project, equals(project2)));
//      });
//
//      test('calls processor first with one dependency on project1', () {
//        schedule(() => expect(processor.invocations.elementAt(1).dependencies,
//            unorderedEquals([project1])));
//      });
//
////      processor.runTests([new TestProcessInvocation(project1, [])]);
//    });

    testCase(
        thatWhen: 'no projects provided',
        asProvidedBy: () => [],
        expectTheseInvocations: (_) => []);

    testCase(
        thatWhen: 'a single project has no dependencies',
        asProvidedBy: () => [aProject('project1')],
        expectTheseInvocations: (Iterable<Project> projects) =>
            [new TestProcessInvocation(projects.first, const [])]);

//    group('for one project with no dependencies', () {
//      MockProject project1;
//
//      setUp(() {
//        project1 = new MockProject('project1', new PubSpec());
//        scheduleForProjects([project1]);
//      });
//
//      test('calls processor once', () {
//        schedule(() => expect(processor.invocations, hasLength(1)));
//      });
//
//      test('calls processor once with expected project', () {
//        schedule(() =>
//            expect(processor.invocations.first.project, equals(project1)));
//      });
//
//      test('calls processor once with no dependencies', () {
//        schedule(
//            () => expect(processor.invocations.first.dependencies, isEmpty));
//      });
//    });

  });
}

class TestProcessor {
  final List<TestProcessInvocation> invocations = [];
  call(Project project, Iterable<Project> dependencies) {
    invocations.add(new TestProcessInvocation(project, dependencies));
  }

  static createTests(
      TestProcessor processor(), List<TestProcessInvocation> expected()) {
    test('has expected number of invocations', () {
      schedule(
          () => expect(processor().invocations, hasLength(expected().length)));
    });

    group('each invocation matches expectation', () {
      for (int i = 0; i < expected().length; i++) {

        // TODO: need to rework this with ordered equals or something
        // as we can't create the expected up front so don't know how
        // many in the list

        TestProcessInvocation.createTests(
            () => processor().invocations[i], expected()[i]);
      }
    });
  }
}

class TestProcessInvocation {
  final Project project;
  final Iterable<Project> dependencies;

  TestProcessInvocation(this.project, this.dependencies);

  static createTests(
      TestProcessInvocation actual(), TestProcessInvocation expected()) {
    test('invocation has expected project', () {
      schedule(() => expect(actual().project, equals(expected.project)));
    });

    test('invocation has expected dependencies', () {
      schedule(() => expect(
          actual().dependencies, unorderedEquals(expected.dependencies)));
    });
  }
}

class MockProject extends Mock implements Project {
  MockProject(String name, PubSpec pubSpec) {
    when(this.name).thenReturn(name);
    when(this.pubspec).thenReturn(new Future.value(pubSpec));
  }
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

//foo() {
//  testCase(
//      thatWhen: 'no projects provided',
//      asProvidedBy: () => [],
//      expectTheseInvocations: () => []);
//}

testCase({String thatWhen, Iterable<Project> asProvidedBy(),
    List<TestProcessInvocation> expectTheseInvocations(
        Iterable<Project> projects)}) {
  TestProcessor processor;
  Iterable<Project> theProjects;

  scheduleForProjects(Iterable<Project> projects()) {
    return schedule(() async {
      theProjects = projects();
      processor = new TestProcessor();
      final DependencyGraph graph =
          await getDependencyGraph(theProjects.toSet());
      return graph.depthFirst(processor);
    });
  }

  setUpForProjects(Iterable<Project> projects()) {
    setUp(() => scheduleForProjects(projects));
  }

  group('when $thatWhen', () {
    setUpForProjects(asProvidedBy);
    TestProcessor.createTests(
        () => processor, () => expectTheseInvocations(theProjects));
  });
}

Project aProject(String name,
    {Iterable<PathReference> pathDependencies: const []}) {
  final dependencies = {};
  pathDependencies.forEach((pd) {
    // WARNING: only makes sense if path == name
    dependencies[pd.path] = pd;
  });

  return new MockProject(
      name, new PubSpec(name: name, dependencies: dependencies));
}

class TestPrecondition {
  String description;
//  String description;
}
