import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:namer_app/widgets/theme.dart';

PreferredSizeWidget customAppBar(Function onItemTapped, int selectedIndex) {
  return AppBar(
    toolbarHeight: 180,
    backgroundColor: utsaOrange,
    elevation: 0,
    title: Builder(
      builder: (BuildContext context) {
        double screenHeight = MediaQuery.of(context).size.height;
        double screenWidth = MediaQuery.of(context).size.width;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: screenHeight * -0.138,  // Padding
              left: screenWidth * -0.04, 
              child: SvgPicture.asset(
                'assets/images/O.D.D..svg',
                height: screenHeight * 0.36,  // Sizing
                width: screenWidth * 0.25,  
              ),
            ),
            Positioned(
              top: 0, // Padding
              right: 0,
              child: SvgPicture.asset(
                'assets/images/utsa-roadrunners-seeklogo.svg',
                height: screenHeight * 0.1,  // Sizing
                width: screenWidth * 0.15,   
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.camera, color: oddBlue, size: 70),
                    onPressed: () => onItemTapped(0),
                  ),
                  SizedBox(width: 70), // Space between icons
                  IconButton(
                    icon: Icon(Icons.history, color: oddBlue, size: 70),
                    onPressed: () => onItemTapped(1),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
