import 'dart:async';
import 'package:flutter/material.dart';
import 'exam.dart';
import 'openai_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path/path.dart';
import 'dart:convert';

Future<String> extractTextFromPdfFiles(String filePath) async {
  File pdfFile = File(filePath);
  Uint8List bytes = await pdfFile.readAsBytes();

  // Load the PDF document
  final PdfDocument document = PdfDocument(inputBytes: bytes);

  // Extract text from the document
  String content = PdfTextExtractor(document).extractText();

  // Dispose the document after extraction
  document.dispose();

  return content;
}

// Function to send the generated questions to the `ExamScreen`
Future<void> sendToExam(
    BuildContext context,
    Map<String, dynamic> generatedQuestions,
    Map<String, dynamic> metadata) async {
  // Navigate to the ExamScreen and pass the generated questions
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>
          ExamPage(examData: generatedQuestions, metadata: metadata),
    ),
  );
}

Future<String> generatePrompt(Map<String, dynamic> questionTypes,
    List<String> files, String topic, String examType) async {
  // Sample metadata to guide the AI in structuring the exam
  String sampleMetadata = '''
{
  "questionTypes": {
    "Single-Answer MCQs": { "marks": 1.0, "number of questions": 1 },
    "Multi-Answer MCQs": { "marks": 1.5, "number of questions": 1 },
    "True/False": { "marks": 1.0, "number of questions": 1 },
    "Short Answer": { "marks": 2.0, "number of questions": 1 },
    "Matching": { "marks": 2.5, "number of questions": 1 }
  },
  "totalMarks": 8.0
}
''';

  // Sample exam structure to clarify JSON format for the model
  String sampleExam = '''{
    "questions": [
      {
        "type": "Single-Answer MCQs",
        "question": "What is Flutter?",
        "options": ["A web development framework", "A mobile development SDK", "A programming language", "A type of database"],
        "correct_answer": "A mobile development SDK"
      },
      {
        "type": "Multi-Answer MCQs",
        "question": "Select all programming languages:",
        "options": ["Python", "JavaScript", "HTML", "C++", "CSS"],
        "correct_answers": ["Python", "JavaScript", "C++"]
      },
      {
        "type": "True/False",
        "question": "Dart is a language primarily used for Flutter development.",
        "options": ["True", "False"],
        "correct_answer": "True"
      },
      {
        "type": "Short Answer",
        "question": "Explain the concept of widgets in Flutter.",
        "correct_answer": "Widgets are the basic building blocks of a Flutter app."
      },
      {
        "type": "Matching",
        "question": "Match the following items:",
        "left_options": ["Flutter", "React", "Angular"],
        "right_options": ["Mobile SDK", "Web Framework", "Web Framework"],
        "correct_matches": [
          {"left": "Flutter", "right": "Mobile SDK"},
          {"left": "React", "right": "Web Framework"},
          {"left": "Angular", "right": "Web Framework"}
        ]
      }
    ]
  }''';

  // Prompt assembly
  StringBuffer prompt = StringBuffer(
      "You are a helpful assistant. Generate an exam based on the given and settings. \n");
  prompt.write(
      "Generate the exam strictly in JSON format. Respond with only the JSON object, no extra text, explanations, or markdown.\n");

// Add sample metadata and sample exam structure as before

  if (files.isNotEmpty) {
    prompt.write(
        "All questions should be based on the provided file contents, and the questions must be in English.\n");
    prompt.write("Contents:\n");
    for (var file in files) {
      prompt.write(
          "- ${basename(file)}: ${await extractTextFromPdfFiles(file)}\n\n");
    }
  } else {
    prompt.write(
        "Generate questions on the topic of \"$topic\" using general knowledge and make the questions be in the same language as the title.\n\n");
  }

  if (examType == "Random") {
    int quantity = questionTypes['Random']?['number of questions'] ?? 0;
    int marks = questionTypes['Random']?['marks'] ?? 0;
    prompt.write(
        "Exam will have a random mix of question types.\nTotal Questions: $quantity, Total Marks: $marks.\n\n");
  } else if (questionTypes.isNotEmpty) {
    prompt.write("Question Types and Criteria that must be followed:\n");
    questionTypes.forEach((type, details) {
      int quantity = details['number of questions'];
      int marks = details['marks'];

      prompt.write("- $type: $quantity questions, $marks marks in total.\n");

      if (type == 'Multi-Answer MCQs') {
        prompt.write(
            "  * This type may have multiple correct answers. Confusing distractors are encouraged.\n");
      } else if (type == "Single-Answer MCQs") {
        prompt.write(
            "  * This type has only one correct answer. Distractors may be misleading but only one answer is correct.\n");
      } else if (type == 'Matching') {
        prompt.write(
            "You need to shuffle the options on right before returning them to confuse the student.\n");
      }
    });
  }

  // Adding sample metadata and exam for structure reference
  prompt.write("\nExam Metadata (for guidance):\n$sampleMetadata\n\n");
  prompt.write("Expected JSON Format for Response:\n$sampleExam\n\n");
  prompt.write(
      "\nPlease ensure each question includes all necessary fields. For 'Single-Answer MCQs' and 'True/False' questions, include the 'options' field as a list of possible answers.\n");

  return prompt.toString();
}

void assignMarksToQuestions(
    Map<String, dynamic> response, Map<String, dynamic> questionTypes) {
  Map<String, List<Map<String, dynamic>>> questionsByType = {};

  // Group questions by type
  for (var question in response['questions']) {
    String type = question['type'];
    if (!questionsByType.containsKey(type)) {
      questionsByType[type] = [];
    }
    questionsByType[type]!.add(question);
  }

  // For each type, get total marks and number of questions
  questionTypes.forEach((type, details) {
    if (questionsByType.containsKey(type)) {
      int numQuestions = questionsByType[type]!.length;
      double totalMarks = (details['marks'] as num?)?.toDouble() ?? 0.0;
      double marksPerQuestion = totalMarks / numQuestions;

      // Assign marks to each question
      for (var question in questionsByType[type]!) {
        question['marks'] = marksPerQuestion;
      }
    }
  });
}

Future<void> initiateGeneration(
    BuildContext context, Map<String, dynamic> initialExamData) async {
  print("Initiating generation with the following data:");
  print("Exam Data: $initialExamData");

  Map<String, dynamic> questionTypes =
      initialExamData["questionTypes"]?.cast<String, dynamic>() ?? {};
  List<String> fileContents = initialExamData["files"]?.cast<String>() ?? [];
  String topic = initialExamData['topic'] ?? "";
  String examType = initialExamData['examType'] ?? "";

  // Create a prompt
  String prompt =
      await generatePrompt(questionTypes, fileContents, topic, examType);

  // Initialize OpenAIService
  String apiKey = dotenv.env['OPENAI_API_KEY'] ?? "";
  String model = "gpt-4";

  OpenAIService openAIService = OpenAIService(apiKey, model);

  // // // Make API request
  Map<String, dynamic>? response = await openAIService.getResponse(prompt);

  if (response != null && response.containsKey('questions')) {
    print("Prompt $prompt");
    // Process the questions to assign 'marks' per question
    assignMarksToQuestions(response, initialExamData['questionTypes']);

    await sendToExam(context, response, initialExamData);
  } else {
    print("Failed to generate questions.");
  }
}
