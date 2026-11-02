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
  List<FireworkParticle> fireworkParticles = [];
  Timer? _timer;
  bool showEleaText = false;
  
  late AnimationController _textController;
  late Animation<double> _textOpacity;
  late Animation<double> _textScale;

  @override
  void initState() {
    super.initState();

    // Boucle de rafraîchissement (60 FPS) pour le fondu des traits et les particules
    Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateCanvas();
    });

    // Apparition d'Eléa toutes les 8 secondes
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _triggerEleaSequence();
    });

    // Animation d'apparition du prénom
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textScale = Tween<double>(begin: 0.6, end: 1.2).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutBack),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_textController);
  }

  void _triggerEleaSequence() {
    // 1. Apparition du texte
    setState(() => showEleaText = true);
    _textController.forward(from: 0);

    // 2. Déclenchement du feu d'artifice après 1.5 seconde de visibilité
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _explodeElea();
    });
  }

  void _explodeElea() {
    final size = MediaQuery.of(context).size;
    final center = Offset(size.width / 2, size.height / 2);
    final random = Random();

    // Masque le texte et génère 80 particules multicolores
    setState(() {
      showEleaText = false;
      _textController.reset();

      for (int i = 0; i < 80; i++) {
        final angle = random.nextDouble() * 2 * pi;
        final speed = 3.0 + random.nextDouble() * 9.0;
        final color = HSVColor.fromAHSV(
          1.0,
          random.nextDouble() * 360,
          0.85,
          1.0,
        ).toColor();

        fireworkParticles.add(FireworkParticle(
          position: center,
          velocity: Offset(cos(angle) * speed, sin(angle) * speed),
          color: color,
          radius: 3.0 + random.nextDouble() * 3.5,
          time: DateTime.now(),
        ));
      }
    });
  }

  void _updateCanvas() {
    final now = DateTime.now();
    setState(() {
      // Efface le trait au-delà de 400ms (limite ~6cm selon vitesse)
      points.removeWhere((p) => now.difference(p.time).inMilliseconds > 400);

      // Efface les petites étoiles autour du doigt après 800ms
      stars.removeWhere((s) => now.difference(s.time).inMilliseconds > 800);

      // Mise à jour de la physique des particules de feu d'artifice
      for (var p in fireworkParticles) {
        p.position += p.velocity;
        p.velocity += const Offset(0, 0.18); // Gravité
      }
      // Suppression des particules après 1.2 seconde
      fireworkParticles.removeWhere((p) => now.difference(p.time).inMilliseconds > 1200);
    });
  }

  void _addPoint(DragUpdateDetails details) {
    final now = DateTime.now();
    setState(() {
      points.add(DrawPoint(
        position: details.localPosition,
        time: now,
        color: HSVColor.fromAHSV(
          1.0,
          (now.millisecondsSinceEpoch % 360).toDouble(),
          1.0,
          1.0,
        ).toColor(),
      ));

      // Étoiles scintillantes autour du doigt
      if (Random().nextDouble() > 0.45) {
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
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Zone tactile de dessin
          GestureDetector(
            onPanUpdate: _addPoint,
            onPanStart: (details) => points.clear(),
            child: CustomPaint(
              painter: AntiStressPainter(points, stars, fireworkParticles),
              size: Size.infinite,
            ),
          ),

          // Prénom Eléa au centre
          if (showEleaText)
            Center(
              child: AnimatedBuilder(
                animation: _textController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.scale(
                      scale: _textScale.value,
                      child: const Text(
                        "Eléa",
                        style: TextStyle(
                          fontSize: 65,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurpleAccent,
                          shadows: [
                            Shadow(color: Colors.pinkAccent, blurRadius: 25),
                            Shadow(color: Colors.cyanAccent, blurRadius: 35),
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

class FireworkParticle {
  Offset position;
  Offset velocity;
  final Color color;
  final double radius;
  final DateTime time;

  FireworkParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.time,
  });
}

class AntiStressPainter extends CustomPainter {
  final List<DrawPoint> points;
  final List<Star> stars;
  final List<FireworkParticle> fireworks;

  AntiStressPainter(this.points, this.stars, this.fireworks);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    // 1. Dessin de la trace arc-en-ciel
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final age = now.difference(p1.time).inMilliseconds;
      final opacity = (1.0 - (age / 400)).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p1.color.withOpacity(opacity)
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 16.0
        ..isAntiAlias = true;

      canvas.drawLine(p1.position, p2.position, paint);
    }

    // 2. Dessin des étoiles du doigt
    for (var star in stars) {
      final age = now.difference(star.time).inMilliseconds;
      final opacity = (1.0 - (age / 800)).clamp(0.0, 1.0);

      final starPaint = Paint()
        ..color = Colors.amber.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(star.position, 2.5 + (opacity * 2.5), starPaint);
    }

    // 3. Dessin des particules du feu d'artifice
    for (var particle in fireworks) {
      final age = now.difference(particle.time).inMilliseconds;
      final opacity = (1.0 - (age / 1200)).clamp(0.0, 1.0);

      final particlePaint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.radius * opacity, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}