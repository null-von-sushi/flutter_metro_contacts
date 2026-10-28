import 'package:flutter/material.dart';
import '../other/accent_color.dart';

class LetterGridOverlay extends StatelessWidget {
  final List<String> letters;
  final ValueChanged<String> onLetterSelected;

  const LetterGridOverlay(
      {super.key, required this.letters, required this.onLetterSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemCount: letters.length,
              itemBuilder: (context, index) {
                final letter = letters[index];
                return GestureDetector(
                  onTap: () => onLetterSelected(letter),
                  child: Container(
                    color: AccentColor,
                    alignment: Alignment.center,
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}