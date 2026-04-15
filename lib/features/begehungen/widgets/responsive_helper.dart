import 'package:flutter/material.dart';

class ResponsiveHelper {
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1200;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1200;

  static int gridColumns(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }

  static EdgeInsets contentPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(32);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 800;
    return double.infinity;
  }

  static Widget centeredContent({
    required BuildContext context,
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
        child: Padding(padding: padding ?? contentPadding(context), child: child),
      ),
    );
  }

  static Widget responsiveTwoColumn({
    required BuildContext context,
    required Widget left,
    required Widget right,
    int leftFlex = 1,
    int rightFlex = 1,
    double spacing = 24,
  }) {
    if (isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [left, SizedBox(height: spacing), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: leftFlex, child: left),
        SizedBox(width: spacing),
        Expanded(flex: rightFlex, child: right),
      ],
    );
  }
}