import 'package:flutter/material.dart';

class Cbx extends StatelessWidget {
  final String label;
  final bool value;
  final void Function({required bool? value}) update;

  const Cbx(
    this.label,
    this.update, {
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: (v) => update(value: v),
    );
  }
}

class TabContent extends StatelessWidget {
  final List<Widget> children;

  const TabContent({
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          controller: ScrollController(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
