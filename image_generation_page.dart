import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ImageGenerationPage extends StatefulWidget {
  const ImageGenerationPage({super.key});

  @override
  State<ImageGenerationPage> createState() => _ImageGenerationPageState();
}

class _ImageGenerationPageState extends State<ImageGenerationPage> {
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  Uint8List? _generatedImage;
  String? _errorMessage;

  final String _hfToken = 'YOUR_HF_TOKEN';

  Future<void> _generateImage() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _generatedImage = null;
    });

    try {
      final url = Uri.parse(
        'https://router.huggingface.co/black-forest-labs/FLUX.1-dev',
      );
      final headers = {
        'Authorization': 'Bearer $_hfToken',
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({'inputs': prompt});

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        setState(() {
          _generatedImage = response.bodyBytes;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to generate image: ${response.statusCode} ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Image Generation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Enter prompt for image generation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateImage,
              child: const Text('Generate Image'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const SpinKitThreeBounce(color: Colors.blue, size: 50.0),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            if (_generatedImage != null)
              Expanded(child: Image.memory(_generatedImage!)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}
