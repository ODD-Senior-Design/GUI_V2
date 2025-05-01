import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/theme.dart';

PreferredSizeWidget customAppBar(Function onItemTapped, int selectedIndex) {
  return AppBar(
    toolbarHeight: 175,
    backgroundColor: utsaOrange,
    elevation: 5,
    title: _CustomAppBarContent(onItemTapped: onItemTapped),
  );
}

class _CustomAppBarContent extends StatelessWidget {
  final Function onItemTapped;

  const _CustomAppBarContent({required this.onItemTapped});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildPositionedLogo(screenHeight, screenWidth),
        _buildPositionedUTSALogo(screenHeight, screenWidth),
        _buildActionButtons(),
      ],
    );
  }

  Positioned _buildPositionedLogo(double screenHeight, double screenWidth) {
    return Positioned(
      top: screenHeight * -0.13,  // Padding
      left: screenWidth * -0.05,
      child: SvgPicture.asset(
        'assets/images/O.D.D..svg',
        height: screenHeight * 0.36,  // Sizing
        width: screenWidth * 0.25,
      ),
    );
  }

  Positioned _buildPositionedUTSALogo(double screenHeight, double screenWidth) {
    return Positioned(
      top: 0, // Padding
      right: -2,
      child: SvgPicture.asset(
        'assets/images/utsa-roadrunners-seeklogo.svg',
        height: screenHeight * 0.1,  // Sizing
        width: screenWidth * 0.15,
      ),
    );
  }

  Align _buildActionButtons() {
    return Align(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconButton(Icons.search, 73, 2),
          SizedBox(width: 70), // Space between icons
          _buildIconButton(Icons.camera_alt_outlined, 70, 0),
          SizedBox(width: 70), // Space between icons
          _buildIconButton(Icons.history, 70, 1),
        ],
      ),
    );
  }

  IconButton _buildIconButton(IconData icon, double size, int index) {
    return IconButton(
      icon: Icon(icon, color: oddBlue, size: size),
      onPressed: () => onItemTapped(index),
    );
  }
}