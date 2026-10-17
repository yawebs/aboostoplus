import 'package:eafind/theme/app_palette.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:eafind/screens/authscreen/signup_agent.dart';
import 'package:eafind/screens/authscreen/signup_user.dart';
import 'package:flutter/material.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

import '../../const/constant.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({Key? key}) : super(key: key);

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  String selectedType = 'User';
  List<String> userTypes = ['Land Lord', 'Agent', 'User'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomSheet: GestureDetector(
        onTap: () {
          switch (selectedType) {
            case 'User':
              goTo(context, SignupUser(), false);
              break;
            case 'Agent':
              goTo(context, SignAgent(), false);
              break;
          }
        },
        child: Container(
          height: 45,
          width: width(context),
          margin: EdgeInsets.symmetric(horizontal: 10),
          decoration:
              BoxDecoration(color: context.palette.primaryFill, borderRadius: appRadius(10.0)),
          child: Center(
            child: Text(
              'Next',
              textAlign: TextAlign.center,
              style: tStyleWhite,
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: grey.withOpacity(.01),
        elevation: 0.0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: StepProgressIndicator(
          totalSteps: 3,
          currentStep: 1,
          selectedColor: context.palette.accent,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5.0),
              child: Text(
                'Welcome To Aboostoplus!👋',
                style: tHeading.copyWith(color: context.palette.accent),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 5.0, top: 5),
              child: Text('Lets help create an account for you in few steps'),
            ),
            const SizedBox(
              height: 30,
            ),
            Padding(
              padding: EdgeInsets.only(left: 5.0, top: 5),
              child: Text(
                'What Kind Of Account Are You Creating?',
                style: TextStyle(color: context.palette.accent),
              ),
            ),
            SizedBox(
              width: width(context),
              height: 50,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: appRadius(10.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    isExpanded: true,
                    hint: Row(
                      children: [
                        Icon(
                          Icons.list,
                          size: 16,
                          color: context.palette.accent,
                        ),
                        const SizedBox(
                          width: 4,
                        ),
                        Expanded(
                          child: Text(
                            selectedType,
                            style: TextStyle(
                              fontSize: 14,
                              color: context.palette.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    items: userTypes
                        .map((item) => DropdownMenuItem<String>(
                              value: item,
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value as String;
                        // getDataReport();
                        // getComparison();
                      });
                    },
                    iconStyleData: IconStyleData(
                      icon: Icon(
                        Icons.arrow_drop_down,
                        size: 25,
                        color: context.palette.ink,
                      ),
                      iconSize: 14,
                      iconEnabledColor: white,
                      iconDisabledColor: Colors.grey,
                    ),
                    dropdownStyleData: DropdownStyleData(
                      maxHeight: 40,
                      padding: null,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: context.palette.paper,
                      ),
                      elevation: 8,
                      offset: const Offset(-20, 0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
