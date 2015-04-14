library devops.project.dependency.test;

import 'package:devops/src/dependency_graph.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:devops/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:devops/src/pubspec/pubspec.dart';
import 'dart:async';

main() {
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
      setUp(() {
        return scheduleForProjects(projects);
      });
    }

    group('for empty projects', () {
      setUpForProjects([]);

      test('does not call processor', () {
        schedule(() => expect(processor.invocations, isEmpty));
      });
    });

    group('for one project with no dependencies', () {
      MockProject project1;

      setUp(() {
        project1 = new MockProject(new PubSpec());
        scheduleForProjects([project1]);
      });

      test('calls processor once', () {
        schedule(() => expect(processor.invocations, hasLength(1)));
      });

      test('calls processor once with expected project', () {
        schedule(() =>
            expect(processor.invocations.first.project, equals(project1)));
      });

      test('calls processor once with no dependencies', () {
        schedule(
            () => expect(processor.invocations.first.dependencies, isEmpty));
      });
    });
  });
}

class TestProcessor {
  final List<TestProcessInvocation> invocations = [];
  call(Project project, Iterable<Project> dependencies) {
    invocations.add(new TestProcessInvocation(project, dependencies));
  }
}

class TestProcessInvocation {
  final Project project;
  final Iterable<Project> dependencies;

  TestProcessInvocation(this.project, this.dependencies);
}

class MockProject extends Mock implements Project {
  MockProject(PubSpec pubSpec) {
    when(this.pubspec).thenReturn(new Future.value(pubSpec));
  }
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
