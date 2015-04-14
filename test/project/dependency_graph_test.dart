library devops.project.dependency.test;

import 'package:devops/src/dependency_graph.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:devops/src/project.dart';

main() {
  TestProcessor processor;

  group('depthFirst', () {
    setUpForProjects(Iterable<Project> projects) {
      setUp(() {
        return schedule(() async {
          processor = new TestProcessor();
          final DependencyGraph graph =
              await getDependencyGraph(projects.toSet());
          return graph.depthFirst(processor);
        });
      });
    }

    group('for empty projects', () {
      setUpForProjects([]);

      test('does not call processor', () {
        schedule(() => expect(processor.invocations, isEmpty));
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
