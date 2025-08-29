// tools/paren_checker.dart

import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart paren_checker.dart <file.dart>');
    exit(1);
  }

  final file = File(args[0]);
  if (!await file.exists()) {
    print('File not found: ${args[0]}');
    exit(1);
  }

  final lines = await file.readAsLines();
  int roundOpen = 0, roundClose = 0;
  int curlyOpen = 0, curlyClose = 0;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    roundOpen += RegExp(r'\(').allMatches(line).length;
    roundClose += RegExp(r'\)').allMatches(line).length;
    curlyOpen += RegExp(r'\{').allMatches(line).length;
    curlyClose += RegExp(r'\}').allMatches(line).length;

    if (roundClose > roundOpen) {
      print('⚠️  Too many ")" at line ${i + 1}');
    }
    if (curlyClose > curlyOpen) {
      print('⚠️  Too many "}" at line ${i + 1}');
    }
  }

  print('\nParentheses: ( = $roundOpen, ) = $roundClose');
  print('Braces:      { = $curlyOpen, } = $curlyClose');

  if (roundOpen != roundClose) {
    print('❌ Unbalanced parentheses');
  }
  if (curlyOpen != curlyClose) {
    print('❌ Unbalanced braces');
  }
}

