import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../../../core/theme/app_theme.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primary
      ..strokeWidth = 3;

    final bonePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppTheme.primary.withOpacity(0.8)
      ..strokeWidth = 3;

    final errorPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppTheme.error.withOpacity(0.8)
      ..strokeWidth = 3;

    for (final pose in poses) {
      // Draw bones (connections)
      _drawBones(canvas, pose, size, bonePaint, errorPaint);

      // Draw joints (landmarks)
      pose.landmarks.forEach((_, landmark) {
        if (landmark.likelihood >= 0.5) {
          final offset = _translateOffset(
            Offset(landmark.x, landmark.y),
            size,
          );
          canvas.drawCircle(offset, 6, jointPaint);
          // Inner dot
          canvas.drawCircle(
            offset,
            3,
            Paint()..color = Colors.white,
          );
        }
      });
    }
  }

  void _drawBones(
      Canvas canvas,
      Pose pose,
      Size size,
      Paint bonePaint,
      Paint errorPaint,
      ) {
    // Define skeleton connections
    final connections = [
      // Torso
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      // Left arm
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      // Right arm
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      // Left leg
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      // Right leg
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
      // Face
      [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
      [PoseLandmarkType.rightEar, PoseLandmarkType.rightEye],
      [PoseLandmarkType.leftEye, PoseLandmarkType.nose],
      [PoseLandmarkType.rightEye, PoseLandmarkType.nose],
    ];

    for (final connection in connections) {
      final start = pose.landmarks[connection[0]];
      final end = pose.landmarks[connection[1]];

      if (start != null &&
          end != null &&
          start.likelihood >= 0.5 &&
          end.likelihood >= 0.5) {
        final startOffset = _translateOffset(Offset(start.x, start.y), size);
        final endOffset = _translateOffset(Offset(end.x, end.y), size);
        canvas.drawLine(startOffset, endOffset, bonePaint);
      }
    }
  }

  Offset _translateOffset(Offset point, Size size) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    double x = point.dx * scaleX;
    double y = point.dy * scaleY;

    // Mirror for back camera
    if (cameraLensDirection == CameraLensDirection.back) {
      x = size.width - x;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) {
    return oldDelegate.poses != poses;
  }
}