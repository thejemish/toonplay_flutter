import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:toonplay/theme/theme.dart';

class CustomBottomBar extends StatefulWidget {
  const CustomBottomBar({super.key});

  @override
  State<CustomBottomBar> createState() {
    return _CustomBottomBarState();
  }
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.primary, width: 3)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.lg),
          topRight: Radius.circular(AppBorderRadius.lg),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.lg),
          topRight: Radius.circular(AppBorderRadius.lg),
        ),
        child: NavigationBar(
          onDestinationSelected: (int index) {
            setState(() {
              currentPageIndex = index;
            });
          },
          indicatorColor: Colors.transparent,
          overlayColor: WidgetStateColor.fromMap({
            WidgetState.pressed: Colors.transparent,
          }),
          indicatorShape: const CircleBorder(),
          height: 70,
          selectedIndex: currentPageIndex,
          backgroundColor: AppColors.card,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
          destinations: <Widget>[
            NavigationDestination(
              selectedIcon: Icon(
                PhosphorIcons.house(PhosphorIconsStyle.fill),
                size: 40,
                color: AppColors.primary,
              ),
              icon: Icon(
                PhosphorIcons.house(PhosphorIconsStyle.regular),
                size: 40,
                color: AppColors.textSecondary,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              selectedIcon: Icon(
                PhosphorIcons.youtubeLogo(PhosphorIconsStyle.fill),
                size: 48,
                color: AppColors.primary,
              ),
              icon: Icon(
                PhosphorIcons.youtubeLogo(PhosphorIconsStyle.regular),
                size: 48,
                color: AppColors.textSecondary,
              ),
              label: 'Notifications',
            ),
            NavigationDestination(
              selectedIcon: Icon(
                PhosphorIcons.heart(PhosphorIconsStyle.fill),
                size: 44,
                color: AppColors.primary,
              ),
              icon: Icon(
                PhosphorIcons.heart(PhosphorIconsStyle.regular),
                size: 44,
                color: AppColors.textSecondary,
              ),
              label: 'Messages',
            ),
          ],
        ),
      ),
    );
  }
}
