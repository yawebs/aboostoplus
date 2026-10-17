// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:goa_radio/const/constant.dart';
// import 'package:goa_radio/forgot_password/new_password.dart';
// import 'package:goa_radio/styles/styles.dart';
// import 'package:hexcolor/hexcolor.dart';
// import 'package:pin_code_fields/pin_code_fields.dart';

// class ResetCode extends StatefulWidget {
//   const ResetCode({super.key});

//   @override
//   State<ResetCode> createState() => _ResetCodeState();
// }

// class _ResetCodeState extends State<ResetCode> {
//   TextEditingController textEditingController = TextEditingController();
//   bool hasError = false;
//   String currentText = "";
//   final formKey = GlobalKey<FormState>();
//   StreamController<ErrorAnimationType>? errorController;
//   @override
//   Widget build(BuildContext context) {
//     bool showSheet = MediaQuery.of(context).viewInsets.bottom == 0.0;
//     return Scaffold(
//       backgroundColor: black,
//       bottomSheet: showSheet
//           ? GestureDetector(
//               onTap: () => goTo(context, NewPassword()),
//               child: Container(
//                 height: 45,
//                 margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
//                 decoration: BoxDecoration(
//                   color: white,
//                   borderRadius: appRadius(8.0),
//                 ),
//                 child: Center(
//                     child: Text(
//                   'Resend',
//                   style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//                 )),
//               ),
//             )
//           : null,
//       body: ListView(
//         children: [
//           Stack(
//             children: [
//               Positioned(
//                 child: SvgPicture.asset(
//                   imageRoute('shadeTop.svg'),
//                   width: 100,
//                   color: grey,
//                 ),
//               )
//             ],
//           ),
//           Image.asset(
//             imageRoute('logo_new.png'),
//             width: 150,
//             height: 150,
//           ),
//           h10(),
//           Text(
//             'Verify Email',
//             textAlign: TextAlign.center,
//             style: tStyle(color: white, size: 24.0),
//           ),
//           h10(),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 25.0),
//             child: Text(
//               'We have sent the OTP verification code to your email address. Check your email and input it below',
//               textAlign: TextAlign.center,
//               style: tStyle(color: white, size: 14.0),
//             ),
//           ),
//           h40(),
//           Form(
//             key: formKey,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(
//                 vertical: 8.0,
//                 horizontal: 60,
//               ),
//               child: PinCodeTextField(
//                 appContext: context,
//                 pastedTextStyle: TextStyle(
//                   color: Colors.green.shade600,
//                   fontWeight: FontWeight.bold,
//                 ),
//                 length: 4,
//                 obscureText: true,
//                 obscuringCharacter: '*',
//                 // obscuringWidget: const FlutterLogo(
//                 //   size: 24,
//                 // ),
//                 blinkWhenObscuring: true,
//                 animationType: AnimationType.fade,
//                 validator: (v) {
//                   if (v!.length < 3) {
//                     return "I'm from validator";
//                   } else {
//                     return null;
//                   }
//                 },
//                 pinTheme: PinTheme(
//                     shape: PinCodeFieldShape.box,
//                     borderRadius: BorderRadius.circular(5),
//                     fieldHeight: 50,
//                     fieldWidth: 40,
//                     activeFillColor: Colors.white,
//                     inactiveColor: yellow,
//                     inactiveFillColor: yellow),

//                 cursorColor: Colors.black,
//                 animationDuration: const Duration(milliseconds: 300),
//                 enableActiveFill: true,
//                 errorAnimationController: errorController,
//                 controller: textEditingController,
//                 keyboardType: TextInputType.number,
//                 boxShadows: const [
//                   BoxShadow(
//                     offset: Offset(0, 1),
//                     color: Colors.black12,
//                     blurRadius: 10,
//                   )
//                 ],
//                 onCompleted: (v) {
//                   debugPrint("Completed");
//                 },
//                 // onTap: () {
//                 //   print("Pressed");
//                 // },
//                 onChanged: (value) {
//                   debugPrint(value);
//                   setState(() {
//                     currentText = value;
//                   });
//                 },
//                 beforeTextPaste: (text) {
//                   debugPrint("Allowing to paste $text");
//                   //if you return true then it will show the paste confirmation dialog. Otherwise if false, then nothing will happen.
//                   //but you can show anything you want here, like your pop up saying wrong paste format or etc
//                   return true;
//                 },
//               ),
//             ),
//           ),
//           h10(),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 25.0),
//             child: Text(
//               'Didn’t recieve email?',
//               textAlign: TextAlign.center,
//               style: tStyle(color: white, size: 14.0),
//             ),
//           ),
//           h10(),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 'You can resend code in',
//                 textAlign: TextAlign.center,
//                 style: tStyle(color: white, size: 14.0),
//               ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 5.0),
//                 child: Text(
//                   '55',
//                   textAlign: TextAlign.center,
//                   style: tStyle(color: yellow, size: 14.0),
//                 ),
//               ),
//               Text(
//                 's',
//                 textAlign: TextAlign.center,
//                 style: tStyle(color: white, size: 14.0),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
