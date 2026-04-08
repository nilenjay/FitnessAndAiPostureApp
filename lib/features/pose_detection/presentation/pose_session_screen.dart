import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../bloc/pose_bloc.dart';
import '../../../core/theme/app_theme.dart';
import 'pose_painter.dart';

class PoseSessionScreen extends StatefulWidget {
  final String exercise;
  const PoseSessionScreen({super.key, required this.exercise});

  @override
  State<PoseSessionScreen> createState() => _PoseSessionScreenState();
}

class _PoseSessionScreenState extends State<PoseSessionScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;

  CameraLensDirection _lensDirection = CameraLensDirection.back;
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
    context.read<PoseBloc>().add(PoseCameraStarted(widget.exercise));
  }

  Future<void> _initCamera({CameraLensDirection? direction}) async {
    final targetDirection = direction ?? _lensDirection;

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      CameraDescription camera;
      final preferred = _cameras
          .where((c) => c.lensDirection == targetDirection)
          .toList();
      if (preferred.isNotEmpty) {
        camera = preferred.first;
      } else {
        camera = _cameras.first;
      }

      await _cameraController?.stopImageStream().catchError((_) {});
      await _cameraController?.dispose();
      _cameraController = null;

      if (!mounted) return;
      setState(() => _isCameraInitialized = false);

      final newController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await newController.initialize();
      _rotation = _getRotation(camera.sensorOrientation);
      _lensDirection = camera.lensDirection;

      if (!mounted) return;

      _cameraController = newController;
      setState(() {
        _isCameraInitialized = true;
        _isFlipping = false;
      });

      _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      if (mounted) setState(() => _isFlipping = false);
      debugPrint('❌ Camera init error: $e');
    }
  }

  Future<void> _flipCamera() async {
    if (_isFlipping) return;
    setState(() => _isFlipping = true);

    final newDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;

    await _initCamera(direction: newDirection);
  }

  void _processCameraImage(CameraImage image) {
    if (_isDetecting) return;
    _isDetecting = true;
    try {
      final inputImage = _convertToInputImage(image);
      if (inputImage != null) {
        context.read<PoseBloc>().add(PoseImageProcessed(inputImage));
      }
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertToInputImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation _getRotation(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  void _stopSession() {
    _cameraController?.stopImageStream();
    context.read<PoseBloc>().add(PoseSessionCompleted());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  bool get _hasFrontCamera =>
      _cameras.any((c) => c.lensDirection == CameraLensDirection.front);

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoseBloc, PoseState>(
      listener: (context, state) {
        if (state is PoseSessionDone) {
          context.go(
            '/workout/summary',
            extra: {
              'exercise': state.exercise,
              'reps': state.totalReps,
              'score': state.score,
              'feedback': state.feedbackList,
            },
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_isCameraInitialized && _cameraController != null)
              CameraPreview(_cameraController!)
            else
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primary),
              ),

            BlocBuilder<PoseBloc, PoseState>(
              builder: (context, state) {
                if (state is PoseDetecting &&
                    state.poses.isNotEmpty &&
                    _cameraController != null) {
                  return CustomPaint(
                    painter: PosePainter(
                      poses: state.poses,
                      imageSize: Size(
                        _cameraController!.value.previewSize!.height,
                        _cameraController!.value.previewSize!.width,
                      ),
                      rotation: _rotation,
                      cameraLensDirection: _lensDirection,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopBar(
                exercise: widget.exercise,
                onFlipCamera: _hasFrontCamera ? _flipCamera : null,
                isFlipping: _isFlipping,
                lensDirection: _lensDirection,
              ),
            ),

            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomOverlay(onStop: _stopSession),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String exercise;
  final VoidCallback? onFlipCamera;
  final bool isFlipping;
  final CameraLensDirection lensDirection;

  const _TopBar({
    required this.exercise,
    this.onFlipCamera,
    this.isFlipping = false,
    required this.lensDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/workout/select'),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),

          Text(
            exercise.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),

          if (onFlipCamera != null)
            GestureDetector(
              onTap: isFlipping ? null : onFlipCamera,
              child: AnimatedOpacity(
                opacity: isFlipping ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isFlipping
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.flip_camera_ios_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomOverlay extends StatelessWidget {
  final VoidCallback onStop;
  const _BottomOverlay({required this.onStop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
        ),
      ),
      child: BlocBuilder<PoseBloc, PoseState>(
        builder: (context, state) {
          int repCount = 0;
          String feedback = 'Get into position...';
          double angle = 0;
          RepPhase phase = RepPhase.up;

          if (state is PoseDetecting) {
            repCount = state.repCount;
            feedback = state.feedback;
            angle = state.angle;
            phase = state.repPhase;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _getFeedbackColor(feedback).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getFeedbackColor(feedback).withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFeedbackIcon(feedback),
                      color: _getFeedbackColor(feedback),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        feedback,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(
                    label: 'REPS',
                    value: '$repCount',
                    color: AppTheme.primary,
                  ),
                  _StatChip(
                    label: 'ANGLE',
                    value: '${angle.toStringAsFixed(0)}°',
                    color: AppTheme.secondary,
                  ),
                  _StatChip(
                    label: 'PHASE',
                    value: phase == RepPhase.down ? '▼ DOWN' : '▲ UP',
                    color: phase == RepPhase.down
                        ? AppTheme.error
                        : AppTheme.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              GestureDetector(
                onTap: onStop,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.error,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.stop, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to finish',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getFeedbackColor(String feedback) {
    final lower = feedback.toLowerCase();
    if (lower.contains('good') ||
        lower.contains('great') ||
        lower.contains('perfect'))
      return AppTheme.secondary;
    if (lower.contains('straight') ||
        lower.contains('sagging') ||
        lower.contains('hips'))
      return AppTheme.error;
    return AppTheme.primary;
  }

  IconData _getFeedbackIcon(String feedback) {
    final lower = feedback.toLowerCase();
    if (lower.contains('good') ||
        lower.contains('great') ||
        lower.contains('perfect'))
      return Icons.check_circle_outline;
    if (lower.contains('straight') ||
        lower.contains('keep') ||
        lower.contains('hips'))
      return Icons.warning_amber_outlined;
    return Icons.info_outline;
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
