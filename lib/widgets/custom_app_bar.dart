import 'package:flutter/material.dart';
import 'package:toonplay/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget{
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CustomAppBar> createState() {
    return _CustomAppBarState();
  }
}

class _CustomAppBarState extends State<CustomAppBar>{

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border(
              bottom: BorderSide(color: AppColors.primary, width: 3),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppBorderRadius.lg),
              bottomRight: Radius.circular(AppBorderRadius.lg),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(AppBorderRadius.lg),
              bottomRight: Radius.circular(AppBorderRadius.lg),
            ),
            child: AppBar(
              title: Text(
                'Home',
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
      );
  }
}