import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const AntiStressApp());
}

class AntiStressApp extends StatelessWidget {
  const AntiStressApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DrawingScreen(),
    );
  }
}

class DrawingScreen extends StatefulWidget {
  const DrawingScreen({super.key});

  @override
  State<DrawingScreen> createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> with TickerProviderStateMixin {
  List<DrawPoint> points = [];
  List<Star> stars = [];
  Timer? _timer;
  bool showElea = false;
  late AnimationController _eleaController;
  late Animation<double> _eleaScale;
  late Animation<double> _eleaOpacity;

  @override
  void initState() {
    super.initState();
    // Boucle de rafraîchissement pour l'effet de fondu
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updatePointsAndStars();
    });

    // Apparition d'Eléa toutes les 15 secondes
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _triggerEleaFireworks();
    });

    _eleaController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _eleaScale = Tween<double>(begin: 0.5, end: 2.0).animate(CurvedAnimation(parent: _eleaController, curve: Curves.easeOutBack));
    _eleaOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_eleaController);
  }

  void _triggerEleaFireworks() {
    setState(() => showElea = true);
    _eleaController.forward(from: 0).then((_) {
      setState(() => showElea = false);
    });
  }

  void _updatePointsAndStars() {
    final now = DateTime.now();
    setState(() {
      // Efface les points de plus de 400ms (ce qui correspond environ à une traînée de 6cm selon la vitesse du doigt)
      points.removeWhere((p) => now.difference(p.time).inMilliseconds > 400);
      stars.removeWhere((s) => now.difference(s.time).inMilliseconds > 800);
    });
  }

  void _addPoint(DragUpdateDetails details) {
    final now = DateTime.now();
    setState(() {
      points.add(DrawPoint(
        position: details.localPosition,
        time: now,
        // Changement de couleur arc-en-ciel basé sur le temps
        color: HSVColor.fromAHSV(1.0, (now.millisecondsSinceEpoch % 360).toDouble(), 1.0, 1.0).toColor(),
      ));

      // Génération aléatoire d'étoiles autour du doigt (rayon de 30 pixels)
      if (Random().nextDouble() > 0.5) {
        final offsetX = (Random().nextDouble() - 0.5) * 60;
        final offsetY = (Random().nextDouble() - 0.5) * 60;
        stars.add(Star(
          position: details.localPosition + Offset(offsetX, offsetY),
          time: now,
        ));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _eleaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          GestureDetector(
            onPanUpdate: _addPoint,
            onPanStart: (details) => points.clear(), // Nouveau trait
            child: CustomPaint(
              painter: AntiStressPainter(points, stars),
              size: Size.infinite,
            ),
          ),
          if (showElea)
            Center(
              child: AnimatedBuilder(
                animation: _eleaController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _eleaOpacity.value,
                    child: Transform.scale(
                      scale: _eleaScale.value,
                      child: const Text(
                        "Eléa",
                        style: TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber, // Couleur feu d'artifice
                          shadows: [
                            Shadow(color: Colors.pinkAccent, blurRadius: 20, offset: Offset(0, 0)),
                            Shadow(color: Colors.orange, blurRadius: 40, offset: Offset(0, 0)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class DrawPoint {
  final Offset position;
  final DateTime time;
  final Color color;
  DrawPoint({required this.position, required this.time, required this.color});
}

class Star {
  final Offset position;
  final DateTime time;
  Star({required this.position, required this.time});
}

class AntiStressPainter extends CustomPainter {
  final List<DrawPoint> points;
  final List<Star> stars;

  AntiStressPainter(this.points, this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    // Dessin de la ligne arc-en-ciel
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      
      // Calcule l'opacité en fonction de l'âge du point (effet de fondu arrière)
      final age = now.difference(p1.time).inMilliseconds;
      final opacity = (1.0 - (age / 400)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p1.color.withOpacity(opacity)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 15.0 // Épaisseur apaisante
        ..isAntiAlias = true;

      canvas.drawLine(p1.position, p2.position, paint);
    }

    // Dessin des petites étoiles
    for (var star in stars) {
      final age = now.difference(star.time).inMilliseconds;
      final opacity = (1.0 - (age / 800)).clamp(0.0, 1.0);
      
      final starPaint = Paint()
        ..color = Colors.amber.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(star.position, 3.0 + (opacity * 2), starPaint); // La taille varie avec le fondu
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}