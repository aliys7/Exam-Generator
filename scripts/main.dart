import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'initiate_generation.dart';
import 'loading_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  try {
    await dotenv.load(fileName: ".env");
    runApp(ExamGeneratorApp());
  } catch (e) {
    print("Error loading .env file: $e");
    runApp(ExamGeneratorApp());
  }
}

class ExamGeneratorApp extends StatelessWidget {
  const ExamGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      restorationScopeId: "Test",
      title: 'Exam Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.lightBlue[300],
        scaffoldBackgroundColor: Colors.grey[200],
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.lightBlue[300],
          secondary: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue[300],
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue[300],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.lightBlue[300]!),
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      ),
      home: ExamForm(),
    );
  }
}

class ExamForm extends StatefulWidget {
  const ExamForm({super.key});

  @override
  _ExamFormState createState() => _ExamFormState();
}

class _ExamFormState extends State<ExamForm> {
  String? contentType = "General Knowledge";
  String? examType;
  String? mcqType = "Single Answer"; // Default to Single Answer MCQs
  bool showFilePicker = false;
  bool showRandomInputs = false;
  bool showCustomInputs = false;
  String? errorMessage;

  // Controllers and validation flags
  TextEditingController totalQuestionsController = TextEditingController();
  TextEditingController totalMarksController = TextEditingController();
  TextEditingController mcqQuestionsController = TextEditingController();
  TextEditingController mcqMarksController = TextEditingController();
  TextEditingController trueFalseQuestionsController = TextEditingController();
  TextEditingController trueFalseMarksController = TextEditingController();
  TextEditingController shortAnswerQuestionsController =
      TextEditingController();
  TextEditingController shortAnswerMarksController = TextEditingController();
  TextEditingController matchingQuestionsController = TextEditingController();
  TextEditingController matchingMarksController = TextEditingController();
  TextEditingController generalKnowledgeTopicController =
      TextEditingController();

  bool isFileUploaded = false;
  bool? isMCQSelected = false;
  bool? isTrueFalseSelected = false;
  bool? isShortAnswerSelected = false;
  bool? isMatchingSelected = false;

  // Track if fields are in error state
  bool mcqQuestionsError = false;
  bool mcqMarksError = false;
  bool trueFalseQuestionsError = false;
  bool trueFalseMarksError = false;
  bool shortAnswerQuestionsError = false;
  bool shortAnswerMarksError = false;
  bool matchingQuestionsError = false;
  bool matchingMarksError = false;

  Map<String, Map<int, int>>? questionTypes;
  List<String?>? files;
  FilePickerResult? filesPickerResult;

  // Helper function for validation
  bool _validateFields() {
    setState(() {
      errorMessage = null;
      mcqQuestionsError = mcqMarksError = false;
      trueFalseQuestionsError = trueFalseMarksError = false;
      shortAnswerQuestionsError = shortAnswerMarksError = false;
      matchingQuestionsError = matchingMarksError = false;
    });

    if (contentType == "Upload Content" && !isFileUploaded) {
      setState(() {
        errorMessage = "Please upload a file.";
      });
      return false;
    }

    if (showRandomInputs &&
        (totalQuestionsController.text.isEmpty ||
            totalMarksController.text.isEmpty)) {
      setState(() {
        errorMessage = "Please fill all the fields.";
      });
      return false;
    }

    bool hasError = false;

    if (isMCQSelected == true &&
        (mcqQuestionsController.text.isEmpty ||
            mcqMarksController.text.isEmpty)) {
      setState(() {
        if (mcqQuestionsController.text.isEmpty) mcqQuestionsError = true;
        if (mcqMarksController.text.isEmpty) mcqMarksError = true;
        hasError = true;
      });
    }

    if (isTrueFalseSelected == true &&
        (trueFalseQuestionsController.text.isEmpty ||
            trueFalseMarksController.text.isEmpty)) {
      setState(() {
        if (trueFalseQuestionsController.text.isEmpty) {
          trueFalseQuestionsError = true;
        }
        if (trueFalseMarksController.text.isEmpty) trueFalseMarksError = true;
        hasError = true;
      });
    }

    if (isShortAnswerSelected == true &&
        (shortAnswerQuestionsController.text.isEmpty ||
            shortAnswerMarksController.text.isEmpty)) {
      setState(() {
        if (shortAnswerQuestionsController.text.isEmpty) {
          shortAnswerQuestionsError = true;
        }
        if (shortAnswerMarksController.text.isEmpty) {
          shortAnswerMarksError = true;
        }
        hasError = true;
      });
    }

    if (isMatchingSelected == true &&
        (matchingQuestionsController.text.isEmpty ||
            matchingMarksController.text.isEmpty)) {
      setState(() {
        if (matchingQuestionsController.text.isEmpty) {
          matchingQuestionsError = true;
        }
        if (matchingMarksController.text.isEmpty) matchingMarksError = true;
        hasError = true;
      });
    }
    // Check if General Knowledge is selected and topic is empty
    if (contentType == "General Knowledge" &&
        generalKnowledgeTopicController.text.isEmpty) {
      setState(() {
        errorMessage = "Please enter a topic for General Knowledge.";
      });
      hasError = false;
    }

    if (hasError) {
      setState(() {
        errorMessage = "Please fill all selected question type fields.";
      });
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Generator"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
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
                const Text("Content Type:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("General Knowledge"),
                        value: "General Knowledge",
                        groupValue: contentType,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            contentType = value;
                            showFilePicker = false;
                            isFileUploaded = false;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("Upload Content"),
                        value: "Upload Content",
                        groupValue: contentType,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            contentType = value;
                            showFilePicker = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (showFilePicker)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: [
                              'pptx',
                              'ppt',
                              'pdf',
                              'doc',
                              'docx'
                            ],
                            allowMultiple:
                                true, // Enable multiple file selection
                          );
                          if (result != null) {
                            setState(() {
                              isFileUploaded = true;
                              files ??= [];

                              // Store the result in `filesPickerResult`
                              filesPickerResult = result;

                              files!.clear();
                              for (var file in result.files) {
                                files!.add(file.name);
                              }
                            });
                            print("Selected files: $files");
                          }
                        },
                        child: const Text("Choose Files"),
                      ),

