// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';

// import '../../const/constant.dart';
// import '../authscreen/login_screen.dart';

// class NewPassword extends StatefulWidget {
//   const NewPassword({Key? key});

//   @override
//   State<NewPassword> createState() => _NewPasswordState();
// }

// class _NewPasswordState extends State<NewPassword> {
//   @override
//   Widget build(BuildContext context) {
//     bool showSheet = MediaQuery.of(context).viewInsets.bottom == 0.0;
//     return Scaffold(
//       backgroundColor: black,
//       bottomSheet: showSheet
//           ? GestureDetector(
//               onTap: () => goTo(
//                   context,
//                   LoginScreen(
//                     fromNav: false,
//                   ),
//                   false),
//               child: Container(
//                 height: 45,
//                 margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
//                 decoration: BoxDecoration(
//                   color: white,
//                   borderRadius: appRadius(8.0),
//                 ),
//                 child: Center(
//                     child: Text(
//                   'Reset',
//                   style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                 )),
//               ),
//             )
//           : null,
//       body: ListView(
//         children: [
//           Image.asset(
//             imageRounte(name:logoPath),
//             width: 150,
//             height: 150,
//           ),
//           h10(),
//           Text(
//             'Reset Password',
//             textAlign: TextAlign.center,
//             style: tStyle(color: white, size: 24.0),
//           ),
//           h10(),
//           Text(
//             'Input New Password',
//             textAlign: TextAlign.center,
//             style: tStyle(color: white, size: 14.0),
//           ),
//           h40(),
//           Form(
//               child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 15.0),
//             child: ListView(
//               shrinkWrap: true,
//               primary: false,
//               children: [
//                 formContainer(
//                   'New Password',
//                   TextFormField(
//                     style: tStyleTextField(),
//                     decoration: InputDecoration(
//                       border: InputBorder.none,
//                     ),
//                   ),
//                 ),
//                 h15(),
//                 formContainer(
//                   'Confirm Password',
//                   TextFormField(
//                     style: tStyleTextField(),
//                     decoration: InputDecoration(
//                         border: InputBorder.none,
//                         labelStyle: tStyle(color: white, size: 16.0)),
//                   ),
//                 ),
//                 h10(),
//               ],
//             ),
//           ))
//         ],
//       ),
//     );
//   }
// }
