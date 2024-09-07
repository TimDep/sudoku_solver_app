import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

import '../class/SudokuSolution.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  XFile? _pickedFile;
  CroppedFile? _croppedFile;

  List<List<String>>? sudokuGrid;
  List<List<TextEditingController>>? controllers;
  List<List<Color>>? cellColors;
  List<List<List<String>>> gridHistory = [];

  String currentStepDescription = '';

  int selectedX = 0;
  int selectedY = 0;

  int currentStepIndex = 0;
  SudokuSolution? currentSolution;

  bool isSolving = false;

  @override
  void initState() {
    _initializeControllers();
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    for (var row in controllers!) {
      for (var controller in row) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void initCamera() async {
    WidgetsFlutterBinding.ensureInitialized();
  }

  void _initializeControllers() {
    controllers = List.generate(
        9, (i) => List.generate(9, (j) => TextEditingController()));
    cellColors = List.generate(9, (i) => List.generate(9, (j) => Colors.black));
  }

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        _croppedFile = null;
        sudokuGrid = null; // Clear the Sudoku grid when a new image is picked
      });
    }
  }

  Future<void> _takePicture() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
        _croppedFile = null;
        sudokuGrid = null; // Clear the Sudoku grid when a new image is picked
      });
    }
  }

  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        aspectRatioPresets: [
          CropAspectRatioPreset.square,
          CropAspectRatioPreset.ratio3x2,
          CropAspectRatioPreset.original,
          CropAspectRatioPreset.ratio4x3,
          CropAspectRatioPreset.ratio16x9
        ],
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Snij foto bij',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            minimumAspectRatio: 1.0,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _croppedFile = croppedFile;
        });
      }
    }
  }

  Future<void> _submit() async {
    final uri = Uri.parse('http://10.0.2.2:5000/upload-image');

    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        _croppedFile?.path ?? _pickedFile!.path,
        filename: basename(_croppedFile?.path ?? _pickedFile!.path),
        contentType: MediaType('image', 'jpeg'),
      ));

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await http.Response.fromStream(response);

        Map<String, dynamic> parsedJson = json.decode(responseData.body);
        List<List<String>> grid = (json.decode(parsedJson['grid']) as List)
            .map((row) => (row as List).map((cell) => cell.toString()).toList())
            .toList();

        setState(() {
          sudokuGrid = grid;
          _updateSudokuGrid();
        });
      } else {
        print('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.blue,
        title: const Text('Sudoku Scanner', style: TextStyle(color: Colors.white)),
      ),
      body: Center(child: choosingWidget()),
    );
  }

  Widget choosingWidget() {
    if (_pickedFile != null) {
      if (_croppedFile != null) {
        return _buildCroppedImage();
      } else if (sudokuGrid != null) {
        return _buildSudokuGrid();
      } else {
        return _buildOriginalImage();
      }
    } else {
      return _startScreen();
    }
  }

  Widget _startScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: _getImage,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text('Choose from gallery',
                  style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 60),
            ElevatedButton(
              onPressed: _takePicture,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child:
                  const Text('Take a picture', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCroppedImage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: Card(
              elevation: 4.0,
              child: Image.file(
                File(_croppedFile!.path),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _cropImage,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: RichText(
                  text: const TextSpan(
                    text: 'Snij Foto bij',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: RichText(
                  text: TextSpan(
                    text: 'Submit',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
              const Padding(padding: EdgeInsets.all(10.0), child: Text(" ")),
              ElevatedButton(
                onPressed: _clear,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: RichText(
                  text: TextSpan(
                      text: 'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalImage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4.0,
        child: Column(
          children: [
            Image.file(File(_pickedFile!.path)),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _cropImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: RichText(
                    text: const TextSpan(
                        text: 'Snij Foto bij',
                        style: TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 16.0),
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: RichText(
                    text: const TextSpan(
                        text: 'Submit',
                        style: TextStyle(color: Colors.white, fontSize: 15)),
                  ),
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.all(10.0), child: Text(" ")),
            ElevatedButton(
              onPressed: _clear,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
              child: RichText(
                text: const TextSpan(
                    text: 'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSudokuGrid() {
    if (sudokuGrid != null) {
      _updateSudokuGrid(); // Update controllers with the current grid values

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Step ${(currentStepIndex / 2).ceil()}: $currentStepDescription',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(3.5),
                height: 296,
                width: 296,
                color: Colors.black,
                child: GridView.builder(
                  itemCount: 81,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 9,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    int i = (index % 9);
                    int j = (index ~/ 9);

                    return GestureDetector(
                      onTap: () {
                        if (!isSolving) {
                          setState(() {
                            selectedX = i;
                            selectedY = j;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: (i == selectedX && j == selectedY)
                              ? const Color(0xffD3D3D3)
                              : Colors.white,
                          border: Border.all(color: Colors.black),
                        ),
                        child: isSolving
                            ? Center(
                          child: Text(
                            controllers![j][i].text,
                            style: TextStyle(
                              color: (sudokuGrid![j][i] == '0' ||
                                  sudokuGrid![j][i].isEmpty)
                                  ? Colors.transparent
                                  : cellColors![j][i],
                            ),
                          ),
                        )
                            : TextField(
                          controller: controllers?[j][i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          decoration: const InputDecoration(
                            counterText: '', // Removes character counter
                            border: InputBorder.none,
                          ),
                          onChanged: (value) {
                            sudokuGrid![j][i] = value.isEmpty ? '0' : value;
                          },
                          style: TextStyle(
                            color: (sudokuGrid![j][i] == '0' ||
                                sudokuGrid![j][i].isEmpty)
                                ? Colors.transparent
                                : cellColors![j][i],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: (currentSolution != null && currentStepIndex > 1)
                      ? _previousStep
                      : null,
                ),
                if (!isSolving)
                  ElevatedButton(
                    onPressed: _solveSudoku,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Solve', style: TextStyle(fontSize: 18)),
                  ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: (currentSolution != null &&
                      currentStepIndex < currentSolution!.steps.length - 2)
                      ? _nextStep
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 80),
              ElevatedButton(
                onPressed: _clear, // Clears the current state to start new Sudoku
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text('New Sudoku', style: TextStyle(fontSize: 18)),
              ),
          ],
        ),
      );
    } else {
      return const Text('No processed image available.');
    }
  }



  void _nextStep() {
    if (currentSolution != null &&
        currentStepIndex < currentSolution!.steps.length - 2) {
      setState(() {
        currentStepIndex += 2;
        _applyStep(currentStepIndex, currentSolution!, true);
      });
    }
  }

  void _previousStep() {
    if (currentSolution != null && currentStepIndex > 1) {
      setState(() {
        currentStepIndex -= 2;
        _applyStep(currentStepIndex, currentSolution!, false);
      });
    }
  }

  void _updateSudokuGrid() {
    if (sudokuGrid != null) {
      for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
          controllers![i][j].text = sudokuGrid![i][j];
        }
      }
    }
  }

  void _solveSudoku() async {
    _fillEmptyCells();
    setState(() {
      isSolving = true; // Hide the "Solve" button after it's pressed
    });
    final uri = Uri.parse('http://10.0.2.2:8080/sudoku/solve');
    try {
      var response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(sudokuGrid),
      );

      if (response.statusCode == 200) {
        // Parse the JSON response
        Map<String, dynamic> parsedJson = json.decode(response.body);
        currentSolution = SudokuSolution.fromJson(parsedJson);

        setState(() {
          _applyStep(
              1, currentSolution!, true); // Apply the first step initially
        });
      } else {
        print('Failed to solve Sudoku: ${response.statusCode}');
        setState(() {
          isSolving = false; // Show the "Solve" button again if the solve fails
        });
      }
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        isSolving = false; // Show the "Solve" button again if an error occurs
      });
    }
  }

  void _fillEmptyCells() {
    if (sudokuGrid != null) {
      for (int i = 0; i < sudokuGrid!.length; i++) {
        for (int j = 0; j < sudokuGrid![i].length; j++) {
          if (sudokuGrid![i][j].isEmpty) {
            sudokuGrid![i][j] = '0';
          }
        }
      }
    }
  }

  void _applyStep(int stepIndex, SudokuSolution sudokuSolution, bool forward) {
    if (stepIndex < sudokuSolution.steps.length) {
      // Get the grid from the step that contains the numbers
      String gridStep = sudokuSolution.steps[stepIndex];

      List<List<String>> grid = [];
      for (int i = 0; i < 9; i++) {
        List<String> row = gridStep.substring(i * 9, (i + 1) * 9).split('');
        grid.add(row);
      }

      setState(() {
        if (forward) {
          gridHistory.add(List.generate(9, (i) => List.from(sudokuGrid![i])));
          for (int i = 0; i < 9; i++) {
            for (int j = 0; j < 9; j++) {
              if (sudokuGrid![i][j] != grid[i][j]) {
                cellColors![i][j] = Colors.red;
              } else {
                cellColors![i][j] = Colors.black;
              }
              sudokuGrid![i][j] = grid[i][j];
            }
          }
        } else {
          if (gridHistory.length > 2) {
            for (int i = 0; i < 9; i++) {
              for (int j = 0; j < 9; j++) {
                if (gridHistory.elementAt(gridHistory.length - 2)[i][j] !=
                    gridHistory.elementAt(gridHistory.length - 1)[i][j]) {
                  cellColors![i][j] = Colors.red;
                } else {
                  cellColors![i][j] = Colors.black;
                }
                sudokuGrid![i][j] =
                    gridHistory.elementAt(gridHistory.length - 1)[i][j];
              }
            }
            gridHistory.removeAt(gridHistory.length - 1);
          } else {
            for (int i = 0; i < 9; i++) {
              for (int j = 0; j < 9; j++) {
                cellColors![i][j] = Colors.black;
                sudokuGrid![i][j] = grid[i][j];
              }
            }
          }
        }

        currentStepIndex = stepIndex;
        currentStepDescription = sudokuSolution.steps[stepIndex-1];
        _updateSudokuGrid();
      });
    } else {
      List<List<String>> solvedGrid = (json.decode(sudokuSolution.solution)
              as List)
          .map((row) => (row as List).map((cell) => cell.toString()).toList())
          .toList();

      setState(() {
        sudokuGrid = solvedGrid;
        _updateSudokuGrid();
      });
    }
  }

  void _clear() {
    setState(() {
      _pickedFile = null;
      _croppedFile = null;
      sudokuGrid = null;
      isSolving = false; // Reset solve button visibility
    });
  }
}
