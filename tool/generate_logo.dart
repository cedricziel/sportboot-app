import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// Simple logo generator for the app
// Creates a logo.png file in assets/images/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create logo at different sizes
  await generateLogo(512, 'assets/images/logo.png');
  await generateLogo(1024, 'assets/images/logo@2x.png');
  
  // Logo files generated successfully
  exit(0);
}

Future<void> generateLogo(int size, String outputPath) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));
  final paint = Paint();
  
  // Background gradient
  paint.shader = ui.Gradient.linear(
    const Offset(0, 0),
    Offset(size.toDouble(), size.toDouble()),
    [
      const Color(0xFF1976D2), // Material Blue 700
      const Color(0xFF1565C0), // Material Blue 800
    ],
  );
  
  // Draw rounded rectangle background
  final rrect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    Radius.circular(size * 0.2),
  );
  canvas.drawRRect(rrect, paint);
  
  // Draw boat waves (simple curved lines)
  final wavePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.3)
    ..style = PaintingStyle.stroke
    ..strokeWidth = size * 0.02;
  
  final wavePath = Path();
  wavePath.moveTo(size * 0.2, size * 0.7);
  wavePath.quadraticBezierTo(
    size * 0.35, size * 0.65,
    size * 0.5, size * 0.7,
  );
  wavePath.quadraticBezierTo(
    size * 0.65, size * 0.75,
    size * 0.8, size * 0.7,
  );
  canvas.drawPath(wavePath, wavePaint);
  
  // Draw boat triangle (simplified sailboat)
  final boatPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.9)
    ..style = PaintingStyle.fill;
  
  final boatPath = Path();
  // Sail
  boatPath.moveTo(size * 0.5, size * 0.25);
  boatPath.lineTo(size * 0.35, size * 0.6);
  boatPath.lineTo(size * 0.5, size * 0.6);
  boatPath.close();
  
  // Second sail
  final sail2Path = Path();
  sail2Path.moveTo(size * 0.5, size * 0.3);
  sail2Path.lineTo(size * 0.65, size * 0.6);
  sail2Path.lineTo(size * 0.5, size * 0.6);
  sail2Path.close();
  
  canvas.drawPath(boatPath, boatPaint);
  canvas.drawPath(sail2Path, boatPaint..color = Colors.white.withValues(alpha: 0.7));
  
  // Draw "SBF" text
  final textPainter = TextPainter(
    text: TextSpan(
      text: 'SBF',
      style: TextStyle(
        fontSize: size * 0.2,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: size * 0.02,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset(
      (size - textPainter.width) / 2,
      size * 0.75,
    ),
  );
  
  final picture = recorder.endRecording();
  final img = await picture.toImage(size, size);
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();
  
  final file = File(outputPath);
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
}