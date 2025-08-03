import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final Map<String, dynamic> examData;
  final Map<String, dynamic> userResponses;
  final Map<String, dynamic> metadata;
  final Map<int, Map<String, dynamic>> shortAnswerEvaluations;

  const ResultPage({
    super.key,
    required this.examData,
    required this.userResponses,
    required this.metadata,
    required this.shortAnswerEvaluations,
  });

  @override
  Widget build(BuildContext context) {
    print("Metadata in ResultPage: $metadata"); // Debugging print statement

    return Scaffold(
      appBar: AppBar(title: const Text("Results")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildTotalExamMarks(), // Display total exam mark
          const Divider(),
          ...buildResults(), // Display each question result
        ],
      ),
    );
  }

  Widget buildTotalExamMarks() {
    double totalExamMarks = _calculateTotalExamMarks();
    double totalMarksObtained = _calculateTotalMarksObtained();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        "Total Exam Marks: ${totalMarksObtained.toStringAsFixed(2)} / ${totalExamMarks.toStringAsFixed(2)}",
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }

  List<Widget> buildResults() {
    List<Widget> resultsWidgets = [];
    List<dynamic>? questions = examData['questions'];
    int questionIndex = 0;

    if (questions == null) {
      return [const Text("No questions available.")];
    }

    for (var question in questions) {
      String type = question['type'] ?? '';
      String userAnswerText = "";
      String correctAnswerText = "";
      bool isCorrect = false;
      List<Widget> additionalInfo = [];
      List<Widget> additionalInfoSAQ = [];
      double marksForQuestion = _getMarksForQuestion(type, questionIndex);

      double obtainedMarks = _calculateMarksForQuestion(
        question,
        type,
        questionIndex,
        marksForQuestion,
      );

      if (type == 'Multi-Answer MCQs') {
        // Handle Multi-Answer MCQs
        Set<int> userSelections =
            userResponses['multiAnswerSelections']?[questionIndex] ?? {};
        List<String> correctAnswers =
            List<String>.from(question['correct_answers'] ?? []);
        List<dynamic> userSelectedOptions = userSelections
            .map((index) => question['options']?[index] ?? "Unknown")
            .toList();

        userAnswerText = userSelectedOptions.join(", ");
        correctAnswerText = correctAnswers.join(", ");
        isCorrect = obtainedMarks == marksForQuestion;
      } else if (type == 'Single-Answer MCQs' || type == 'True/False') {
        int? userSelection =
            userResponses['singleAnswerSelections']?[questionIndex];
        if (userSelection != null) {
          // Provide default options for True/False questions
          if (type == 'True/False' && question['options'] == null) {
            question['options'] = ["True", "False"];
          }
          userAnswerText = question['options'][userSelection];
          correctAnswerText = question['correct_answer'];
          isCorrect = (userAnswerText == correctAnswerText);
          obtainedMarks = isCorrect ? marksForQuestion : 0;
        } else {
          userAnswerText = "Not Selected";
          correctAnswerText = question['correct_answer'] ?? "Unavailable";
        }
      } else if (type == 'Short Answer') {
        // Handle Short Answer
        userAnswerText =
            userResponses['shortAnswerResponses']?[questionIndex] ?? "";
        correctAnswerText = question['correct_answer'] ?? "";
        if (shortAnswerEvaluations.containsKey(questionIndex)) {
          obtainedMarks = shortAnswerEvaluations[questionIndex]
                  ?['marks_awarded'] ??
              obtainedMarks;
          String explanation = shortAnswerEvaluations[questionIndex]
                  ?['explanation'] ??
              "No explanation provided";
          additionalInfoSAQ.add(Text("Explanation: $explanation"));
        }
      } else if (type == 'Matching') {
        List<Map<String, String>> userPairs =
            userResponses['matchingAnswers']?[questionIndex] ?? [];
        List<Map<String, String>> correctPairs = [];

        for (int i = 0; i < (question['left_options']?.length ?? 0); i++) {
          correctPairs.add({
            "leftOption": question['left_options'][i],
            "rightOption": question['right_options'][i],
          });
        }

        List<Widget> matchingPairs = [];
        for (int i = 0; i < correctPairs.length; i++) {
          String userRight = userPairs.length > i
              ? userPairs[i]['rightOption'] ?? "Not Selected"
              : "Not Selected";
          String correctRight = correctPairs[i]['rightOption'] ?? "";

          bool pairIsCorrect = userRight == correctRight;

          matchingPairs.add(
            Row(
              children: [
                Icon(
                  pairIsCorrect ? Icons.check_circle : Icons.cancel,
                  color: pairIsCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  "Your Pair: ${correctPairs[i]['leftOption']} ->  $userRight.\n Correct Pair: ${correctPairs[i]['leftOption']} $correctRight)",
                  style: TextStyle(
                    color: pairIsCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        }
        additionalInfo = matchingPairs;
      }

      resultsWidgets.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 3,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (type != 'Matching') ...[
                  Icon(
                    obtainedMarks == marksForQuestion
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: obtainedMarks == marksForQuestion
                        ? Colors.green
                        : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    "Q: ${question['question']} (${obtainedMarks.toStringAsFixed(2)} / ${marksForQuestion.toStringAsFixed(2)} marks)",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              if (type == 'Matching') ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: additionalInfo,
                ),
              ] else ...[
                Text("Your Answer: $userAnswerText"),
                if (type != 'Short Answer')
                  Text("Correct Answer: $correctAnswerText"),
                if (type == 'Short Answer') ...additionalInfoSAQ,
              ],
            ],
          ),
        ),
      );

      questionIndex++;
    }

    return resultsWidgets;
  }

  double _calculateTotalExamMarks() {
    double totalMarks = 0;

    List<dynamic>? questions = examData['questions'];
    if (questions != null) {
      for (var question in questions) {
        double questionMarks = (question['marks'] as num?)?.toDouble() ?? 0.0;
        totalMarks += questionMarks;
      }
    }

    return totalMarks;
  }

  double _calculateTotalMarksObtained() {
    double totalMarks = 0;
    List<dynamic>? questions = examData['questions'];
    if (questions != null) {
      for (int i = 0; i < questions.length; i++) {
        String type = questions[i]['type'];
        double marksForQuestion = _getMarksForQuestion(type, i);
        totalMarks += _calculateMarksForQuestion(
          questions[i],
          type,
          i,
          marksForQuestion,
        );
      }
    }
    return totalMarks;
  }

  double _getMarksForQuestion(String type, int questionIndex) {
    List<dynamic>? questions = examData['questions'];
    if (questions != null && questionIndex < questions.length) {
      double marks =
          (questions[questionIndex]['marks'] as num?)?.toDouble() ?? 1.0;
      return marks;
    }
    return 1.0; // Default value if marks not specified
  }

  double _calculateMarksForQuestion(
    Map<String, dynamic> question,
    String type,
    int questionIndex,
    double marksForQuestion,
  ) {
    double obtainedMarks = marksForQuestion;

    if (type == 'Multi-Answer MCQs') {
      Set<int>? userSelections =
          userResponses['multiAnswerSelections']?[questionIndex] as Set<int>? ??
              {};
      List<String> correctAnswers =
          List<String>.from(question['correct_answers'] ?? []);
      int totalOptions = question['options']?.length ?? 0;
      double marksPerOption =
          totalOptions > 0 ? marksForQuestion / totalOptions : 0;

      for (int i = 0; i < totalOptions; i++) {
        bool isUserSelectionCorrect =
            correctAnswers.contains(question['options']?[i] ?? "");
        if ((userSelections.contains(i) && !isUserSelectionCorrect) ||
            (!userSelections.contains(i) && isUserSelectionCorrect)) {
          obtainedMarks -= marksPerOption;
        }
      }
    } else if (type == 'Single-Answer MCQs' || type == 'True/False') {
      // Existing logic remains the same
      int? userSelection =
          userResponses['singleAnswerSelections']?[questionIndex];
      String correctAnswer = question['correct_answer'] ?? "";
      if (userSelection != null &&
          userSelection < (question['options']?.length ?? 0)) {
        String userSelectedOption = question['options'][userSelection] ?? "";
        obtainedMarks =
            userSelectedOption == correctAnswer ? marksForQuestion : 0;
      } else {
        obtainedMarks = 0;
      }
    } else if (type == 'Short Answer') {
      // Use marks from shortAnswerEvaluations if available
      if (shortAnswerEvaluations.containsKey(questionIndex)) {
        obtainedMarks =
            shortAnswerEvaluations[questionIndex]?['marks_awarded'] ?? 0.0;
      } else {
        obtainedMarks = 0;
      }
    } else if (type == 'Matching') {
      // Implemented logic for matching questions
      List<Map<String, String>> userPairs =
          userResponses['matchingAnswers']?[questionIndex] ?? [];
      Map<String, String> correctMatchMap = {};
      for (int i = 0; i < (question['left_options']?.length ?? 0); i++) {
        correctMatchMap[question['left_options'][i]] =
            question['right_options'][i] ?? "";
      }

      double marksPerPair = correctMatchMap.isNotEmpty
          ? marksForQuestion / correctMatchMap.length
          : 0;
      obtainedMarks = 0; // Reset obtainedMarks for matching question

      // Compare user's selections with correct matches
      for (int i = 0; i < userPairs.length; i++) {
        String userLeft = userPairs[i]['leftOption'] ?? "";
        String userRight = userPairs[i]['rightOption'] ?? "";
        String correctRight = correctMatchMap[userLeft] ?? "";

        if (userRight == correctRight) {
          obtainedMarks += marksPerPair;
        }
      }
    }

    return obtainedMarks < 0 ? 0 : obtainedMarks;
  }
}
