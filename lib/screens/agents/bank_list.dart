import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/services/db_services.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:flutter_popup/flutter_popup.dart';

import '../../const/constant.dart';

class BankList extends StatefulWidget {
  final UserModel user;
  const BankList({Key? key, required this.user}) : super(key: key);

  @override
  State<BankList> createState() => _BankListState();
}

class _BankListState extends State<BankList> {
  bool _isLoading = false;
  bool _dataLoading = false;
  int tappedIndex = 0;
  List<dynamic> banks = [];
  getBanks() async {
    setState(() {
      _dataLoading = true;
    });
    List<dynamic> data = await DbServices.getBanks(widget.user.id);
    setState(() {
      banks = data;
      _dataLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getBanks();
    debugPrint('OwnerId: ${widget.user.id}');
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.paper,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: context.palette.paper,
        leading: GestureDetector(
          onTap: () => goTo(context, BottomNavHome(), false),
          child: Icon(
            Icons.arrow_back_ios,
            color: context.palette.ink,
            size: 17,
          ),
        ),
        title: Text('My Accounts',
            style: TextStyle(
              color: context.palette.ink,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => goBack(context),
              child: Icon(
                Icons.remove,
                color: context.palette.ink,
                size: 15,
              ),
            ),
          )
        ],
      ),
      body: _dataLoading
          ? Container(
              height: height(context),
              child: Center(
                child: appLoader(50.0),
              ),
            )
          : (_dataLoading == false && banks.isEmpty)
              ? Container(
                  height: height(context),
                  child: Center(
                    child: Text('No Banks'),
                  ),
                )
              : bankListViewWidget(banks),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => goTo(context, BottomNavHome(), false),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new,
                                    size: 16, color: AppColors.textDark),
                                const SizedBox(width: 6),
                                const Text('Back',
                                    style: TextStyle(color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ),
                        const Text(
                          'My accounts',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => goBack(context),
                            child: const Icon(Icons.close,
                                color: AppColors.textDark, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_dataLoading)
                      Padding(
                        padding: const EdgeInsets.all(48),
                        child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary)),
                      )
                    else if (banks.isEmpty)
                      const EmptyState(
                        icon: Icons.account_balance_outlined,
                        title: 'No banks added yet',
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: banks.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 380,
                          mainAxisSpacing: 18,
                          crossAxisSpacing: 18,
                          childAspectRatio: 1.55,
                        ),
                        itemBuilder: (context, index) =>
                            _bankCard(banks[index], index),
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

