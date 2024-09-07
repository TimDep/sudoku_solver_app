class SudokuSolution {
  final List<String> steps;
  final String solution;

  SudokuSolution({required this.steps, required this.solution});

  factory SudokuSolution.fromJson(Map<String, dynamic> json) {
    return SudokuSolution(
      steps: List<String>.from(json['steps']),
      solution: json['solution'],
    );
  }
}
