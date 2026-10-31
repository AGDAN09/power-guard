import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'app_theme.dart';
import 'main.dart';

const bool kDataDariEsp = false;
const TextStyle _labelStyle = TextStyle(
  fontSize: 11,
  letterSpacing: 1.2,
  fontWeight: FontWeight.w700,
  color: AppColors.muted,
);

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

  void _openScan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _volt.isNotEmpty;
    String fmt(double v, int d) => hasData ? v.toStringAsFixed(d) : '--';

    final voltOk = !hasData || (_last(_volt) >= 200 && _last(_volt) <= 240);
    final loadOk = !hasData || _last(_watt) <= 500;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: const Text(
          'POWER GUARD',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 20,
          ),
        ),
        actions: [
          ValueListenableBuilder<ScanResult?>(
            valueListenable: connectedDevice,
            builder: (context, dev, child) =>
                _StatusPill(connected: dev != null),
          ),
          IconButton(
            icon: const Icon(Icons.bluetooth_searching, color: AppColors.cyan),
            tooltip: 'Scan Bluetooth',
            onPressed: _openScan,
          ),
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(2),
          child: GradientLine(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _SimBanner(),
          Panel(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    _StartButton(running: _running, onTap: _toggleRun),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _MetricLabel(
                              Icons.bolt, 'TEGANGAN', AppColors.cyan),
                          _BigNumber(fmt(_last(_volt), 0), 'V', AppColors.cyan),
                          const SizedBox(height: 14),
                          const _MetricLabel(
                              Icons.speed, 'ARUS', const Color.fromARGB(255, 0, 245, 49)),
                          _BigNumber(
                              fmt(_last(_amp), 2), 'A',  const Color.fromARGB(255, 0, 245, 49)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.border, height: 36),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _MetricLabel(
                            Icons.flash_on, 'DAYA', AppColors.amber),
                        _BigNumber(fmt(_last(_watt), 0), 'W', AppColors.amber),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('RELAY CONTROL', style: _labelStyle),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NeonSwitch(
                              value: _relayOn,
                              onChanged: (v) => setState(() => _relayOn = v),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _relayOn ? 'ON' : 'OFF',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: _relayOn ? Colors.white : AppColors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ---------- Lencana status ----------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Badge(
                icon: Icons.shield,
                label: voltOk ? 'Aman' : 'Tidak aman',
                color: voltOk ? AppColors.green : AppColors.red,
              ),
              _Badge(
                icon: Icons.speed,
                label: loadOk ? 'Beban' : 'Beban tinggi',
                color: loadOk ? AppColors.green : AppColors.amber,
              ),
              // TODO: sambungkan ke sensor suhu ESP32
              const _Badge(
                icon: Icons.thermostat,
                label: 'Suhu',
                color: AppColors.green,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ---------- Info perangkat ----------
          _InfoPanel(onChange: _openScan),
          const SizedBox(height: 24),

          // ---------- Grafik ----------
          Stack(
            alignment: Alignment.center,
            children: [
              const Text('GRAFIK MONITORING', style: _labelStyle),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ChartCard('Tegangan', 'V', _volt, 1, AppColors.cyan),
          _ChartCard('Arus', 'A', _amp, 2, const Color.fromARGB(255, 0, 245, 49)),
          _ChartCard('Daya', 'W', _watt, 1, AppColors.amber),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool connected;
  const _StatusPill({required this.connected});

  @override
  Widget build(BuildContext context) {
    final c = connected ? AppColors.green : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'Terhubung' : 'Terputus',
            style: TextStyle(
              color: c,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  final bool running;
  final VoidCallback onTap;
  const _StartButton({required this.running, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = running ? AppColors.red : AppColors.cyan;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 130,
        height: 130,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.withValues(alpha: 0.14),
          border: Border.all(color: c, width: 2),
          boxShadow: [
            BoxShadow(
              color: c.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          running ? 'STOP' : 'MULAI',
          style: TextStyle(
            color: c,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _MetricLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  const _MetricLabel(this.icon, this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(text, style: _labelStyle),
      ],
    );
  }
}

class _BigNumber extends StatelessWidget {
  final String value, unit;
  final Color color;
  const _BigNumber(this.value, this.unit, this.color);

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w200,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 2),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleIcon(icon: icon, color: color, size: 52),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final VoidCallback onChange;
  const _InfoPanel({required this.onChange});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScanResult?>(
      valueListenable: connectedDevice,
      builder: (context, dev, child) {
        final name = dev == null
            ? 'Belum terhubung'
            : (scanName(dev).isEmpty ? '(tanpa nama)' : scanName(dev));
        final mac = dev?.device.remoteId.str ?? '-';
        final signal =
            dev == null ? '-' : '${dev.rssi} dBm (${jarakLabel(dev.rssi)})';

        return Panel(
          child: Column(
            children: [
              _InfoRow(Icons.memory, 'Perangkat', name),
              const SizedBox(height: 14),
              _InfoRow(Icons.fingerprint, 'Alamat', mac),
              const SizedBox(height: 14),
              _InfoRow(
                Icons.signal_cellular_alt,
                'Sinyal',
                signal,
                trailing: GestureDetector(
                  onTap: onChange,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Text(
                      'Ganti Perangkat',
                      style: TextStyle(
                        color: AppColors.cyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Widget? trailing;
  const _InfoRow(this.icon, this.label, this.value, {this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIcon(icon: icon, color: Colors.white70, size: 42),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.muted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
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
    return Panel(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title ($unit)',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'Tekan MULAI untuk melihat data',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  )
                : CustomPaint(painter: _LinePainter(data, decimals, color)),
          ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> data;
  final int decimals;
  final Color color;
  _LinePainter(this.data, this.decimals, this.color);

  void _text(
    Canvas c,
    String s,
    Offset o, {
    double size = 10,
    bool center = false,
    bool alignRight = false,
    Color? col,
    FontWeight? weight,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          color: col ?? AppColors.muted,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = o.dx;
    if (center) dx -= tp.width / 2;
    if (alignRight) dx -= tp.width;
    tp.paint(c, Offset(dx, o.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    const padL = 40.0, padR = 20.0, padT = 18.0, padB = 22.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;

    var lo = data.reduce(min);
    var hi = data.reduce(max);
    var pad = (hi - lo) * 0.2;
    if (pad == 0) pad = max(hi.abs() * 0.05, 1);
    lo -= pad;
    hi += pad;
    if (lo < 0 && data.reduce(min) >= 0) lo = 0;

    double yOf(double v) => padT + h - (v - lo) / (hi - lo) * h;
    double xOf(int i) => padL + w * i / (_PowerMax.n - 1);

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final v = lo + (hi - lo) * i / 4;
      final y = yOf(v);
      canvas.drawLine(Offset(padL, y), Offset(padL + w, y), grid);
      _text(canvas, v.toStringAsFixed(decimals), Offset(padL - 6, y),
          alignRight: true);
    }

    for (var i = 0; i < _PowerMax.n; i++) {
      canvas.drawLine(
          Offset(xOf(i), padT), Offset(xOf(i), padT + h), grid);
      _text(canvas, '${i + 1}', Offset(xOf(i), padT + h + 12), center: true);
    }

    final pts = [
      for (var i = 0; i < data.length; i++) Offset(xOf(i), yOf(data[i])),
    ];

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final cx = (a.dx + b.dx) / 2;
      path.cubicTo(cx, a.dy, cx, b.dy, b.dx, b.dy);
    }

    if (pts.length > 1) {
      final fill = Path.from(path)
        ..lineTo(pts.last.dx, padT + h)
        ..lineTo(pts.first.dx, padT + h)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromLTWH(padL, padT, w, h)),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );

    final dot = Paint()..color = color;
    for (final p in pts) {
      canvas.drawCircle(p, 4, dot);
    }

    _text(
      canvas,
      data.last.toStringAsFixed(decimals),
      Offset(pts.last.dx, pts.last.dy - 14),
      size: 11,
      center: true,
      col: color,
      weight: FontWeight.w700,
    );
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}

class _PowerMax {
  static const int n = 10;
}
class _SimBanner extends StatelessWidget {
  const _SimBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ScanResult?>(
      valueListenable: connectedDevice,
      builder: (context, dev, child) {
        final espAsli = dev != null;

        if (espAsli && kDataDariEsp) return const SizedBox.shrink();


        final String detail;
        if (dev == null) {
          detail = 'Belum terhubung ke ESP32. Angka hanya contoh.';
        } else {
          detail = 'Terhubung, tapi data ESP32 belum dibaca.';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.amber.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SIMULASI',
                style: TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(detail, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    );
  }
}