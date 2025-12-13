// Location: lib/components/local_game/LocalNameInputDialog.dart

import 'package:flutter/material.dart';

// --- Wrapper Class (Keeps the original calling signature) ---
class LocalNameInputDialog {
  static void show({
    required BuildContext context,
    required String p1DefaultName,
    required String p2DefaultName,
    required Function(String p1Name, String p2Name) onNamesConfirmed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LocalNameInputWidget(
        p1DefaultName: p1DefaultName,
        p2DefaultName: p2DefaultName,
        onNamesConfirmed: onNamesConfirmed,
      ),
    );
  }
}

// --- Stateful Dialog Widget (Handles FocusNode Lifecycle) ---
class LocalNameInputWidget extends StatefulWidget {
  final String p1DefaultName;
  final String p2DefaultName;
  final Function(String p1Name, String p2Name) onNamesConfirmed;

  const LocalNameInputWidget({
    Key? key,
    required this.p1DefaultName,
    required this.p2DefaultName,
    required this.onNamesConfirmed,
  }) : super(key: key);

  @override
  State<LocalNameInputWidget> createState() => _LocalNameInputWidgetState();
}

class _LocalNameInputWidgetState extends State<LocalNameInputWidget> {
  late TextEditingController p1Controller;
  late TextEditingController p2Controller;
  late FocusNode p1Focus;
  late FocusNode p2Focus;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with default names
    p1Controller = TextEditingController(text: widget.p1DefaultName);
    p2Controller = TextEditingController(text: widget.p2DefaultName);

    // Initialize FocusNodes
    p1Focus = FocusNode();
    p2Focus = FocusNode();

    // Add listeners to clear the text on focus (if it's the default text)
    _addFocusClearListener(p1Controller, p1Focus, widget.p1DefaultName);
    _addFocusClearListener(p2Controller, p2Focus, widget.p2DefaultName);
  }

  @override
  void dispose() {
    // Dispose resources ONLY when the stateful widget is destroyed (dialog closed)
    p1Controller.dispose();
    p2Controller.dispose();
    p1Focus.dispose();
    p2Focus.dispose();
    super.dispose();
  }

  // Helper function to handle clearing default text on focus
  void _addFocusClearListener(
    TextEditingController controller, 
    FocusNode focusNode, 
    String defaultName,
  ) {
    focusNode.addListener(() {
      if (focusNode.hasFocus && controller.text == defaultName) {
        controller.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1F222B),
      title: const Text("Enter Player Names", style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView( // Add SingleChildScrollView to prevent dialog content overflow
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player 1 (White) Input
            TextField(
              controller: p1Controller,
              focusNode: p1Focus,
              decoration: InputDecoration(
                hintText: widget.p1DefaultName,
                hintStyle: TextStyle(color: Colors.white38), 
                labelText: 'Player 1 (White)',
                labelStyle: TextStyle(color: Colors.greenAccent.shade100),
                fillColor: Colors.white.withOpacity(0.1),
                filled: true,
                prefixIcon: Icon(Icons.person, color: Colors.greenAccent),
              ),
              style: TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 15),
            // Player 2 (Black) Input
            TextField(
              controller: p2Controller,
              focusNode: p2Focus,
              decoration: InputDecoration(
                hintText: widget.p2DefaultName,
                hintStyle: TextStyle(color: Colors.white38),
                labelText: 'Player 2 (Black)',
                labelStyle: TextStyle(color: Colors.pinkAccent.shade100),
                fillColor: Colors.white.withOpacity(0.1),
                filled: true,
                prefixIcon: Icon(Icons.person_outline, color: Colors.pinkAccent),
              ),
              style: TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            final newP1Name = p1Controller.text.trim().isEmpty ? widget.p1DefaultName : p1Controller.text.trim();
            final newP2Name = p2Controller.text.trim().isEmpty ? widget.p2DefaultName : p2Controller.text.trim();
            
            widget.onNamesConfirmed(newP1Name, newP2Name);
            Navigator.pop(context);
          },
          child: Text("Start Game", style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}