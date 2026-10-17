import 'package:eafind/theme/app_palette.dart';
import 'package:clipboard/clipboard.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/providers/refresh_deal_provider.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/agents/bank_details.dart';
import 'package:eafind/screens/agents/user_account.dart';
import 'package:eafind/screens/notification_view.dart';
import 'package:eafind/screens/users/edit_profile.dart';
import 'package:eafind/screens/verification/agent_verification_screen.dart';
import 'package:eafind/upload_forms/house_upload.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/app_drawer.dart';

import 'package:eafind/widgets/deals_widget.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/db_services.dart';

class LeadsDashboard extends StatefulWidget {
  const LeadsDashboard({Key? key}) : super(key: key);

  @override
  State<LeadsDashboard> createState() => _LeadsDashboardState();
}

class _LeadsDashboardState extends State<LeadsDashboard> {
  var currentUser = FirebaseAuth.instance.currentUser;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  UserModel? onlineUser;
  int revenue = 0;
  int income = 0;
  int withdrawals = 0;
  int avaiable = 0;
  int pending = 0;
  var userDeals = [];
  bool isLoading = false;
  int currentAgentIndex = 0;
  bool hasTapped = false;
  getUser() async {
    setState(() {
      isLoading = true;
    });
    UserModel? fUser = Provider.of<UsermodelProvider>(context).userModel;
    if (!mounted) return;
    setState(() {
      onlineUser = fUser;
      isLoading = false;
    });
  }

