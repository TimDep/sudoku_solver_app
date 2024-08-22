import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/painting.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

import '../widgets/grid_tile.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  XFile? _pickedFile;
  CroppedFile? _croppedFile;

  List<List<String>>? sudokuGrid;
  late List<List<TextEditingController>> controllers;
  int selectedX = 0;
  int selectedY = 0;

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  void initCamera() async {
    WidgetsFlutterBinding.ensureInitialized();
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
        title: const Text('Scan Sudoku', style: TextStyle(color: Colors.white)),
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
                  text: TextSpan(
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
                        style:
                        TextStyle(color: Colors.white, fontSize: 15)),
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
                    text: TextSpan(
                        text: 'Submit',
                        style:
                        TextStyle(color: Colors.white, fontSize: 15)),
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
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(3.5),
          height: 296,
          width: 296,
          color: const Color(0xff575D62),
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
                  setState(() {
                    selectedX = i;
                    selectedY = j;
                  });
                },
                child: SudokuTile(
                  c: (i == selectedX && j == selectedY)
                      ? Colors.grey
                      : (((i + 1 <= 6 && i + 1 >= 4) &&
                      (j + 1 <= 3 || j + 1 >= 7)) ||
                      ((i + 1 <= 3 || i + 1 >= 7) &&
                          (j + 1 >= 4 && j + 1 <= 6))
                      ? const Color(0xff1B2023)
                      : const Color(0xff23292C)),
                  value: int.tryParse(sudokuGrid![j][i]) ?? 0,
                ),
              );
            },
          ),
        ),
      );
    } else {
      return const Text('No processed image available.');
    }
  }

  void _clear() {
    setState(() {
      _pickedFile = null;
      _croppedFile = null;
      sudokuGrid = null;
    });
  }
}

