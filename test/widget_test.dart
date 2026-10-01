// Widget tests for the To-Do app.
//
// These tests do NOT use Firebase. We use tiny "fake" BLoCs that start in a
// state we choose and simply record every event the UI sends to them.
// That lets us test: UI -> events, and state -> UI.
//
// Note: relative imports are used so the file works without knowing your
// package name. If you prefer, replace '../lib/' with 'package:your_app/'.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/features/auth/bloc/auth_event.dart';
import '../lib/features/auth/bloc/auth_state.dart';
import '../lib/features/auth/bloc/auth_bloc.dart' show AuthBloc;
import '../lib/features/auth/presentation/pages/login_page.dart';
import '../lib/features/tasks/bloc/task_event.dart';
import '../lib/features/tasks/bloc/task_state.dart';
import '../lib/features/tasks/bloc/task_bloc.dart' show TaskBloc;
import '../lib/features/tasks/data/task_model.dart';
import '../lib/features/tasks/presentation/pages/home_page.dart';

// ---------- Fakes ----------

class FakeAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  final List<AuthEvent> events = [];
  FakeAuthBloc([AuthState? initial]) : super(initial ?? Unauthenticated()) {
    on<AuthEvent>((event, emit) => events.add(event));
  }
}

class FakeTaskBloc extends Bloc<TaskEvent, TaskState> implements TaskBloc {
  final List<TaskEvent> events = [];
  FakeTaskBloc(TaskState initial) : super(initial) {
    on<TaskEvent>((event, emit) => events.add(event));
  }
}

// ---------- Helpers ----------

final milk = Task(
  id: '1',
  title: 'Buy milk',
  description: '2 liters',
  createdAt: DateTime(2026, 1, 1),
  dueDate: DateTime(2026, 12, 24),
);

Future<void> pumpLogin(WidgetTester tester, FakeAuthBloc bloc) {
  return tester.pumpWidget(MaterialApp(
    home: BlocProvider<AuthBloc>.value(value: bloc, child: const LoginPage()),
  ));
}

Future<void> pumpHome(
    WidgetTester tester, FakeTaskBloc taskBloc, FakeAuthBloc authBloc) {
  return tester.pumpWidget(MaterialApp(
    home: MultiBlocProvider(
      providers: [
        BlocProvider<TaskBloc>.value(value: taskBloc),
        BlocProvider<AuthBloc>.value(value: authBloc),
      ],
      child: const HomePage(),
    ),
  ));
}

void main() {
  group('LoginPage', () {
    testWidgets('shows email, password and login button', (tester) async {
      await pumpLogin(tester, FakeAuthBloc());

      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Password'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Login'), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
    });

    testWidgets('empty form shows validation errors and sends no event',
        (tester) async {
      final bloc = FakeAuthBloc();
      await pumpLogin(tester, bloc);

      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(bloc.events, isEmpty);
    });

    testWidgets('valid form sends LoginRequested', (tester) async {
      final bloc = FakeAuthBloc();
      await pumpLogin(tester, bloc);

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'secret1');
      await tester.tap(find.widgetWithText(FilledButton, 'Login'));
      await tester.pump();

      expect(bloc.events.single, const LoginRequested('a@b.com', 'secret1'));
    });

    testWidgets('shows a spinner and disables the button while loading',
        (tester) async {
      await pumpLogin(tester, FakeAuthBloc(AuthLoading()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });
  });

  group('HomePage', () {
    testWidgets('shows a spinner while tasks are loading', (tester) async {
      await pumpHome(tester, FakeTaskBloc(TaskLoading()), FakeAuthBloc());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "No tasks yet" when the list is empty', (tester) async {
      await pumpHome(
          tester, FakeTaskBloc(const TaskLoaded([])), FakeAuthBloc());
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('shows tasks with title, description and due date',
        (tester) async {
      await pumpHome(
          tester, FakeTaskBloc(TaskLoaded([milk])), FakeAuthBloc());

      expect(find.text('Buy milk'), findsOneWidget);
      expect(find.text('2 liters'), findsOneWidget);
      expect(find.textContaining('Due:'), findsOneWidget);
    });

    testWidgets('checkbox sends ToggleTaskCompletion', (tester) async {
      final bloc = FakeTaskBloc(TaskLoaded([milk]));
      await pumpHome(tester, bloc, FakeAuthBloc());

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      expect(bloc.events.single, ToggleTaskCompletion(milk));
    });

    testWidgets('delete asks for confirmation, then sends DeleteTask',
        (tester) async {
      final bloc = FakeTaskBloc(TaskLoaded([milk]));
      await pumpHome(tester, bloc, FakeAuthBloc());

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to delete this task?'),
          findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(bloc.events.single, const DeleteTask('1'));
    });

    testWidgets('cancel in the delete dialog sends nothing', (tester) async {
      final bloc = FakeTaskBloc(TaskLoaded([milk]));
      await pumpHome(tester, bloc, FakeAuthBloc());

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(bloc.events, isEmpty);
    });

    testWidgets('logout button sends LogoutRequested', (tester) async {
      final auth = FakeAuthBloc();
      await pumpHome(tester, FakeTaskBloc(const TaskLoaded([])), auth);

      await tester.tap(find.byIcon(Icons.logout));
      await tester.pump();

      expect(auth.events.single, isA<LogoutRequested>());
    });

    testWidgets('+ button opens Add Task; empty title is rejected',
        (tester) async {
      final bloc = FakeTaskBloc(const TaskLoaded([]));
      await pumpHome(tester, bloc, FakeAuthBloc());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Add Task'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      expect(find.text('Title is required'), findsOneWidget);
      expect(bloc.events, isEmpty);
    });

    testWidgets('Add Task with a title sends AddTask', (tester) async {
      final bloc = FakeTaskBloc(const TaskLoaded([]));
      await pumpHome(tester, bloc, FakeAuthBloc());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Title'), 'Walk the dog');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      final event = bloc.events.single as AddTask;
      expect(event.task.title, 'Walk the dog');
    });
  });
}