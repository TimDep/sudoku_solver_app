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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  XFile? _pickedFile;
  CroppedFile? _croppedFile;
  File? _processedFile;

  @override
  void initState() {
    initCamera();
    super.initState();
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
      } else if (_processedFile != null) {
        return _buildProcessedImage();
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
        // Center the Column widget horizontally and vertically
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          // Center the content vertically
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
            const SizedBox(height: 60), // Spacing between buttons
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
                fit: BoxFit.contain, // Ensure image fits within container
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
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    recognizer: TapGestureRecognizer(),
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
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    recognizer: TapGestureRecognizer(),
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
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      recognizer: TapGestureRecognizer()),
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
                    text: TextSpan(
                        text: 'Snij Foto bij',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                        recognizer: TapGestureRecognizer()),
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
                            const TextStyle(color: Colors.white, fontSize: 15),
                        recognizer: TapGestureRecognizer()),
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
                text: TextSpan(
                    text: 'Cancel',
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    recognizer: TapGestureRecognizer()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    //TODO Python API call
    final uri = Uri.parse('http://10.0.2.2:5000/upload-image');

    // Create a multipart request
    var request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        _croppedFile?.path ?? _pickedFile!.path,
        filename: basename(_croppedFile?.path ?? _pickedFile!.path),
        contentType: MediaType('image', 'png'),
      ));

    try {
      // Send the request
      var response = await request.send();

      if (response.statusCode == 200) {
        // Process the response
        var responseData = await http.Response.fromStream(response);

        // Save the received image to a file
        final processedImageBytes = responseData.bodyBytes;
        final processedImageFile = File('${_croppedFile?.path ?? _pickedFile!.path}_processed.png');
        await processedImageFile.writeAsBytes(processedImageBytes);

        setState(() {
          _processedFile = processedImageFile;
        });
      } else {
        print('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  Widget _buildProcessedImage() {
    if (_processedFile != null) {
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
                  _processedFile!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // You can include additional UI controls here as needed
          ],
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
    });
  }
}
