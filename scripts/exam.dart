import 'package:flutter/material.dart';
import 'result.dart'; // Import result.dart to navigate
import 'openai_service.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ExamPage extends StatefulWidget {
  final Map<String, dynamic> examData;
  final Map<String, dynamic> metadata;

  const ExamPage({super.key, required this.examData, required this.metadata});

  @override
  _ExamPageState createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  // State for handling MCQ selections
  Map<int, Set<int>> multiAnswerSelections = {};
  Map<int, int?> singleAnswerSelections = {};
  Map<int, String> shortAnswerResponses = {};
  Map<int, List<Map<String, String>>> rightOptionsMap =
      {}; // Store user pairs per question
  Map<String, dynamic> userResponses = {};

  @override
  void initState() {
    super.initState();
    // Extract `rightOptions` from the `matching` question type if it exists
    if (widget.examData['questions'] != null) {
      List<dynamic> questions = widget.examData['questions'];
      for (int index = 0; index < questions.length; index++) {
        var question = questions[index];
        if (question['type'] == 'Matching' &&
            question['right_options'] != null &&
            question['left_options'] != null) {
          List<String> leftOptions =
              List<String>.from(question['left_options']);
          List<String> rightOptions =
              List<String>.from(question['right_options']);

          // Create pairs of left and right options
          List<Map<String, String>> pairs = [];
          for (int i = 0; i < leftOptions.length; i++) {
            pairs.add({
              "leftOption": leftOptions[i],
              "rightOption": rightOptions.length > i ? rightOptions[i] : "",
            });
          }

          rightOptionsMap[index] = pairs; // Store the pairs in the map
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Questions"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...buildQuestions(),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _submitExam,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: Text("Submit"),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildQuestions() {
    List<Widget> questionWidgets = [];
    int questionIndex = 0;

    for (var question in widget.examData['questions']) {
      String type = question['type'];
      if (type == 'Multi-Answer MCQs') {
        questionWidgets.add(
          buildMultiAnswerMCQ(question, questionIndex),
        );
      } else if (type == 'Single-Answer MCQs') {
        questionWidgets.add(
          buildSingleAnswerMCQ(question, questionIndex),
        );
      } else if (type == 'True/False') {
        questionWidgets.add(
          buildTrueFalseQuestion(question, questionIndex),
        );
      } else if (type == 'Short Answer') {
        questionWidgets.add(
          buildShortAnswerQuestion(question, questionIndex),
        );
      } else if (type == 'Matching') {
        questionWidgets.add(
          buildMatchingQuestion(question, questionIndex), // Pass index
        );
      } else {
        // Fallback widget for unrecognized question types
        questionWidgets.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              "Unsupported question type: $type",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        );
      }

      questionIndex++;
    }

    return questionWidgets;
  }

  Widget buildMultiAnswerMCQ(Map<String, dynamic> question, int questionIndex) {
    List<String> options = List<String>.from(question['options']);
    multiAnswerSelections[questionIndex] ??= {};

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Column(
            children: options.asMap().entries.map((entry) {
              int optionIndex = entry.key;
              String option = entry.value;
              return CheckboxListTile(
                value:
                    multiAnswerSelections[questionIndex]!.contains(optionIndex),
                onChanged: (bool? selected) {
                  setState(() {
                    if (selected == true) {
                      multiAnswerSelections[questionIndex]!.add(optionIndex);
                    } else {
                      multiAnswerSelections[questionIndex]!.remove(optionIndex);
                    }
                  });
                },
                title: Text(option),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildSingleAnswerMCQ(
      Map<String, dynamic> question, int questionIndex) {
    List<String> options = List<String>.from(question['options']);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Column(
            children: options.asMap().entries.map((entry) {
              int optionIndex = entry.key;
              String option = entry.value;
              return RadioListTile<int>(
                value: optionIndex,
                groupValue: singleAnswerSelections[questionIndex],
                onChanged: (int? selected) {
                  setState(() {
                    singleAnswerSelections[questionIndex] = selected;
                  });
                },
                title: Text(option),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildTrueFalseQuestion(
      Map<String, dynamic> question, int questionIndex) {
    // Ensure options are set to ['True', 'False'] if `question['options']` is null or not a List
    List<String> options = (question['options'] is List<String>)
        ? List<String>.from(question['options'])
        : ['True', 'False'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Column(
            children: options.asMap().entries.map((entry) {
              int optionIndex = entry.key;
              String option = entry.value;
              return RadioListTile<int>(
                value: optionIndex,
                groupValue: singleAnswerSelections[questionIndex],
                onChanged: (int? selected) {
                  setState(() {
                    singleAnswerSelections[questionIndex] = selected;
                  });
                },
                title: Text(option),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget buildShortAnswerQuestion(
      Map<String, dynamic> question, int questionIndex) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question['question'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextField(
            onChanged: (value) {
              setState(() {
                shortAnswerResponses[questionIndex] = value;
              });
            },
            decoration: const InputDecoration(
              hintText: "Type your answer here...",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  List<String> userRightOptions = [];

  Widget buildMatchingQuestion(
      Map<String, dynamic> questionData, int questionIndex) {
    List<String> leftOptions = List<String>.from(questionData['left_options']);
    List<String> initialRightOptions = rightOptionsMap[questionIndex]
            ?.map((pair) => pair['rightOption'] ?? "")
            .toList() ??
        [];
    userRightOptions = List<String>.from(
        initialRightOptions); // Initialize with current rightOptions

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            questionData['question'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: leftOptions.map((item) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child:
                              Text(item, style: const TextStyle(fontSize: 16)),
                        ),
                        const Divider(color: Colors.grey),
                      ],
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: userRightOptions
                      .asMap()
                      .entries
                      .map((entry) => ListTile(
                            key: ValueKey(entry.key),
                            title: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(entry.value),
                            ),
                          ))
                      .toList(),
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = userRightOptions.removeAt(oldIndex);
                      userRightOptions.insert(newIndex, item);

                      // Update the user pairs in rightOptionsMap
                      List<Map<String, String>> userPairs = [];
                      for (int i = 0; i < leftOptions.length; i++) {
                        userPairs.add({
                          "leftOption": leftOptions[i],
                          "rightOption": i < userRightOptions.length
                              ? userRightOptions[i]
                              : "",
                        });
                      }
                      rightOptionsMap[questionIndex] = userPairs;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submitExam() async {
    // Validate that all questions are answered
    bool isAllAnswered = true;
    List<dynamic> questions = widget.examData['questions'];

    for (int i = 0; i < questions.length; i++) {
      String type = questions[i]['type'];

      if (type == 'Multi-Answer MCQs') {
        // No specific validation needed as user can choose multiple or none
      } else if (type == 'Single-Answer MCQs' || type == 'True/False') {
        if (singleAnswerSelections[i] == null) {
          isAllAnswered = false;
          break;
        }
      } else if (type == 'Short Answer') {
        if (shortAnswerResponses[i] == null ||
            shortAnswerResponses[i]!.trim().isEmpty) {
          isAllAnswered = false;
          break;
        }
      }
    }

    if (!isAllAnswered) {
      // Show error dialog if not all questions are answered
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Incomplete Exam"),
          content: Text(
              "Please answer all required questions before submitting.$questions"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 15),
                Text("Submitting and evaluating your exam...")
              ],
            ),
          ),
        );
      },
    );

    // Collect all answers in a structured format
    userResponses = {
      'multiAnswerSelections': multiAnswerSelections,
      'singleAnswerSelections': singleAnswerSelections,
      'shortAnswerResponses': shortAnswerResponses,
      'matchingAnswers': rightOptionsMap, // Use rightOptionsMap for matching
    };

    // Perform the evaluation
    final Map<int, Map<String, dynamic>> shortAnswerEvaluations =
        await _evaluateShortAnswers();

    // Close the loading dialog
    Navigator.of(context).pop();

    // Navigate to the ResultPage with the exam data and user responses
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultPage(
          examData: widget.examData,
          userResponses: userResponses,
          metadata: widget.metadata,
          shortAnswerEvaluations: shortAnswerEvaluations,
        ),
      ),
    );
  }

  String _buildShortAnswerPrompt(List<Map<String, dynamic>> details) {
    StringBuffer prompt = StringBuffer();
    prompt.write("Evaluate my answers and provide marks:\n");
    prompt.write(
        "Return the result in strict JSON format only. Do not include any explanations or additional text.\n");
    prompt.write("The JSON should have the following structure:\n");

    for (var detail in details) {
      prompt.write("\n- Question Index: ${detail['index']}:\n");
      prompt.write("- Question: \"${detail['question']}\"\n");
      prompt.write("- Maximum Marks: ${detail['max_marks']}\n");
      prompt.write("- Correct Answer: \"${detail['correct_answer']}\"\n");
      prompt.write("- User's Answer: \"${detail['user_answer']}\"\n");
    }
    String sampleSAQEvaluation = '''
{
  "3": {
    "marks_awarded": 1.0,
    "explanation": "The answer is partially correct. It mentions that widgets are used to build the UI, which is true, but it does not fully explain that widgets are the basic building blocks of a Flutter app."
  }
}
''';
    prompt.write(
        "\nRespond in JSON format. Example response $sampleSAQEvaluation\n");
    prompt.write(
        "The 3 in the example response represents the index of the question, which is supposed to be provided to you. So, keep it the same for consistency.\n\n");

    prompt.write(
        "Your explanation must be in the same language as my answers\n\n");
    return prompt.toString();
  }

  // Function to get marks for a question type from metadata
  double _getMarksForQuestion(int questionIndex) {
    List<dynamic>? questions = widget.examData['questions'];
    if (questions != null && questionIndex < questions.length) {
      double marks =
          (questions[questionIndex]['marks'] as num?)?.toDouble() ?? 1.0;
      return marks;
    }
    return 1.0; // Default value if marks not specified
  }

  Future<Map<int, Map<String, dynamic>>> _evaluateShortAnswers() async {
    List<Map<String, dynamic>> shortAnswerDetails = [];
    List<dynamic>? questions = widget.examData['questions'];
    int questionIndex = 0;

    if (questions != null) {
      for (var question in questions) {
        if (question['type'] == 'Short Answer') {
          String correctAnswer = question['correct_answer'];
          String userAnswer = shortAnswerResponses[questionIndex] ?? "";
          double maxMarks = _getMarksForQuestion(questionIndex);
          String questionText = question['question'];

          shortAnswerDetails.add({
            'index': questionIndex,
            'question': questionText,
            'max_marks': maxMarks,
            'correct_answer': correctAnswer,
            'user_answer': userAnswer,
          });
        }
        questionIndex++;
      }
    }

    // If there are no short answer questions, return an empty evaluation map
    if (shortAnswerDetails.isEmpty) return {};

    String prompt = _buildShortAnswerPrompt(shortAnswerDetails);
    String model = 'gpt-4';
    OpenAIService openAIService =
        OpenAIService(dotenv.env['OPENAI_API_KEY']!, model);

    Map<String, dynamic>? evaluationResults =
        await openAIService.getResponse(prompt);

    Map<int, Map<String, dynamic>> shortAnswerEvaluations = {};
    evaluationResults!.forEach((key, value) {
      int index = int.parse(key);
      shortAnswerEvaluations[index] = {
        'marks_awarded': value['marks_awarded'] ?? 0.0,
        'explanation': value['explanation'] ?? 'No explanation provided',
      };
    });
    print("shortAnswerEvaluations: $shortAnswerEvaluations\n\n");
    return shortAnswerEvaluations;
  }
}
