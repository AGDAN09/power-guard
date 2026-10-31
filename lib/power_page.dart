import 'main.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class PowerPage extends StatefulWidget {
  const PowerPage({super.key});
  @override
  State<PowerPage> createState() => _PowerPageState();
}

class _PowerPageState extends State<PowerPage> {
  static const int maxPoints = 10;
  final _rand = Random();
  Timer? _timer;
  bool _running = false;
  bool _relayOn = true;

  final List<double> _volt = [];
  final List<double> _amp = [];
  final List<double> _watt = [];

  double _last(List<double> l) => l.isEmpty ? 0 : l.last;

  void _add(List<double> l, double x) {
    l.add(x);
    if (l.length > maxPoints) l.removeAt(0);
  }

  void _tick() {
    final v = 220 + (_rand.nextDouble() * 6 - 3);
    final a = _relayOn ? 0.5 + _rand.nextDouble() * 2 : 0.0;
    final w = v * a;
    setState(() {
      _add(_volt, v);
      _add(_amp, a);
      _add(_watt, w);
    });
  }

  void _toggleRun() {
    if (_running) {
      _timer?.cancel();
    } else {
      _tick();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    setState(() => _running = !_running);
  }

  void _reset() {
    setState(() {
      _volt.clear();
      _amp.clear();
      _watt.clear();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Power Guard'),
  actions: [
    IconButton(
      icon: const Icon(Icons.bluetooth_searching),
      tooltip: 'Scan Bluetooth',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScanPage()),
      ),
    ),
  ],
),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            children: [
              _ValueCard('Tegangan', 'V', _last(_volt), 1, Colors.orange),
              const SizedBox(width: 8),
              _ValueCard('Arus', 'A', _last(_amp), 2, Colors.blue),
              const SizedBox(width: 8),
              _ValueCard('Daya', 'W', _last(_watt), 1, Colors.green),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _toggleRun,
                  icon: Icon(_running ? Icons.stop : Icons.play_arrow),
                  label: Text(_running ? 'Stop' : 'Mulai'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _relayOn ? Colors.green : Colors.red,
              ),
              onPressed: () => setState(() => _relayOn = !_relayOn),
              icon: const Icon(Icons.power_settings_new),
              label: Text(_relayOn ? 'Relay: ON' : 'Relay: OFF'),
            ),
          ),
          const SizedBox(height: 16),
          _ChartCard('Grafik Tegangan', 'V', _volt, 1, Colors.orange),
          _ChartCard('Grafik Arus', 'A', _amp, 2, Colors.blue),
          _ChartCard('Grafik Daya', 'W', _watt, 1, Colors.green),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final String title, unit;
  final double value;
  final int decimals;
  final Color color;
  const _ValueCard(this.title, this.unit, this.value, this.decimals, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 6),
              Text(
                value.toStringAsFixed(decimals),
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              Text(unit, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title, unit;
  final List<double> data;
  final int decimals;
  final Color color;
  const _ChartCard(this.title, this.unit, this.data, this.decimals, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$title ($unit)',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: data.isEmpty
                  ? const Center(child: Text('Tekan Mulai untuk melihat data'))
                  : CustomPaint(
                      painter: _LinePainter(
                        data,
                        decimals,
                        color,
                        Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> data;
  final int decimals;
  final Color color;
  final Color textColor;
  _LinePainter(this.data, this.decimals, this.color, this.textColor);

  void _text(Canvas c, String s, Offset o,
      {double size = 10, bool center = false, bool right = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontSize: size, color: textColor.withValues(alpha: 0.75))),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = o.dx;
    if (center) dx -= tp.width / 2;
    if (right) dx -= tp.width;
    tp.paint(c, Offset(dx, o.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0, right = 14.0, top = 18.0, bottom = 22.0;
    final w = size.width - left - right;
    final h = size.height - top - bottom;

    var lo = data.reduce(min);
    var hi = data.reduce(max);
    var pad = (hi - lo) * 0.2;
    if (pad == 0) pad = max(hi.abs() * 0.05, 1);
    lo -= pad;
    hi += pad;
    if (lo < 0 && data.reduce(min) >= 0) lo = 0;

    double yOf(double v) => top + h - (v - lo) / (hi - lo) * h;
    double xOf(int i) => left + w * i / (_PowerMax.n - 1);

    final grid = Paint()
      ..color = textColor.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final v = lo + (hi - lo) * i / 4;
      final y = yOf(v);
      canvas.drawLine(Offset(left, y), Offset(left + w, y), grid);
      _text(canvas, v.toStringAsFixed(decimals), Offset(left - 6, y),
          right: true);
    }
    for (var i = 0; i < _PowerMax.n; i++) {
      canvas.drawLine(
          Offset(xOf(i), top), Offset(xOf(i), top + h), grid);
    }

    final line = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < data.length; i++) {
      final p = Offset(xOf(i), yOf(data[i]));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = color;
    for (var i = 0; i < data.length; i++) {
      final p = Offset(xOf(i), yOf(data[i]));
      canvas.drawCircle(p, 4.5, dot);
      _text(canvas, data[i].toStringAsFixed(decimals),
          Offset(p.dx, p.dy - 12),
          size: 9, center: true);
      _text(canvas, '${i + 1}', Offset(xOf(i), top + h + 12),
          center: true);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}

class _PowerMax {
  static const int n = 10;
}