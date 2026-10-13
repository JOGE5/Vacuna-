import 'package:flutter/material.dart';
import '../core/theme.dart';

const gap = SizedBox(height: 12);
String dateLabel(DateTime d) =>
    '${d.day} ${['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'][d.month - 1]} ${d.year}';
String shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
void go(BuildContext context, String route) =>
    Navigator.pushNamed(context, route);
void toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class Brand extends StatelessWidget {
  const Brand({super.key, this.large = false});
  final bool large;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        Icons.health_and_safety_outlined,
        color: green,
        size: large ? 48 : 28,
      ),
      const SizedBox(width: 5),
      Text.rich(
        TextSpan(
          text: 'Vacuna',
          children: const [
            TextSpan(
              text: 'Plus',
              style: TextStyle(color: green),
            ),
          ],
        ),
        style: TextStyle(
          color: ink,
          fontSize: large ? 38 : 20,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = 14});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7EEE9)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D123D30),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    // Material transparente para que ListTile/InkWell muestren el efecto táctil
    // sobre el fondo blanco del panel.
    child: Material(type: MaterialType.transparency, child: child),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final warning = text == 'Próxima',
        bad = text == 'Inactivo' || text == 'Cerrado';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bad
            ? const Color(0xFFFDE8E8)
            : warning
            ? const Color(0xFFFFF1D6)
            : mint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: bad
              ? Colors.red
              : warning
              ? Colors.orange
              : green,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class CircleMark extends StatelessWidget {
  const CircleMark({super.key, this.icon, this.text, this.size = 44});
  final IconData? icon;
  final String? text;
  final double size;
  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: mint,
    child: icon != null
        ? Icon(icon, color: green, size: size * .5)
        : Text(
            text ?? '',
            style: TextStyle(
              color: ink,
              fontSize: size * .32,
              fontWeight: FontWeight.bold,
            ),
          ),
  );
}

class ActionButton extends StatelessWidget {
  const ActionButton(
    this.label,
    this.onTap, {
    super.key,
    this.icon = Icons.add,
    this.outlined = false,
  });
  final String label;
  final VoidCallback onTap;
  final IconData icon;
  final bool outlined;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: outlined
        ? OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 20),
            label: Text(label),
          )
        : ElevatedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 20),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
  );
}

class SearchBox extends StatelessWidget {
  const SearchBox(this.hint, this.onChanged, {super.key});
  final String hint;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: muted),
      ),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, this.icon, {super.key});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Icon(icon, color: green, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: ink,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

class Notice extends StatelessWidget {
  const Notice(this.text, {super.key, this.warning = false});
  final String text;
  final bool warning;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: warning ? const Color(0xFFFFF3DF) : mint,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(
          warning ? Icons.warning_amber : Icons.info_outline,
          size: 20,
          color: warning ? Colors.orange : green,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: warning ? Colors.brown : ink),
          ),
        ),
      ],
    ),
  );
}

class Tabs extends StatelessWidget {
  const Tabs(this.items, this.selected, this.onSelect, {super.key});
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: items
          .map(
            (e) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onSelect(e),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: e == selected ? mint : Colors.white,
                      border: Border.all(color: const Color(0xFFE0E8E2)),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      e,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: ink,
                        fontWeight: e == selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