                      // Display the list of selected file names
                      if (files != null && files!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            const Text(
                              "Uploaded Files:",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            ListView.builder(
                              shrinkWrap:
                                  true, // Prevents the ListView from taking infinite space
                              physics:
                                  const NeverScrollableScrollPhysics(), // Disable scrolling inside the ListView
                              itemCount: files!.length,
                              itemBuilder: (context, index) {
                                return Text(
                                  files![index]!,
                                  style: const TextStyle(color: Colors.black87),
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                if (contentType == "General Knowledge")
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: TextField(
                      controller: generalKnowledgeTopicController,
                      decoration: const InputDecoration(
                        labelText: "Enter Topic (e.g., Physics, Math, etc.)",
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                const Text("Exam Type:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("Random"),
                        value: "Random",
                        groupValue: examType,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            examType = value;
                            showRandomInputs = true;
                            showCustomInputs = false;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("Custom"),
                        value: "Custom",
                        groupValue: examType,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (value) {
                          setState(() {
                            examType = value;
                            showCustomInputs = true;
                            showRandomInputs = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (showRandomInputs)
                  Column(
                    children: [
                      TextField(
                        controller: totalQuestionsController,
                        decoration: const InputDecoration(
                          labelText: "Total Number of Questions",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: totalMarksController,
                        decoration: const InputDecoration(
                          labelText: "Total Marks",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                if (showCustomInputs)
                  Column(
                    children: [
                      _buildMCQType(),
                      _buildQuestionType(
                          "True/False",
                          isTrueFalseSelected,
                          trueFalseQuestionsController,
                          trueFalseMarksController, (value) {
                        setState(() {
                          isTrueFalseSelected = value ?? false;
                        });
                      },
                          errorState:
                              trueFalseQuestionsError || trueFalseMarksError),
                      _buildQuestionType(
                          "Short Answer",
                          isShortAnswerSelected,
                          shortAnswerQuestionsController,
                          shortAnswerMarksController, (value) {
                        setState(() {
                          isShortAnswerSelected = value ?? false;
                        });
                      },
                          errorState: shortAnswerQuestionsError ||
                              shortAnswerMarksError),
                      _buildQuestionType(
                          "Matching",
                          isMatchingSelected,
                          matchingQuestionsController,
                          matchingMarksController, (value) {
                        setState(() {
                          isMatchingSelected = value ?? false;
                        });
                      },
                          errorState:
                              matchingQuestionsError || matchingMarksError),
                    ],
                  ),
                const SizedBox(height: 20),
                if (errorMessage != null)
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      Map<String, dynamic> initialExamData = {
                        "examType": examType, // Random or Custom
                        "files":
                            <String>[], // Will populate if "Upload Content" is selected
                        "topic": generalKnowledgeTopicController.text.isNotEmpty
                            ? generalKnowledgeTopicController.text
                            : "", // Populate if "General Knowledge" is selected
                        "questionTypes": <String,
                            dynamic>{} // This will store the types and counts
                      };

                      // Check if all required fields are valid
                      if (_validateFields()) {
                        // Handling Random Exam Type
                        if (examType == "Random") {
                          int totalQuestions =
                              int.tryParse(totalQuestionsController.text) ?? 0;
                          int totalMarks =
                              int.tryParse(totalMarksController.text) ?? 0;

                          if (totalQuestions > 0 && totalMarks > 0) {
                            // Store random settings in `questionTypes`
                            initialExamData["questionTypes"] = {
                              "Random": {
                                "marks": totalMarks,
                                "number of questions": totalQuestions
                              }
                            };
                            initialExamData["topic"] =
                                generalKnowledgeTopicController.text;

                            // Navigate to Loading Screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoadingScreen()),
                            );

                            await initiateGeneration(context, initialExamData);
                          } else {
                            // Show error if random fields are not properly filled
                            setState(() {
                              errorMessage =
                                  "Please enter valid numbers for random exam.";
                            });
                          }
                          return; // Exit after handling random exam
                        }

                        // Handling Custom Exam Type
                        if (examType == "Custom") {
                          // Step 1: Validate and Store Exam Data in `initialExamData["questionTypes"]`

                          // Store MCQs if selected
                          if (isMCQSelected == true) {
                            String mcqTypeKey = mcqType == "Single Answer"
                                ? "Single-Answer MCQs"
                                : "Multi-Answer MCQs";
                            int quantity =
                                int.tryParse(mcqQuestionsController.text) ?? 0;
                            int marks =
                                int.tryParse(mcqMarksController.text) ?? 0;

                            if (quantity > 0 && marks > 0) {
                              initialExamData["questionTypes"][mcqTypeKey] = {
                                "marks": marks,
                                "number of questions": quantity
                              };
                            }
                          }

                          // Store True/False questions if selected
                          if (isTrueFalseSelected == true) {
                            int quantity = int.tryParse(
                                    trueFalseQuestionsController.text) ??
                                0;
                            int marks =
                                int.tryParse(trueFalseMarksController.text) ??
                                    0;

                            if (quantity > 0 && marks > 0) {
                              initialExamData["questionTypes"]["True/False"] = {
                                "marks": marks,
                                "number of questions": quantity
                              };
                            }
                          }

                          // Store Short Answer questions if selected
                          if (isShortAnswerSelected == true) {
                            int quantity = int.tryParse(
                                    shortAnswerQuestionsController.text) ??
                                0;
                            int marks =
                                int.tryParse(shortAnswerMarksController.text) ??
                                    0;

                            if (quantity > 0 && marks > 0) {
                              initialExamData["questionTypes"]
                                  ["Short Answer"] = {
                                "marks": marks,
                                "number of questions": quantity
                              };
                            }
                          }

                          // Store Matching questions if selected
                          if (isMatchingSelected == true) {
                            int quantity = int.tryParse(
                                    matchingQuestionsController.text) ??
                                0;
                            int marks =
                                int.tryParse(matchingMarksController.text) ?? 0;

                            if (quantity > 0 && marks > 0) {
                              initialExamData["questionTypes"]["Matching"] = {
                                "marks": marks,
                                "number of questions": quantity
                              };
                            }
                          }

                          // Check if at least one question type is selected
                          if (initialExamData["questionTypes"].isEmpty) {
                            setState(() {
                              errorMessage =
                                  "Please select at least one question type.";
                            });
                            return;
                          }

                          // Handle General Knowledge (No files uploaded)
                          if (contentType == "General Knowledge") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoadingScreen()),
                            );

                            await initiateGeneration(context, initialExamData);
                            return;
                          }

                          // Handle Upload Content scenario
                          if (contentType == "Upload Content" &&
                              isFileUploaded) {
                            // Populate file paths to `files` list
                            if (filesPickerResult != null) {
                              for (var file in filesPickerResult!.files) {
                                if (file.path != null) {
                                  initialExamData["files"].add(file.path!);
                                }
                              }
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoadingScreen()),
                            );

                            await initiateGeneration(context, initialExamData);
                            return;
                          }
                        }

                        // If nothing matches, set an error
                        setState(() {
                          errorMessage =
                              "Please ensure all fields are correctly filled.";
                        });
                      }
                    },
                    child: const Text("Generate Exam"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMCQType() {
    return Column(children: [
      CheckboxListTile(
        title: const Text("MCQs"),
        value: isMCQSelected,
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (value) {
          setState(() {
            isMCQSelected = value ?? false;
            if (isMCQSelected == true && mcqType == null) {
              mcqType = "Single Answer"; // Set default to Single Answer
            }
          });
        },
      ),
      if (isMCQSelected == true)
        Column(children: [
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text("Single Answer"),
                  value: "Single Answer",
                  groupValue: mcqType,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() {
                      mcqType = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text("Multiple Answers"),
                  value: "Multiple",
                  groupValue: mcqType,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (value) {
                    setState(() {
                      mcqType = value;
                    });
                  },
                ),
              ),
            ],
          ),
          _buildQuestionType(
              "MCQs", isMCQSelected, mcqQuestionsController, mcqMarksController,
              (value) {
            setState(() {
              isMCQSelected = value ?? false;
            });
          }, errorState: mcqQuestionsError || mcqMarksError),
        ]),
    ]);
  }

  Widget _buildQuestionType(
      String title,
      bool? isSelected,
      TextEditingController controller,
      TextEditingController marksController,
      ValueChanged<bool?> onChanged,
      {bool errorState = false}) {
    return Column(
      children: [
        if (title != "MCQs")
          CheckboxListTile(
            title: Text(title),
            value: isSelected,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: onChanged,
          ),
        if (isSelected == true)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: errorState ? Colors.red : Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                      labelText: "Number of Questions",
                      errorText: errorState ? "Field cannot be empty" : null),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: marksController,
                  decoration: InputDecoration(
                      labelText: "$title Total Marks",
                      errorText: errorState ? "Field cannot be empty" : null),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
