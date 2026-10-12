import 'package:flutter/material.dart';
import '../core/theme.dart';

class PageShell extends StatelessWidget {
  const PageShell({
    super.key,
    required this.child,
    this.title,
    this.navIndex,
    this.back = false,
    this.actions = const [],
  });
  final Widget child;
  final String? title;
  final int? navIndex;
  final bool back;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Row(
                    children: [
                      if (back)
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back, color: green),
                        ),
                      Expanded(
                        child: Text(
                          title!,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: child,
                ),
              ),
              if (navIndex != null) _BottomNav(navIndex!),
            ],
          ),
        ),
      ),
    ),
  );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav(this.index);
  final int index;
  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFEAF0EC))),
    ),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: Row(
      children: List.generate(
        4,
        (i) => Expanded(
          child: InkWell(
            onTap: () {
              final route = ['/home', '/campaigns', '/patients', '/more'][i];
              Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: index == i ? mint : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    [
                      Icons.home_outlined,
                      Icons.campaign_outlined,
                      Icons.people_outline,
                      Icons.more_horiz,
                    ][i],
                    color: index == i ? green : muted,
                  ),
                  Text(
                    ['Inicio', 'Campañas', 'Pacientes', 'Más'][i],
                    style: TextStyle(
                      fontSize: 11,
                      color: index == i ? green : muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
