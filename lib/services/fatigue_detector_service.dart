import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class DetectionResult {
  final bool faceFound;
  final double leftEyeOpenProb;
  final double rightEyeOpenProb;
  final bool yawning;

  DetectionResult({
    required this.faceFound,
    this.leftEyeOpenProb = 1.0,
    this.rightEyeOpenProb = 1.0,
    this.yawning = false,
  });
}

class FatigueDetectorService {
  final FaceDetector _faceDetector;

  FatigueDetectorService()
    : _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableContours: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

  Future<DetectionResult> detectFromCameraImage(CameraImage image) async {
    try {
      final bytes = Uint8List.fromList(
        image.planes.expand((plane) => plane.bytes).toList(),
      );

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation270deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) return DetectionResult(faceFound: false);

      final face = faces.first;

      final left = face.leftEyeOpenProbability ?? 1.0;
      final right = face.rightEyeOpenProbability ?? 1.0;
      final yawning = _isYawning(face);

      return DetectionResult(
        faceFound: true,
        leftEyeOpenProb: left,
        rightEyeOpenProb: right,
        yawning: yawning,
      );
    } catch (e) {
      debugPrint('Detector error: $e');
      return DetectionResult(faceFound: false);
    }
  }

  bool _isYawning(Face face) {
    final upperLip = face.contours[FaceContourType.upperLipBottom]?.points;
    final lowerLip = face.contours[FaceContourType.lowerLipTop]?.points;

    if (upperLip == null ||
        upperLip.isEmpty ||
        lowerLip == null ||
        lowerLip.isEmpty) {
      return false;
    }

    final double upperMeanY =
        upperLip.map((p) => p.y.toDouble()).reduce((a, b) => a + b) /
        upperLip.length;
    final double lowerMeanY =
        lowerLip.map((p) => p.y.toDouble()).reduce((a, b) => a + b) /
        lowerLip.length;
    final double mouthGap = (lowerMeanY - upperMeanY).abs();

    final leftMouth = face.landmarks[FaceLandmarkType.leftMouth]?.position;
    final rightMouth = face.landmarks[FaceLandmarkType.rightMouth]?.position;

    if (leftMouth == null || rightMouth == null) {
      return mouthGap > face.boundingBox.height * 0.09;
    }

    final double mouthWidth = (rightMouth.x - leftMouth.x)
        .abs()
        .toDouble()
        .clamp(1.0, double.infinity);
    final double mouthAspectRatio = mouthGap / mouthWidth;

    return mouthAspectRatio > 0.22;
  }

  void dispose() {
    _faceDetector.close();
  }
}
