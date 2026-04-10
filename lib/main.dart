import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'disease_data.dart';


void main() {
  runApp(const CropDiseaseApp());
}

class CropDiseaseApp extends StatelessWidget {
  const CropDiseaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Crop Disease Detector",
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String diseaseName = "";
  String description = "";
  String treatment = "";
  double confidence = 0;

  File? image;
  final ImagePicker picker = ImagePicker();

  late Interpreter interpreter;

  List<String> labels = [];

  String result = "";

  @override
  void initState() {
    super.initState();
    loadModel();
    loadLabels();
  }

  // Load model
  void loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/model.tflite');
    print("Model loaded");
  }

  // Load labels
  Future loadLabels() async {
    final data = await DefaultAssetBundle.of(context)
        .loadString('assets/labels.txt');

    labels = data.split('\n').map((e) => e.trim()).toList();
  }

  // Convert image to tensor
  List processImage(File imageFile) {

    img.Image image = img.decodeImage(imageFile.readAsBytesSync())!;
    img.Image resized = img.copyResize(image, width: 200, height: 200);

    var input = List.generate(
        1,
            (_) => List.generate(
            200,
                (_) => List.generate(
                200,
                    (_) => List.filled(3, 0.0))));

    for (int y = 0; y < 200; y++) {
      for (int x = 0; x < 200; x++) {

        var pixel = resized.getPixel(x, y);

        input[0][y][x][1] = pixel.g / 255.0;
        input[0][y][x][2] = pixel.b / 255.0;
        input[0][y][x][0] = pixel.r / 255.0;

      }
    }

    return input;
  }

  // Run prediction
  void runModel(File imageFile) {

    print("running model");

    var input = processImage(imageFile);

    var output = List.generate(1, (_) => List.filled(39, 0.0));

    interpreter.run(input, output);

    int maxIndex = 0;
    double maxValue = output[0][0];

    for (int i = 0; i < output[0].length; i++) {
      if (output[0][i] > maxValue) {
        maxValue = output[0][i];
        maxIndex = i;
      }
    }

    setState(() {

      diseaseName = labels[maxIndex].trim();

      confidence = maxValue * 100;

      if (diseaseInfo.containsKey(diseaseName)) {
        description = diseaseInfo[diseaseName]!["description"]!;
        treatment = diseaseInfo[diseaseName]!["treatment"]!;
      } else {
        description = "Information not available.";
        treatment = "No treatment recommendation.";
      }

});

  }

  // Camera
  Future pickCamera() async {

    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {

      File imgFile = File(picked.path);

      setState(() {
        image = imgFile;
      });

      runModel(imgFile);
    }
  }

  // Gallery
  Future pickGallery() async {

    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {

      File imgFile = File(picked.path);

      setState(() {
        image = imgFile;
      });

      runModel(imgFile);
    }
  }


  @override
Widget build(BuildContext context) {

  return Scaffold(
    appBar: AppBar(
  title: const Text("Crop Disease Identifier"),
  centerTitle: true,
  elevation: 0,
  flexibleSpace: Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Color(0xff0D47A1),
          Color(0xff1976D2),
          Color(0xff64B5F6),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ),
),

    body: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xff0D47A1),
        Color(0xff1976D2),
        Color(0xff64B5F6),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  ),
  child: diseaseName.isEmpty && image == null
      ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Icon(
                Icons.eco,
                size: 100,
                color: Colors.white,
              ),

              const SizedBox(height: 20),

              const Text(
                "Crop Disease Detector",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Upload or capture a leaf image",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Take Photo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: pickCamera,
              ),

              const SizedBox(height: 15),

              ElevatedButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text("Upload from Gallery"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: pickGallery,
              ),

            ],
          ),
        )
      : SingleChildScrollView(
          child: Column(
            children: [

              const SizedBox(height: 20),

              if (image != null)
                Card(
                  elevation: 10,
                  margin: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(image!, height: 250),
                  ),
                ),

              if (diseaseName.isNotEmpty)
                Card(
                  elevation: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        const Row(
                          children: [
                            Icon(Icons.eco, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              "Detected Disease",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        Text(
                          diseaseName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "Confidence: ${confidence.toStringAsFixed(2)}%",
                          style: const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(height: 10),

                        LinearProgressIndicator(
                          value: confidence / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          color: Colors.green,
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(description),

                        const SizedBox(height: 15),

                        const Text(
                          "Recommended Treatment",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(treatment),

                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 30),

              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text("Take Another Photo"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15),
                ),
                onPressed: pickCamera,
              ),

              const SizedBox(height: 15),

              ElevatedButton.icon(
                icon: const Icon(Icons.photo),
                label: const Text("Upload Another Image"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15),
                ),
                onPressed: pickGallery,
              ),

              const SizedBox(height: 40),

            ],
          ),
        ),
),
  );
}
}