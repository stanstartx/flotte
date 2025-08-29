// tools/paren_checker_line.dart

import 'dart:io';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart paren_checker_line.dart <file.dart>');
    exit(1);
  }

  final file = File(args[0]);
  if (!await file.exists()) {
    print('File not found: ${args[0]}');
    exit(1);
  }

  final lines = await file.readAsLines();

  int roundBalance = 0;
  int curlyBalance = 0;

  print('Checking parentheses () and braces {} balance line by line...\n');

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];

    final openParens = RegExp(r'\(').allMatches(line).length;
    final closeParens = RegExp(r'\)').allMatches(line).length;
    final openBraces = RegExp(r'\{').allMatches(line).length;
    final closeBraces = RegExp(r'\}').allMatches(line).length;

    roundBalance += openParens - closeParens;
    curlyBalance += openBraces - closeBraces;

    if (roundBalance < 0) {
      print('⚠️  Too many ")" at line ${i + 1}');
      roundBalance = 0; // Reset to keep tracking
    }

    if (curlyBalance < 0) {
      print('⚠️  Too many "}" at line ${i + 1}');
      curlyBalance = 0;
    }

    if (openParens > 0 || closeParens > 0) {
      print('Line ${i + 1}: ( +$openParens, ) -$closeParens, Balance: $roundBalance');
    }
  }

  print('\nFinal result:');
  print('Parentheses balance: $roundBalance');
  print('Braces balance:     $curlyBalance');

  if (roundBalance != 0) {
    print('❌ Unbalanced parentheses — likely missing ${roundBalance.abs()} ")"');
  }
  if (curlyBalance != 0) {
    print('❌ Unbalanced braces');
  }
}

