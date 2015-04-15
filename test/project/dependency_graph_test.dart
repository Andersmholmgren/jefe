library devops.project.dependency.test;

import 'package:devops/src/dependency_graph.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:devops/src/project.dart';
import 'package:devops/src/pubspec/pubspec.dart';
import 'package:devops/src/pubspec/dependency.dart';
import 'package:logging/logging.dart';
import 'package:devops/src/project_impl.dart';
import 'dart:io';

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
    group('when no projects provided', () =>
        expectThat(withTheseProjects: () => [], weGetTheseInvocations: []));

    group('for a single project that has no dependencies', () {
      final project1 = aProject('project1');

      expectThat(
          withTheseProjects: () => [project1],
          weGetTheseInvocations: [
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
  call(Project project, Iterable<Project> dependencies) {
    invocations.add(new TestProcessInvocation(project, dependencies));
  }

  static createTests(
      TestProcessor processor(), List<TestProcessInvocationFactory> expected) {
    test('has expected number of invocations', () {
      schedule(
          () => expect(processor().invocations, hasLength(expected.length)));
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
      schedule(() => expect(actual().project, equals(expected().project)));
    });

    test('invocation has expected dependencies', () {
      schedule(() => expect(
          actual().dependencies, unorderedEquals(expected().dependencies)));
    });
  }
}

expectThat({String thatWhen, Iterable<Project> withTheseProjects(),
    List<TestProcessInvocationFactory> weGetTheseInvocations}) {
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

  setUpForProjects(withTheseProjects);
  TestProcessor.createTests(() => processor, weGetTheseInvocations);
}

Project aProject(String name, {Iterable<Project> dependencies: const []}) =>
    __aProject(name,
        pathDependencies: dependencies.map((p) => new PathReference(p.name)));

Project __aProject(String name,
    {Iterable<PathReference> pathDependencies: const []}) {
  final dependencies = {};
  pathDependencies.forEach((pd) {
    // WARNING: only makes sense if path == name
    dependencies[pd.path] = pd;
  });

  return new ProjectImpl(name, new Directory(name),
      new PubSpec(name: name, dependencies: dependencies));
}
