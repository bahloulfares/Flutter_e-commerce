import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:atelier7/utils/face_id_service.dart';

enum FaceCaptureMode { enroll, verify }

/// Écran de capture du visage via caméra frontale
class FaceCaptureScreen extends StatefulWidget {
  final FaceCaptureMode mode;

  const FaceCaptureScreen({super.key, required this.mode});

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = '';
  String _instruction = '';

  @override
  void initState() {
    super.initState();
    _instruction = widget.mode == FaceCaptureMode.enroll
        ? 'Placez votre visage dans le cadre et appuyez sur le bouton'
        : 'Regardez la caméra pour vous connecter';
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      // Chercher la caméra frontale
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Erreur caméra: $e');
      }
    }
  }

  Future<void> _capture() async {
    if (_cameraController == null || !_isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyse du visage...';
    });

    try {
      final xFile = await _cameraController!.takePicture();
      final imageFile = File(xFile.path);

      final service = FaceIdService();
      FaceIdResult result;

      if (widget.mode == FaceCaptureMode.enroll) {
        result = await service.enrollFace(imageFile);
      } else {
        result = await service.verifyFace(imageFile);
      }

      service.dispose();

      if (!mounted) return;

      switch (result) {
        case FaceIdResult.success:
          setState(() => _statusMessage = widget.mode == FaceCaptureMode.enroll
              ? '✅ Visage enregistré avec succès !'
              : '✅ Visage reconnu !');
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) Navigator.of(context).pop(true);
          break;

        case FaceIdResult.noFaceDetected:
          setState(() {
            _statusMessage = '❌ Aucun visage détecté. Rapprochez-vous.';
            _isProcessing = false;
          });
          break;

        case FaceIdResult.multipleFaces:
          setState(() {
            _statusMessage = '❌ Plusieurs visages détectés. Restez seul.';
            _isProcessing = false;
          });
          break;

        case FaceIdResult.notMatching:
          setState(() {
            _statusMessage = '❌ Visage non reconnu. Réessayez.';
            _isProcessing = false;
          });
          break;

        case FaceIdResult.notEnrolled:
          setState(() {
            _statusMessage = '❌ Aucun visage enregistré.';
            _isProcessing = false;
          });
          break;

        default:
          setState(() {
            _statusMessage = '❌ Erreur. Réessayez.';
            _isProcessing = false;
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Erreur: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEnroll = widget.mode == FaceCaptureMode.enroll;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isEnroll ? 'Enregistrer Face ID' : 'Connexion Face ID'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Column(
        children: [
          // Prévisualisation caméra
          Expanded(
            child: _isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      // Caméra
                      SizedBox.expand(
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: _cameraController!.value.previewSize!.height,
                            height: _cameraController!.value.previewSize!.width,
                            child: CameraPreview(_cameraController!),
                          ),
                        ),
                      ),
                      // Cadre ovale pour le visage
                      CustomPaint(
                        size: const Size(double.infinity, double.infinity),
                        painter: _FaceOvalPainter(
                          color: _statusMessage.startsWith('✅')
                              ? Colors.green
                              : _statusMessage.startsWith('❌')
                                  ? Colors.red
                                  : Colors.white,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: _statusMessage.isNotEmpty
                        ? Text(_statusMessage,
                            style: const TextStyle(color: Colors.white))
                        : const CircularProgressIndicator(color: Colors.white),
                  ),
          ),

          // Zone de contrôle
          Container(
            color: Colors.black,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Instruction
                Text(
                  _statusMessage.isNotEmpty ? _statusMessage : _instruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _statusMessage.startsWith('✅')
                        ? Colors.green
                        : _statusMessage.startsWith('❌')
                            ? Colors.red
                            : Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Bouton capture
                GestureDetector(
                  onTap: _isProcessing ? null : _capture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      color: _isProcessing ? Colors.grey : cs.primary,
                    ),
                    child: _isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.face, color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isProcessing ? 'Analyse...' : 'Appuyez pour capturer',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dessine un cadre ovale pour guider le positionnement du visage
class _FaceOvalPainter extends CustomPainter {
  final Color color;
  _FaceOvalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.65,
      height: size.height * 0.55,
    );

    canvas.drawOval(ovalRect, paint);

    // Coins guides
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLen = 20.0;
    final l = ovalRect.left;
    final r = ovalRect.right;
    final t = ovalRect.top;
    final b = ovalRect.bottom;
    final cx = ovalRect.center.dx;
    final cy = ovalRect.center.dy;

    // Coins haut-gauche
    canvas.drawLine(Offset(l, cy - cornerLen), Offset(l, cy), cornerPaint);
    canvas.drawLine(Offset(cx - cornerLen, t), Offset(cx, t), cornerPaint);
    // Coins haut-droit
    canvas.drawLine(Offset(r, cy - cornerLen), Offset(r, cy), cornerPaint);
    canvas.drawLine(Offset(cx, t), Offset(cx + cornerLen, t), cornerPaint);
    // Coins bas-gauche
    canvas.drawLine(Offset(l, cy), Offset(l, cy + cornerLen), cornerPaint);
    canvas.drawLine(Offset(cx - cornerLen, b), Offset(cx, b), cornerPaint);
    // Coins bas-droit
    canvas.drawLine(Offset(r, cy), Offset(r, cy + cornerLen), cornerPaint);
    canvas.drawLine(Offset(cx, b), Offset(cx + cornerLen, b), cornerPaint);
  }

  @override
  bool shouldRepaint(_FaceOvalPainter old) => old.color != color;
}
