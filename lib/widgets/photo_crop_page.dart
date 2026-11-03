import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import '../other/wp_text.dart';
import 'wp_button.dart';

class PhotoCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const PhotoCropPage({super.key, required this.imageBytes});

  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> {
  final _controller = CropController();
  bool _isCropping = false;
  bool _isReady = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  Text(
                    wpLowercase('crop photo'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            if (_isCropping)
              const LinearProgressIndicator(
                color: Colors.white,
                backgroundColor: Colors.white24,
              ),

            Expanded(
              child: Container(
                color: Colors.black,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _controller,
                  aspectRatio: 1.0,
                  interactive: true,
                  baseColor: Colors.black,               // The background behind the image
                  maskColor: Colors.black.withOpacity(0.8), // The dimming overlay outside the crop box
                  onStatusChanged: (status) {
                    if (status == CropStatus.ready && !_isReady) {
                      setState(() => _isReady = true);
                    }
                  },
                  onCropped: (result) {
                    if (!mounted) return;
                    if (result is CropSuccess) {
                      Navigator.pop(context, result.croppedImage);
                    } else if (result is CropFailure) {
                      setState(() => _isCropping = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to crop: ${result.cause}')),
                      );
                    }
                  },
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: WpButton(
                        label: 'cancel',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: WpButton(
                        label: 'done',
                        onPressed: (_isCropping || !_isReady)
                            ? null
                            : () {
                          setState(() => _isCropping = true);
                          _controller.crop();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}