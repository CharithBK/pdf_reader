import 'package:flutter/material.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback onClicked;

  const ButtonWidget({
    Key? key,
    required this.text,
    required this.onClicked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(55),
          ),
          child: Text(text, style: const TextStyle(fontSize: 20)),
          onPressed: onClicked,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

}