  getDealsOnly() async {
    setState(() {
      isLoading = true;
    });
    try {
      var data = [];
      if (onlineUser!.userType == 'User') {
        data = await DbServices.getCustomerDeals(currentUser!.uid);
      } else {
        data = await DbServices.getAgentDeals(currentUser!.uid);
      }

      if (data.isNotEmpty) {
        setState(() {
          userDeals = data;
          isLoading = false;
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar('Oops unable to get revenue', context);
      // getRevenue();
    }
  }

  getRevenue() async {
    setState(() {
      isLoading = true;
    });
    try {
      var data = [];
      data = await DbServices.getAgentDeals(currentUser!.uid);

      if (data.isNotEmpty) {
        setState(() {
          userDeals = data;
          isLoading = false;
        });
        for (var items in data) {
          setState(() {
            revenue += int.parse(items['amount'].toString());
            income += int.parse(items['amount'].toString());
          });
        }
        setState(() {
          userDeals = data;
          isLoading = false;
        });
      }
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar('Oops unable to get revenue', context);
      // getRevenue();
    }
  }

  getBalance() async {
    setState(() {
      isLoading = true;
    });
    try {
      var data = await DbServices.getWalletBalance(onlineUser!.id);
      debugPrint('Revenue data is $data');
      setState(() {
        revenue = data['w_balance'];
        isLoading = false;
      });
    } catch (e) {}
  }

  Future<List<UserModel>> getUserLeads() async {
    setState(() {
      isLoading = true;
    });
    List<UserModel> data = [];
    try {
      data = await DbServices.getUserLeads(onlineUser!.uid);

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar('Oops unable to get leads', context);
      // getRevenue();
    }
    return data;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
    getBalance();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    bool shouldRefresh = Provider.of<RefreshDealProvider>(context).getState();
    if (shouldRefresh == true) {
      getDealsOnly();
      Provider.of<RefreshDealProvider>(context, listen: false)
          .changeStateWithoutNotif(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.palette.paper,
        drawer: onlineUser == null
            ? null
            : AppDrawer(
                sKey: _scaffoldKey,
                onlineUser: onlineUser!,
              ),
        appBar: AppBar(
          backgroundColor: transparent,
          automaticallyImplyLeading: false,
          elevation: 0.0,
          title: userProfile(),
          actions: [
            // GestureDetector(
            //   onTap: () {
            //     _scaffoldKey.currentState!.openDrawer();
            //   },
            //   child: Icon(
            //     Icons.settings,
            //     color: primaryColor,
            //     size: 18,
            //   ),
            // )

            GestureDetector(
              onTap: () {
                _scaffoldKey.currentState!.openDrawer();
              },
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: Icon(
                  Icons.admin_panel_settings,
                  color: grey,
                  size: 25,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: context.palette.primaryFill,
                shape: RoundedRectangleBorder(borderRadius: appRadius(50.0)),
                child: GestureDetector(
                  onTap: () => goTo(context, NotificationView(), false),
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Stack(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: white,
                        ),
                        Positioned(
                          right: 1.0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              borderRadius: appRadius(50.0),
                              color: Colors.red,
                            ),
                            child: Center(
                              child: Text(
                                '0',
                                style: TextStyle(color: white, fontSize: 8),
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: onlineUser == null
            ? Center(child: appLoader(50.0))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    Divider(),
                    Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: width(context),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: width(context) / 1.27,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage(
                                        imageRounte(name: 'bg_wallet3.jpg'),
                                      ),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        primaryColor,
                                        BlendMode.multiply,
                                      ),
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15.0),
                                      topRight: Radius.circular(15.0),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0, vertical: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          onlineUser!.userType == 'User'
                                              ? 'SPENT'
                                              : 'Revenue',
                                          style: TextStyle(
                                              color: white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '₦${NumberFormat().format(revenue)}  ',
                                          style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: white),
                                        ),
                                        Text(
                                          'Last Seen ${DateFormat.yMEd().format(currentUser!.metadata.lastSignInTime!)} ${DateFormat('hh:mm').format(currentUser!.metadata.lastSignInTime!)}',
                                          style: TextStyle(
                                              color: grey, fontSize: 13),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Container(
                                  height: 65,
                                  width: width(context) / 1.27,
                                  child: DottedBorder(
                                      child: Row(
                                    children: [
                                      pendingStats(),
                                      DottedBorder(
                                        child: Container(
                                          height: 65,
                                          width: 1,
                                        ),
                                      ),
                                      availableIncomeStat()
                                    ],
                                  )),
                                )
                              ],
                            ),
                            Container(
                              height: 200,
                              width: 30,
                              margin: EdgeInsets.only(left: 5),
                              child: Card(
                                color: context.palette.paperOp,
                                shape: RoundedRectangleBorder(
                                    borderRadius: appRadius(
                                  20.0,
                                )),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () =>
                                        goTo(context, BankDetails(), false),
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: context.palette.accent,
                                      size: 15,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Actions',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    SizedBox(
                      height: 80,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => goTo(context, BankDetails(), false),
                            child: Card(
                              child: Container(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.home,
                                      size: 20,
                                    ),
                                    h5(),
                                    Text('Bank Details')
                                  ],
                                ),
                              ),
                            ),
                          ),
                          w10(),
                          GestureDetector(
                            onTap: () => goTo(context, EditProfile(), false),
                            child: Card(
                              child: Container(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      size: 20,
                                    ),
                                    h5(),
                                    Text('Edit Profile')
                                  ],
                                ),
                              ),
                            ),
                          ),
                          w10(),
                          GestureDetector(
                            onTap: () => goTo(context, EditProfile(), false),
                            child: Card(
                              child: Container(
                                padding: EdgeInsets.all(10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people,
                                      size: 20,
                                    ),
                                    h5(),
                                    Text('My Referrals')
                                  ],
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Card(
                        color: context.palette.paperOp,
                        elevation: 20,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 10,
                          ),
                          child: ListView(
                            shrinkWrap: true,
                            primary: false,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Text(
                                        'My Agents',
                                        style: TextStyle(
                                            color: context.palette.accent, fontSize: 20),
                                      ),
                                    ),
                                    // Row(
                                    //   children: [
                                    //     Text(
                                    //       'See all',
                                    //       style: TextStyle(
                                    //         color: grey,
                                    //       ),
                                    //     ),
                                    //   ],
                                    // )
                                  ],
                                ),
                              ),
                              h10(),
                              FutureBuilder(
                                future: getUserLeads(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return gridLoader();
                                  }
                                  List<UserModel> leads =
                                      snapshot.data as List<UserModel>;
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    primary: false,
                                    itemCount: leads.length,
                                    itemBuilder: (context, index) {
                                      UserModel lead = leads[index];
                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 20,
                                                        backgroundImage: (lead
                                                                        .profileImage ==
                                                                    null ||
                                                                lead.profileImage
                                                                    .toString()
                                                                    .isEmpty)
                                                            ? AssetImage(
                                                                imageRounte(
                                                                    name:
                                                                        avatarImage),
                                                              )
                                                            : NetworkImage(
                                                                lead.profileImage,
                                                              ) as ImageProvider,
                                                      ),
                                                      w10(),
                                                      Text(
                                                        '${lead.firstName} ${lead.lastName}',
                                                        style: TextStyle(
                                                            color: context.palette.ink,
                                                            fontSize: 16),
                                                      ),
                                                    ],
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setTap(index);
                                                    },
                                                    child: (index ==
                                                                currentAgentIndex &&
                                                            hasTapped == true)
                                                        ? Icon(
                                                            Icons
                                                                .arrow_drop_up_rounded,
                                                            color: context.palette.accent,
                                                            size: 30,
                                                          )
                                                        : Icon(
                                                            Icons
                                                                .arrow_drop_down_circle,
                                                            color: context.palette.accent,
                                                            size: 30,
                                                          ),
                                                  )
                                                ],
                                              ),
                                              Divider(),
                                              (index == currentAgentIndex &&
                                                      hasTapped == true)
                                                  ? Column(
                                                      children: [
                                                        // Text(
                                                        //   'Joined: ${lead.createdAt != null ? DateFormat.yMEd().format(lead.createdAt.toDate()) : ''}',
                                                        //   style: TextStyle(
                                                        //     color: grey,
                                                        //     fontSize: 12,
                                                        //   ),
                                                        // ),
                                                        h10(),
                                                        agentStatsCard(lead),
                                                      ],
                                                    )
                                                  : SizedBox.fromSize(),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ));
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.surface,
        endDrawer: onlineUser == null
            ? null
            : AppDrawer(sKey: _scaffoldKey, onlineUser: onlineUser!),
        body: SafeArea(
          child: onlineUser == null
              ? Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: userProfile()),
                              _webIconButton(
                                Icons.notifications_none_rounded,
                                () => goTo(context, NotificationView(), false),
                              ),
                              const SizedBox(width: 10),
                              _webIconButton(
                                Icons.settings_outlined,
                                () =>
                                    _scaffoldKey.currentState?.openEndDrawer(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              SizedBox(
                                width: 240,
                                child: StatTile(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: onlineUser!.userType == 'User'
                                      ? 'Spent'
                                      : 'Revenue',
                                  value: '₦${NumberFormat().format(revenue)}',
                                ),
                              ),
                              SizedBox(
                                width: 240,
                                child: StatTile(
                                  icon: Icons.hourglass_empty_rounded,
                                  label: 'Pending',
                                  value: '₦${NumberFormat().format(income)}',
                                  accentColor: AppColors.secondary,
                                ),
                              ),
                              SizedBox(
                                width: 240,
                                child: StatTile(
                                  icon: Icons.savings_outlined,
                                  label: 'Available',
                                  value:
                                      '₦${NumberFormat().format(withdrawals)}',
                                  accentColor: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Actions',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _webActionTile(
                                  Icons.home_outlined,
                                  'Bank details',
                                  () => goTo(context, BankDetails(), false)),
                              _webActionTile(
                                  Icons.edit_outlined,
                                  'Edit profile',
                                  () => goTo(context, EditProfile(), false)),
                              _webActionTile(
                                  Icons.people_outline,
                                  'My referrals',
                                  () => goTo(context, EditProfile(), false)),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'My agents',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder(
                            future: getUserLeads(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.primary)),
                                );
                              }
                              List<UserModel> leads =
                                  snapshot.data as List<UserModel>;
                              if (leads.isEmpty) {
                                return const EmptyState(
                                  icon: Icons.people_outline,
                                  title: 'No agents yet',
                                );
                              }
                              return Column(
                                children: [
                                  for (var index = 0;
                                      index < leads.length;
                                      index++)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _webLeadCard(leads[index], index),
                                    ),
                                ],
                              );
                            },
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

  Widget _webLeadCard(UserModel lead, int index) {
    final expanded = index == currentAgentIndex && hasTapped == true;
    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: (lead.profileImage == null ||
                            lead.profileImage.toString().isEmpty)
                        ? AssetImage(imageRounte(name: avatarImage))
                        : NetworkImage(lead.profileImage) as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Text('${lead.firstName} ${lead.lastName}',
                      style: const TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ],
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => setTap(index),
                  child: Icon(
                    expanded
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_circle,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const Divider(),
            const SizedBox(height: 8),
            agentStatsCard(lead),
          ],
        ],
      ),
    );
  }

  Widget _webIconButton(IconData icon, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.card,
          ),
          child: Icon(icon, color: AppColors.textDark, size: 20),
        ),
      ),
    );
  }

  Widget _webActionTile(IconData icon, String label, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textDark, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  setTap(index) {
    setState(() {
      currentAgentIndex = index;
    });
    if (hasTapped == true && index == currentAgentIndex) {
      setState(() {
        hasTapped = false;
      });
    } else {
      hasTapped = true;
    }
  }

  Widget agentStatsCard(UserModel lead) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    'Followers',
                    style: TextStyle(color: grey),
                  ),
                  FutureBuilder(
                    future: DbServices.getFollowersCount(lead.id),
                    builder: (ctx, AsyncSnapshot<int> snapshot) {
                      if (!snapshot.hasData) {
                        return appLoader(15.0);
                      }
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          snapshot.data.toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: context.palette.ink),
                        ),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(width: 15),
              dividerH(),
              const SizedBox(width: 15),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Deals',
                    style: TextStyle(color: grey),
                  ),
                  FutureBuilder(
                    future: DbServices.getAgentDeals(lead.id),
                    builder: (ctx, AsyncSnapshot<List<dynamic>> snapshot) {
                      if (!snapshot.hasData) {
                        return appLoader(15.0);
                      }
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          snapshot.data!.length.toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: context.palette.ink),
                        ),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(width: 15),
              dividerH(),
              const SizedBox(width: 15),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Success Rate',
                    style: TextStyle(color: grey),
                  ),
                  FutureBuilder(
                    future: DbServices.getAgentDeals(lead.id),
                    builder: (ctx, AsyncSnapshot<List<dynamic>> snapshot) {
                      if (!snapshot.hasData) {
                        return appLoader(15.0);
                      }
                      int successRate = getSuccessRate(snapshot.data!);
                      return Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          '${successRate}%',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: context.palette.ink),
                        ),
                      );
                    },
                  )
                ],
              ),
              const SizedBox(width: 15),
              dividerH(),
            ]),
      ),
    );
  }

  Widget pendingStats() {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.monetization_on,
                color: grey,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending',
                      style: TextStyle(color: context.palette.ink),
                    ),
                    Text(
                      '₦${NumberFormat().format(income)}',
                      style: TextStyle(color: context.palette.ink),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget incomeStats() {
    return SizedBox(
      width: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                Icons.monetization_on,
                color: grey,
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      onlineUser!.userType == 'User' ? 'Bonus' : 'Income',
                      style: TextStyle(color: context.palette.ink),
                    ),
                    Text(
                      '₦${NumberFormat().format(income)}',
                      style: TextStyle(color: context.palette.ink),
                    )
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget availableIncomeStat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(
              Icons.monetization_on,
              color: grey,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available',
                    style: TextStyle(color: context.palette.ink),
                  ),
                  Text(
                    '₦${NumberFormat().format(withdrawals)}',
                    style: TextStyle(color: context.palette.ink),
                  )
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  Widget userProfile() {
    return onlineUser == null
        ? LoadingAnimationWidget.fallingDot(color: white, size: 25)
        : Row(
            children: [
              Container(
                height: 50,
                width: 50,
                padding: EdgeInsets.all(3.0),
                decoration: BoxDecoration(
                    color: context.palette.paper,
                    border: Border.all(
                      width: 1.0,
                      color: black,
                    ),
                    borderRadius: appRadius(50.0)),
                child: (onlineUser!.profileImage == null ||
                        onlineUser!.profileImage.toString().isEmpty)
                    ? ClipOval(
                        child: Image.asset(
                          imageRounte(name: avatarImage),
                          fit: BoxFit.cover,
                        ),
                      )
                    : ClipOval(
                        child: Image.network(
                        onlineUser!.profileImage,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Hi, ${onlineUser!.firstName}",
                      style: TextStyle(fontSize: 18, color: context.palette.accent),
                    ),
                    onlineUser!.userType == 'Lead'
                        ? GestureDetector(
                            onTap: () => FlutterClipboard.copy(onlineUser!.uid)
                                .then((value) => successSnackBar(
                                    'User ID copied to clipboard', context)),
                            child: Container(
                                decoration: BoxDecoration(
                                  color: context.palette.primaryFill.withOpacity(.1),
                                  borderRadius: appRadius(10.0),
                                ),
                                padding: EdgeInsets.all(2.0),
                                child: Row(
                                  children: [
                                    w5(),
                                    Text(
                                      'UID: ${onlineUser!.uid}',
                                      style: tStyle(
                                          color: context.palette.accent, size: 12.0),
                                    ),
                                    w5(),
                                    Icon(
                                      Icons.copy,
                                      size: 20,
                                      color: context.palette.accent,
                                    )
                                  ],
                                )),
                          )
                        : GestureDetector(
                            onTap: () => goTo(
                                context, const AgentVerificationScreen(), false),
                            child: Container(
                                decoration: BoxDecoration(
                                  color: context.palette.primaryFill.withOpacity(.1),
                                  borderRadius: appRadius(10.0),
                                ),
                                padding: EdgeInsets.all(2.0),
                                child: Row(
                                  children: [
                                    w5(),
                                    Text(
                                      'verify account',
                                      style: tStyle(
                                          color: context.palette.accent, size: 12.0),
                                    ),
                                    w5(),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: context.palette.accent,
                                    )
                                  ],
                                )),
                          )
                  ],
                ),
              )
            ],
          );
  }
}