  Widget _bankCard(dynamic data, int index) {
    if (_isLoading && tappedIndex == index) {
      return Center(child: CircularProgressIndicator(color: context.palette.accent));
    }
    return Stack(
      children: [
        CreditCardWidget(
          cardBgColor: primaryColor,
          cardNumber: data['accountNumber'].toString(),
          expiryDate: data['dateCreated'].toString().split(' ').first,
          cardHolderName: data['accountName'],
          cvvCode: '254',
          isHolderNameVisible: true,
          labelValidThru: 'DATE CREATED ',
          obscureCardNumber: true,
          bankName: data['bankName'],
          showBackView: false,
          onCreditCardWidgetChange: (CreditCardBrand brand) {},
        ),
        Positioned(
          right: 20,
          bottom: 16,
          child: data['defaultBank'] == 1
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('Default', style: TextStyle(color: Colors.white)),
                    Padding(
                      padding: EdgeInsets.only(left: 2.0),
                      child: Icon(Icons.verified, color: Colors.white, size: 16),
                    ),
                  ],
                )
              : const Text('Not set',
                  style: TextStyle(fontSize: 12, color: Colors.white70)),
        ),
        Positioned(
          right: 12,
          top: 12,
          child: CustomPopup(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    goBack(context);
                    setState(() {
                      tappedIndex = index;
                      _isLoading = true;
                    });
                    var response = await DbServices.setDefaultBank(
                        widget.user.id, int.parse(data['id'].toString()));
                    setState(() {
                      _isLoading = false;
                    });
                    if (response['status'] == true) {
                      getBanks();
                      successSnackBar(
                          'Default bank successfully set', context);
                    } else {
                      showErrorSnackbar(response['message'], context);
                    }
                  },
                  child: const Text('Set default'),
                ),
              ],
            ),
            child: const Icon(Icons.more_vert, color: Colors.white70, size: 18),
          ),
        ),
      ],
    );
  }

  Widget bankListViewWidget(List<dynamic> snapshot) {
    return ListView.builder(
        itemCount: snapshot.length,
        shrinkWrap: true,
        itemBuilder: (ctx, index) {
          var data = snapshot[index];
          return (_isLoading && tappedIndex == index)
              ? Center(child: appLoader(35.0))
              : Stack(
                  children: [
                    CreditCardWidget(
                      cardBgColor: primaryColor,
                      cardNumber: data['accountNumber'].toString(),
                      expiryDate:
                          data['dateCreated'].toString().split(' ').first,
                      cardHolderName: data['accountName'],
                      cvvCode: '254',
                      isHolderNameVisible: true,
                      labelValidThru: 'DATE CREATED ',

                      obscureCardNumber: true,
                      bankName: data['bankName'],
                      showBackView:
                          false, //true when you want to show cvv(back) view
                      onCreditCardWidgetChange: (CreditCardBrand
                          brand) {}, // Callback for anytime credit card brand is changed
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        right: 20,
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: data['defaultBank'] == 1
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Default'),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 2.0),
                                    child: Icon(
                                      Icons.verified,
                                      color: context.palette.accent,
                                      size: 16,
                                    ),
                                  )
                                ],
                              )
                            : Text(
                                'Not Set',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: (index == 3) ? white : context.palette.ink),
                              ),
                      ),
                    ),
                    Positioned(
                        right: 20,
                        top: 80,
                        child: CustomPopup(
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                  onTap: () async {
                                    goBack(context);
                                    setState(() {
                                      tappedIndex = index;
                                      _isLoading = true;
                                    });
                                    var response =
                                        await DbServices.setDefaultBank(
                                            widget.user.id,
                                            int.parse(data['id'].toString()));
                                    setState(() {
                                      _isLoading = false;
                                    });
                                    if (response['status'] == true) {
                                      getBanks();
                                      successSnackBar(
                                          'Defualt Bank Successfully Set',
                                          context);
                                    } else {
                                      showErrorSnackbar(
                                          response['message'], context);
                                    }
                                  },
                                  child: Text('Set DEFAULT')),
                            ],
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: grey,
                            size: 18,
                          ),
                        ))
                  ],
                );

          // Padding(
          //     padding: const EdgeInsets.all(8.0),
          //     child: Row(
          //       children: [
          //         SizedBox(
          //           width: width(context) / 1.15,
          //           child: Column(
          //             crossAxisAlignment: CrossAxisAlignment.start,
          //             children: [
          //               Text(
          //                 data['bankName'],
          //                 style: TextStyle(fontWeight: FontWeight.bold),
          //               ),
          //               h10(),
          //               Container(
          //                 padding: const EdgeInsets.all(8.0),
          //                 decoration: BoxDecoration(
          //                   borderRadius: appRadius(8.0),
          //                   color: (index == 3) ? primaryColor : lightGrey,
          //                 ),
          //                 child: Column(
          //                   children: [
          //                     Padding(
          //                       padding: const EdgeInsets.only(top: 8.0),
          //                       child: Row(
          //                         children: [
          //                           CircleAvatar(
          //                             backgroundColor: (index == 3)
          //                                 ? lightGrey
          //                                 : primaryColor,
          //                             child: Icon(
          //                               FontAwesomeIcons.bank,
          //                               size: 18,
          //                               color: (index == 3)
          //                                   ? primaryColor
          //                                   : white,
          //                             ),
          //                           ),
          //                           w10(),
          //                           Expanded(
          //                             child: Column(
          //                               mainAxisAlignment:
          //                                   MainAxisAlignment.start,
          //                               crossAxisAlignment:
          //                                   CrossAxisAlignment.start,
          //                               children: [
          //                                 Text(
          //                                   data['accountNumber']
          //                                       .toString(),
          //                                   style: TextStyle(
          //                                     color: (index == 3)
          //                                         ? white
          //                                         : black,
          //                                   ),
          //                                 ),
          //                                 h5(),
          //                                 Text(
          //                                   data['accountName'],
          //                                   style: TextStyle(
          //                                     color: (index == 3)
          //                                         ? white
          //                                         : black,
          //                                   ),
          //                                 ),
          //                               ],
          //                             ),
          //                           )
          //                         ],
          //                       ),
          //                     ),
          //                     Align(
          //                       alignment: Alignment.bottomRight,
          //                       child: data['defaultBank'] == 1
          //                           ? Row(
          //                               mainAxisAlignment:
          //                                   MainAxisAlignment.end,
          //                               crossAxisAlignment:
          //                                   CrossAxisAlignment.end,
          //                               children: [
          //                                 Text('Default'),
          //                                 Padding(
          //                                   padding: const EdgeInsets.only(
          //                                       left: 2.0),
          //                                   child: Icon(
          //                                     Icons.verified,
          //                                     color: primaryColor,
          //                                     size: 16,
          //                                   ),
          //                                 )
          //                               ],
          //                             )
          //                           : Text(
          //                               'Not Defualt',
          //                               style: TextStyle(
          //                                   fontSize: 12,
          //                                   color: (index == 3)
          //                                       ? white
          //                                       : black),
          //                             ),
          //                     )
          //                   ],
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //         Center(
          //             child: CustomPopup(
          //           content: Column(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               GestureDetector(
          //                   onTap: () async {
          //                     goBack(context);
          //                     setState(() {
          //                       tappedIndex = index;
          //                       _isLoading = true;
          //                     });
          //                     var response =
          //                         await DbServices.setDefaultBank(
          //                             widget.user.id,
          //                             int.parse(data['id'].toString()));
          //                     setState(() {
          //                       _isLoading = false;
          //                     });
          //                     if (response['status'] == true) {
          //                       getBanks();
          //                       successSnackBar(
          //                           'Defualt Bank Successfully Set',
          //                           context);
          //                     } else {
          //                       showErrorSnackbar(
          //                           response['message'], context);
          //                     }
          //                   },
          //                   child: Text('Set DEFAULT')),
          //             ],
          //           ),
          //           child: Icon(
          //             Icons.more_vert,
          //             color: grey,
          //             size: 18,
          //           ),
          //         ))
          //       ],
          //     ),
          //   );
        });
  }
}
