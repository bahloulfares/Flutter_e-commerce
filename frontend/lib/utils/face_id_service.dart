import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:ui';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Résultat de l'opération Face ID
enum FaceIdResult {
  success, // Visage reconnu
  noFaceDetected, // Aucun visage dans l'image
  multipleFaces, // Plusieurs visages détectés
  notEnrolled, // Aucun visage enregistré
  notMatching, // Visage ne correspond pas
  failure, // Erreur technique
}

/// Service Face ID basé sur ML Kit Face Detection
/// ⚠️ Avertissement sécurité : peut être trompé par une photo
class FaceIdService {
  static const _storageKey = 'face_id_landmarks';
  static const double _similarityThreshold = 0.82; // seuil de similarité

  final FlutterSecureStorage _storage;
  late final FaceDetector _detector;

  FaceIdService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ) {
    _detector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: true,
        enableClassification: true,
        enableContours: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
  }

  /// Enregistre le visage depuis une image
  Future<FaceIdResult> enrollFace(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _detector.processImage(inputImage);

      if (faces.isEmpty) {
        developer.log('❌ FaceID: aucun visage détecté', name: 'FaceIdService');
        return FaceIdResult.noFaceDetected;
      }
      if (faces.length > 1) {
        developer.log('❌ FaceID: plusieurs visages', name: 'FaceIdService');
        return FaceIdResult.multipleFaces;
      }

      final face = faces.first;
      final vector = _extractFaceVector(face);

      if (vector == null) {
        developer.log('❌ FaceID: landmarks insuffisants',
            name: 'FaceIdService');
        return FaceIdResult.failure;
      }

      // Stocker le vecteur chiffré
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(vector),
      );

      developer.log('✅ FaceID: visage enregistré (${vector.length} points)',
          name: 'FaceIdService');
      return FaceIdResult.success;
    } catch (e) {
      developer.log('❌ FaceID enrollFace error: $e', name: 'FaceIdService');
      return FaceIdResult.failure;
    }
  }

  /// Vérifie le visage contre le vecteur enregistré
  Future<FaceIdResult> verifyFace(File imageFile) async {
    try {
      // Vérifier qu'un visage est enregistré
      final storedJson = await _storage.read(key: _storageKey);
      if (storedJson == null) {
        return FaceIdResult.notEnrolled;
      }

      final storedVector = List<double>.from(jsonDecode(storedJson));

      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _detector.processImage(inputImage);

      if (faces.isEmpty) return FaceIdResult.noFaceDetected;
      if (faces.length > 1) return FaceIdResult.multipleFaces;

      final face = faces.first;
      final currentVector = _extractFaceVector(face);

      if (currentVector == null) return FaceIdResult.failure;

      final similarity = _cosineSimilarity(storedVector, currentVector);
      developer.log('🔍 FaceID similarity: ${similarity.toStringAsFixed(3)}',
          name: 'FaceIdService');

      if (similarity >= _similarityThreshold) {
        developer.log(
            '✅ FaceID: visage reconnu (${(similarity * 100).toStringAsFixed(1)}%)',
            name: 'FaceIdService');
        return FaceIdResult.success;
      } else {
        developer.log(
            '❌ FaceID: visage non reconnu (${(similarity * 100).toStringAsFixed(1)}%)',
            name: 'FaceIdService');
        return FaceIdResult.notMatching;
      }
    } catch (e) {
      developer.log('❌ FaceID verifyFace error: $e', name: 'FaceIdService');
      return FaceIdResult.failure;
    }
  }

  /// Vérifie si un visage est enregistré
  Future<bool> isEnrolled() async {
    final stored = await _storage.read(key: _storageKey);
    return stored != null;
  }

  /// Supprime le visage enregistré
  Future<void> deleteFace() async {
    await _storage.delete(key: _storageKey);
    developer.log('🗑️ FaceID: visage supprimé', name: 'FaceIdService');
  }

  /// Extrait un vecteur de caractéristiques depuis les landmarks ML Kit
  List<double>? _extractFaceVector(Face face) {
    final List<double> vector = [];

    // Landmarks principaux
    final landmarks = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
    ];

    // Collecter les positions des landmarks
    final points = <Offset>[];
    for (final type in landmarks) {
      final landmark = face.landmarks[type];
      if (landmark != null) {
        points.add(Offset(
            landmark.position.x.toDouble(), landmark.position.y.toDouble()));
      }
    }

    if (points.length < 5) return null; // Pas assez de landmarks

    // Normaliser par rapport au centre du visage
    final centerX =
        points.map((p) => p.dx).reduce((a, b) => a + b) / points.length;
    final centerY =
        points.map((p) => p.dy).reduce((a, b) => a + b) / points.length;
    final scale = face.boundingBox.width.toDouble();

    for (final point in points) {
      vector.add((point.dx - centerX) / scale);
      vector.add((point.dy - centerY) / scale);
    }

    // Ajouter les angles du visage (rotation)
    if (face.headEulerAngleY != null) vector.add(face.headEulerAngleY! / 90.0);
    if (face.headEulerAngleZ != null) vector.add(face.headEulerAngleZ! / 90.0);

    // Ajouter les scores de classification
    if (face.leftEyeOpenProbability != null) {
      vector.add(face.leftEyeOpenProbability!);
    }
    if (face.rightEyeOpenProbability != null) {
      vector.add(face.rightEyeOpenProbability!);
    }

    return vector;
  }

  /// Calcule la similarité cosinus entre deux vecteurs
  double _cosineSimilarity(List<double> a, List<double> b) {
    final minLen = min(a.length, b.length);
    if (minLen == 0) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < minLen; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  void dispose() {
    _detector.close();
  }
}
