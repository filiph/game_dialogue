import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:jenny/jenny.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dialogue Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Yard Spinner Dialogue'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with DialogueView {
  YarnProject? _project;

  DialogueRunner? _dialogueRunner;

  DialogueLine? _currentLine;

  bool _dialogueFinished = false;

  Completer<bool>? _finishedReadingCompleter;

  @override
  Widget build(BuildContext context) {
    final line = _currentLine;
    if (line == null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text('Loading...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_dialogueFinished)
            FilledButton(
              onPressed: () => setState(() {
                _dialogueFinished = false;
                _initYarn();
              }),
              child: Text('Restart'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: <Widget>[
              Text(line.character?.name ?? ''),
              Card(
                color: Theme.of(context).colorScheme.inversePrimary,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    line.text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _finishedReadingCompleter != null
          ? FloatingActionButton(
              onPressed: _finishReadingLine,
              tooltip: 'Next',
              child: const Icon(Icons.arrow_forward),
            )
          : null,
    );
  }

  @override
  void initState() {
    super.initState();
    _initYarn();
  }

  @override
  Future<int?> onChoiceStart(DialogueChoice choice) {
    final completer = Completer<int>();

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            spacing: 20,
            children: [
              for (final (index, option) in choice.options.indexed)
                OutlinedButton(
                  onPressed: option.isAvailable
                      ? () {
                          completer.complete(index);
                          Navigator.pop(context);
                        }
                      : null,
                  child: Text(option.text),
                )
            ],
          ),
        );
      },
    );

    return completer.future;
  }

  @override
  FutureOr<void> onDialogueFinish() {
    setState(() {
      _dialogueFinished = true;
    });
  }

  @override
  Future<bool> onLineStart(DialogueLine line) {
    assert(_finishedReadingCompleter == null);
    final completer = Completer<bool>();

    setState(() {
      _currentLine = line;
    });

    _finishedReadingCompleter = completer;
    return completer.future;
  }

  void _achievementCommand(String achievement) {
    _showSnackBar('achieved $achievement');
  }

  void _finishReadingLine() {
    final completer = _finishedReadingCompleter!;
    completer.complete(true);
    setState(() {
      _finishedReadingCompleter = null;
    });
  }

  String _getTimeOfDay() {
    return switch (DateTime.now().hour) {
      < 10 => 'morning',
      > 12 && < 17 => 'afternoon',
      >= 17 => 'evening',
      _ => 'day',
    };
  }

  void _giveCommand(String itemName) {
    _showSnackBar('$itemName given');
  }

  void _initYarn() async {
    final script =
        await DefaultAssetBundle.of(context).loadString('assets/project.yarn');

    _project = YarnProject()
      ..functions.addFunction0('time_of_day', _getTimeOfDay)
      ..functions.addFunction0('luck', () => Random().nextInt(100))
      ..commands.addCommand1('give', _giveCommand)
      ..commands.addCommand1('take', _takeCommand)
      ..commands.addCommand1('achievement', _achievementCommand)
      ..parse(script);
    _dialogueRunner = DialogueRunner(
      yarnProject: _project!,
      dialogueViews: [this],
    );
    _dialogueRunner!.startDialogue('Slughorn_encounter');
  }

  void _showSnackBar(String content) => ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(content)));

  void _takeCommand(String itemName) {
    _showSnackBar('$itemName taken');
  }
}
