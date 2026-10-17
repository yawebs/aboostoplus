import 'package:eafind/theme/app_palette.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/location_provider.dart';
import 'package:eafind/providers/refresh_deal_provider.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/screens/agents/user_account.dart';
import 'package:eafind/screens/marketplace/messages_screen.dart';
import 'package:eafind/screens/users/user_dashboard.dart';
import 'package:eafind/services/providers/data_provider.dart';
import 'package:eafind/tab_screens/hall_screen.dart';
import 'package:eafind/widgets/easy_access_widget.dart';
import 'package:eafind/widgets/house_profile_widget.dart';
import 'package:eafind/widgets/service_apartment_card.dart';
import 'package:eafind/widgets/home_services_section.dart';
import 'package:eafind/widgets/explore_area_banner.dart';
import 'package:eafind/tab_screens/lands_screen.dart';
import 'package:eafind/tab_screens/offices_screen.dart';
import 'package:eafind/tab_screens/properties_sales.dart';
import 'package:eafind/tab_screens/service_apartments_screen.dart';
import 'package:eafind/widgets/filter_widget.dart';
import 'package:eafind/widgets/recomemded_widget.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/property_model.dart';
import '../utility/states_data.dart';
import 'package:provider/provider.dart';

import 'house_details_screen.dart';
import 'marketplace/upload_product.dart';
import '../services/providers/theme_mode_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var currentUser = FirebaseAuth.instance.currentUser;
  ScrollController quickAccessController = ScrollController();
  ScrollController _controller = ScrollController();
  String selecteQuickAccess = 'Houses';
  int currentIndex = 0;
  var iconSized = 20.0;
  bool isLoading = false;
  UserModel? onlineUser;
  List<String> states = [];
  bool isLoadingVertical = false;
  bool isLoadingHorizontal = false;
  List<PropertyModel> allProperties = [];
  List<PropertyModel> featuredProperties = [];
  String selectedState = 'State';
  bool changingSettings = false;
  bool isBadNetwork = false;
  // Featured-row dropdown choice; the Recommended feed below always stays
  // on houses (_houseFeedType) regardless of it.
  String selectedPropertyType = 'Houses';
  static const String _houseFeedType = 'Houses';
  List<String> communities = [
    'Rumuomasi',
    'Elekahia',
    'Rumuoigbo',
    'Garrison',
    'Trans Amadi'
  ];
  int increament = 10;
  // Service Apartments carousel: cards fill 84% of the width so the next
  // one peeks in, hinting that it swipes.
  final PageController _stayController = PageController(viewportFraction: 0.84);
  int _stayPage = 0;
  bool firstLoading = true;
  DataProvider? _dataProvider;

  getStates() async {
    List<String> allStates = [];
    for (var state in allStatesAndCities) {
      allStates.add(state.state);
    }
    setState(() {
      states = allStates;
    });
  }

  List<PropertyModel> properties = [];
  List<String> quickAccessItems = [
    'Houses',
    'Offices',
    'Halls',
    'Lands',
    'Properties',
    'Service Apartments'
  ];
  List<PropertyModel> serviceApartments = [];
  Map userLocation = {};

  filterDialog() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        isDismissible: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
        ),
        builder: (ctx) {
          return const FilterWidget();
        });
  }

  getUser() async {
    UserModel? user =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    if (user != null) {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();

      if (!mounted) return;
      setState(() {
        onlineUser = user;
      });
      if (sharedPreferences.getStringList('userFilter') != null) {
        List<String> userFilterSettings =
            sharedPreferences.getStringList('userFilter')!;
        setState(() {
          selectedState = userFilterSettings[0];
        });
      }
    }
  }

  easyAccessIntroDialog(ctx) async {
    await Future.delayed(Duration(seconds: 1));
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (!mounted) return;

    bool showSheet = MediaQuery.of(context).viewInsets.bottom == 0.0;
    // if (!showSheet) return;
    debugPrint(sharedPreferences.getStringList('userFilter').toString());
    if (sharedPreferences.getStringList('userFilter') != null &&
        changingSettings == false) return;

    showModalBottomSheet(
        isScrollControlled: true,
        isDismissible: false,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: EasyAccessWidget(),
          );
        },
        context: ctx);
  }

  // Delegates to DataProvider, which only hits the network the first time,
  // when the property type changes, or when forceRefresh is passed (used
  // for pagination, pull-to-refresh and explicit filter changes below) -
  // every other call (e.g. HomeScreen being remounted on tab switch) just
  // reuses the already-cached list.
  Future<dynamic> getAllProperties(selectedPropertyType,
      {bool forceRefresh = false}) async {
    setState(() {
      isLoadingVertical = true;
    });
    if (firstLoading == true) {
      setState(() {
        isLoading = true;
      });
    }
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.fetchProperties(
        context,
        propertyType: selectedPropertyType,
        limit: increament,
        forceRefresh: forceRefresh,
      );
      // The widget (or its context) may have gone away while that request
      // was in flight - e.g. navigating away mid-scroll-triggered fetch.
      if (!mounted) return null;

      allProperties = dataProvider.properties;

      setState(() {
        isLoadingVertical = false;
        increament = increament + increament;
        isLoading = false;
        firstLoading = false;
      });

      return allProperties;
    } on DioException catch (e) {
      debugPrint('Something went wrong fetching post ${e.message}');
    } on SocketException catch (_) {
      setState(() {
        isBadNetwork = true;
      });
    } catch (e) {
      debugPrint('Something went wrong fetching post on Catch ${e.toString()}');
      setState(() {
        isBadNetwork = true;
      });
    }
  }

  Future<dynamic> getFeatured(selectedPropertyType,
      {bool forceRefresh = false}) async {
    setState(() {
      isLoadingHorizontal = true;
    });
    try {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      await dataProvider.fetchFeaturedProperties(
        propertyType: 'Duplex',
        limit: increament,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return null;

      featuredProperties = dataProvider.featuredProperties;

      setState(() {
        isLoadingHorizontal = false;
      });

      return featuredProperties;
    } on DioException catch (e) {
      debugPrint(
          'Something went wrong fetching post Featured Properties ${e.message}');
    } on SocketException catch (_) {
      setState(() {
        isBadNetwork = true;
      });
    } catch (e) {
      setState(() {
        isBadNetwork = true;
      });
    }
  }

  Future<List<PropertyModel>> getP(keyword) async {
    await Future.delayed(Duration(seconds: 2));
    if (!mounted) return [];
    List<PropertyModel> propertiesR = [];
    var data =
        allProperties.where((element) => element.category == keyword).toList();
    if (data.isNotEmpty) {
      propertiesR = data;
      setState(() {
        featuredProperties = data;
      });
    }
    return propertiesR;
  }

  Future<List<PropertyModel>> getAllP() async {
    return allProperties;
  }

  @override
  void initState() {
    super.initState();
    getUser();
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    _dataProvider = dataProvider;
    // Picks up data already cached from the app-launch fetch (or a
    // previous mount of this screen) instantly, before triggering the
    // (no-op if already cached) fetch calls below.
    allProperties = dataProvider.properties;
    featuredProperties = dataProvider.featuredProperties;
    serviceApartments = dataProvider.serviceApartments;
    firstLoading = !dataProvider.hasFetchedProperties;
    dataProvider.addListener(_onDataProviderChanged);
    getAllProperties(_houseFeedType);
    getFeatured('Duplex');
    dataProvider.fetchServiceApartments();
  }

  void _onDataProviderChanged() {
    if (!mounted) return;
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    setState(() {
      allProperties = dataProvider.properties;
      featuredProperties = dataProvider.featuredProperties;
      serviceApartments = dataProvider.serviceApartments;
    });
  }

  @override
  void dispose() {
    // Must use the DataProvider captured in initState, not a fresh
    // Provider.of(context) lookup here: by the time dispose() runs, this
    // element has already been deactivated, so looking up an inherited
    // widget on `context` throws "Looking up a deactivated widget's
    // ancestor is unsafe."
    _dataProvider?.removeListener(_onDataProviderChanged);
    quickAccessController.dispose();
    _controller.dispose();
    _stayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    UserModel? onlineUser = context.read<UsermodelProvider>().getUserModel();
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: context.palette.paper,
        appBar: AppBar(
          backgroundColor: black,
          automaticallyImplyLeading: false,
          elevation: 1.0,
          toolbarHeight: 100,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          title: Column(
            children: [
              const SizedBox(height: 10),
              onlineUserWidget(userLocation),
            ],
          ),
          actions: [
            GestureDetector(
              onTap: () => context.read<ThemeModeProvider>().toggle(context),
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: const _ThemeToggleBtn(),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (onlineUser == null) {
                  showToast("Please Login First");
                  goTo(
                      context,
                      LoginScreen(
                        fromNav: false,
                      ),
                      false);
                } else {
                  goTo(
                      context,
                      MessagesScreen(
                          currentUserId: onlineUser.id,
                          currentUserName: onlineUser.firstName,
                          currentUserImage: onlineUser.profileImage),
                      false);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: _IconBtn(
                  icon: Icons.message,
                  badge: '4',
                ),
              ),
            ),
            GestureDetector(
              onTap: () => showSearchSheet(context),
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: _IconBtn(
                  icon: Icons.search,
                ),
              ),
            ),
          ],
        ),
        body: LazyLoadScrollView(
          onEndOfPage: () async {
            setState(() {
              isLoadingVertical = true;
            });
            await getAllProperties(_houseFeedType, forceRefresh: true);
            if (!mounted) return;
            setState(() {
              isLoadingVertical = false;
            });
          },
          isLoading: isLoadingVertical,
          child: RefreshIndicator(
            color: context.palette.accent,
            backgroundColor: context.palette.paper,
            strokeWidth: 2.4,
            onRefresh: () => Future.wait([
              getAllProperties(_houseFeedType, forceRefresh: true),
              context
                  .read<DataProvider>()
                  .fetchServiceApartments(forceRefresh: true),
              if (_propertyTypeCategories[selectedPropertyType] != null)
                context.read<DataProvider>().fetchFeaturedByCategory(
                    _propertyTypeCategories[selectedPropertyType]!,
                    forceRefresh: true),
            ]),
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Scrollbar(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    h10(),
                    selecteQuickAccess == 'Houses'
                        ? isLoading
                            ? listLoader()
                            : ListView(
                                primary: false,
                                shrinkWrap: true,
                                children: [
                                  buildHouses(
                                    title: 'Featured',
                                    pDatas: _featuredForSelectedType(),
                                  ),
                                  const SizedBox(height: 8),
                                  // Standalone AI area insights entry point.
                                  const ExploreAreaBanner(),
                                  // Section break: spacing instead of a hard
                                  // rule line — a flat Divider() reads as a
                                  // stray line on a white page; whitespace
                                  // plus a heading does the same separating
                                  // job more gently.
                                  const SizedBox(height: 20),
                                  _serviceApartmentsSection(),
                                  const SizedBox(height: 24),
                                  // Movers, cleaners, handymen - book from home.
                                  const HomeServicesSection(),
                                  const SizedBox(height: 20),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5.0),
                                    child: _sectionTitle(
                                        Icons.thumb_up_alt_rounded,
                                        'Recommended '),
                                  ),
                                  const SizedBox(height: 10),
                                  RecommendedWidget(
                                    properties: allProperties,
                                  ),
                                ],
                              )
                        : selecteQuickAccess == 'Offices'
                            ? const OfficesScreen()
                            : selecteQuickAccess == 'Halls'
                                ? const HallScreen()
                                : selecteQuickAccess == 'Lands'
                                    ? const LandScreen()
                                    : const PropertySalesScreen()
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    UserModel? onlineUser = context.read<UsermodelProvider>().getUserModel();
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () =>
                getAllProperties(_houseFeedType, forceRefresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _webHeaderRow(context, onlineUser),
                    const SizedBox(height: 24),
                    _webQuickAccessRow(),
                    const SizedBox(height: 28),
                    if (selecteQuickAccess == 'Houses') ...[
                      if (isLoadingHorizontal ||
                          featuredProperties.isNotEmpty) ...[
                        const Text(
                          'Featured',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        WebPropertyGrid(
                          properties: featuredProperties,
                          onTap: (p) => goTo(
                              context, HouseDetailsScreen(property: p), false),
                        ),
                        const SizedBox(height: 32),
                      ],
                      const Text(
                        'Recommended for you',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isLoading)
                        Padding(
                          padding: const EdgeInsets.all(48),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.primary)),
                        )
                      else if (allProperties.isEmpty)
                        const EmptyState(
                          icon: Icons.home_work_outlined,
                          title: 'No properties yet',
                          message: 'Check back soon for new listings',
                        )
                      else
                        WebPropertyGrid(
                          properties: allProperties,
                          onTap: (p) => goTo(
                              context, HouseDetailsScreen(property: p), false),
                        ),
                    ] else if (selecteQuickAccess == 'Offices')
                      const OfficesScreen()
                    else if (selecteQuickAccess == 'Halls')
                      const HallScreen()
                    else if (selecteQuickAccess == 'Lands')
                      const LandScreen()
                    else if (selecteQuickAccess == 'Service Apartments')
                      const ServiceApartmentsScreen()
                    else
                      const PropertySalesScreen(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webHeaderRow(BuildContext context, UserModel? onlineUser) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                onlineUser == null
                    ? 'Hi, Anonymous'
                    : 'Hi, ${onlineUser.firstName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(
                    userLocation.isEmpty
                        ? 'Set your location'
                        : userLocation['address'],
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textGrey),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          width: 320,
          child: TextField(
            readOnly: true,
            onTap: () => showSearchSheet(context),
            decoration: const InputDecoration(
              hintText: 'Search properties...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _webIconButton(
          icon: Icons.tune_rounded,
          onTap: filterDialog,
        ),
        const SizedBox(width: 10),
        _webIconButton(
          icon: Icons.add,
          onTap: () => goTo(context, UploadProduct(), false),
        ),
        const SizedBox(width: 10),
        _webIconButton(
          icon: Icons.mail_outline_rounded,
          onTap: () {
            if (onlineUser == null) {
              showToast('Please Login First');
              goTo(context, LoginScreen(fromNav: false), false);
            } else {
              goTo(
                  context,
                  MessagesScreen(
                      currentUserId: onlineUser.id,
                      currentUserName: onlineUser.firstName,
                      currentUserImage: onlineUser.profileImage),
                  false);
            }
          },
        ),
      ],
    );
  }

  Widget _webIconButton({required IconData icon, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textDark, size: 20),
        ),
      ),
    );
  }

  Widget _webQuickAccessRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: quickAccessItems.map((item) {
        final selected = selecteQuickAccess == item;
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setState(() => selecteQuickAccess = item);
              if (item == 'Houses') getAllProperties(_houseFeedType);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Text(
                item,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: context.palette.primaryFill.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: context.palette.accent),
        ),
        const SizedBox(width: 8),
        Text(title, style: tHeading.copyWith(color: context.palette.accent)),
      ],
    );
  }

  void _openAllServiceApartments() {
    goTo(
      context,
      Scaffold(
        backgroundColor: context.palette.paper,
        appBar: AppBar(
          backgroundColor: context.palette.paper,
          elevation: 0,
          iconTheme: IconThemeData(color: context.palette.ink),
          title: Text(
            'Service Apartments',
            style: TextStyle(
              color: context.palette.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: const SingleChildScrollView(child: ServiceApartmentsScreen()),
      ),
      false,
    );
  }

  // "Stays" showcase: a night-sky panel (stays are priced per night) with a
  // snapping card carousel and page dots.
  Widget _serviceApartmentsSection() {
    final palette = context.palette;
    final hasFetched = context.read<DataProvider>().hasFetchedServiceApartments;
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.55)!;
    const gold = Color(0xFFF5C76A);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [deep, palette.primaryFill],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // A few faint stars in the panel's sky.
          Positioned.fill(
            child: CustomPaint(painter: _NightSkyPainter()),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.nights_stay_rounded,
                          color: gold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Service Apartments',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hotel comfort, home privacy · priced per night',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (serviceApartments.isNotEmpty)
                      TextButton(
                        onPressed: _openAllServiceApartments,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          shape: const StadiumBorder(),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See all ${serviceApartments.length}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right_rounded, size: 16),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!hasFetched)
                const SizedBox(
                  height: 160,
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                )
              else if (serviceApartments.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
                  child: Row(
                    children: [
                      Icon(Icons.hotel_rounded,
                          color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No service apartments yet - check back soon.',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85)),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                SizedBox(
                  height: 372,
                  child: PageView.builder(
                    controller: _stayController,
                    padEnds: false,
                    itemCount: serviceApartments.length,
                    onPageChanged: (i) => setState(() => _stayPage = i),
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(left: index == 0 ? 10 : 0),
                      child: ServiceApartmentCard(
                          property: serviceApartments[index]),
                    ),
                  ),
                ),
                // Page dots (capped so long lists don't overflow).
                if (serviceApartments.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0;
                            i < serviceApartments.length.clamp(0, 8);
                            i++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _stayPage.clamp(0, 7) ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _stayPage.clamp(0, 7)
                                  ? gold
                                  : Colors.white.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Pages the Duplex featured feed when the row is scrolled to its end.
  // Other categories load in one go (see _selectFeaturedType).
  Future<void> _loadMoreFeatured() async {
    if (selectedPropertyType != 'Houses') return;
    setState(() => isLoadingHorizontal = true);
    await getFeatured('Duplex', forceRefresh: true);
    if (!mounted) return;
    setState(() => isLoadingHorizontal = false);
  }

  // Was a ListView with key: UniqueKey(), so *every* rebuild of the home
  // screen (data arriving, loading flags, ...) threw the row away - which
  // cancelled any swipe in progress and snapped it back to the start.
  // Now a plain Column, with a stable PageStorageKey on the horizontal
  // list so its scroll position survives rebuilds.
  Widget buildHouses({
    title,
    IconData icon = Icons.star_rounded,
    required List<PropertyModel> pDatas,
  }) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(icon, title),
                      Padding(
                        padding: const EdgeInsets.only(left: 36, top: 2),
                        child: Text(
                          pDatas.isEmpty
                              ? 'Hand-picked listings'
                              : '${pDatas.length} hand-picked listings',
                          style: TextStyle(
                              fontSize: 12, color: context.palette.inkSoft),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              propertyTypePopup(),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 280,
            child: pDatas.isEmpty && _isFeaturedTypeLoading()
                ? Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.palette.accent,
                    ),
                  )
                : pDatas.isEmpty
                    ? Center(
                        child: Text(
                          'No featured ${selectedPropertyType.toLowerCase()} yet',
                          style: TextStyle(color: context.palette.inkSoft),
                        ),
                      )
                    // Swallow this row's scroll notifications once handled,
                    // so swiping sideways doesn't also trigger the page's
                    // vertical "load more" above.
                    : NotificationListener<ScrollNotification>(
                        onNotification: (_) => true,
                        child: LazyLoadScrollView(
                          scrollDirection: Axis.horizontal,
                          isLoading: isLoadingHorizontal,
                          onEndOfPage: _loadMoreFeatured,
                          child: ListView.builder(
                            key: PageStorageKey(
                                'featured-row-$selectedPropertyType'),
                            scrollDirection: Axis.horizontal,
                            primary: false,
                            controller: _controller,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            physics: const BouncingScrollPhysics(),
                            itemCount: pDatas.length,
                            itemBuilder: (context, index) => Align(
                              alignment: Alignment.topCenter,
                              child:
                                  HouseWidgetProfile(property: pDatas[index]),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Each property type gets its own icon + one-line hint, so the picker
  // reads as a set of categories rather than a bare text list.
  static const Map<String, IconData> _propertyTypeIcons = {
    'Houses': Icons.home_rounded,
    'Lands': Icons.landscape_rounded,
    'Shops': Icons.storefront_rounded,
    'Event Halls': Icons.celebration_rounded,
    'Properties': Icons.location_city_rounded,
  };
  static const Map<String, String> _propertyTypeHints = {
    'Houses': 'Duplexes, flats & bungalows',
    'Lands': 'Plots & acres',
    'Shops': 'Stores & retail spaces',
    'Event Halls': 'Venues for any occasion',
    'Properties': 'Buildings for sale',
  };

  // Dropdown label -> the `category` value the upload forms store. Houses
  // isn't here: it keeps using the Duplex featured feed.
  static const Map<String, String> _propertyTypeCategories = {
    'Lands': 'Land',
    'Shops': 'Office Space',
    'Event Halls': 'Hall',
    'Properties': 'Property Sales',
  };

  List<PropertyModel> _featuredForSelectedType() {
    final category = _propertyTypeCategories[selectedPropertyType];
    if (category == null) return featuredProperties;
    return context.read<DataProvider>().featuredByCategory[category] ?? [];
  }

  bool _isFeaturedTypeLoading() {
    final category = _propertyTypeCategories[selectedPropertyType];
    return category != null &&
        context.read<DataProvider>().isFeaturedCategoryLoading(category);
  }

  void _selectFeaturedType(String type, {bool forceRefresh = false}) {
    setState(() => selectedPropertyType = type);
    final category = _propertyTypeCategories[type];
    if (category == null) return;
    context
        .read<DataProvider>()
        .fetchFeaturedByCategory(category, forceRefresh: forceRefresh);
  }

  IconData _propertyTypeIcon(String type) =>
      _propertyTypeIcons[type] ?? Icons.category_rounded;

  // Compact pill trigger: the current type's icon in a filled badge, its
  // label, and a chevron — tapping it opens the category sheet below.
  Widget propertyTypePopup() {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: Material(
        color: palette.primaryFill.withOpacity(0.10),
        shape: StadiumBorder(
          side: BorderSide(color: palette.accent.withOpacity(0.35)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _showPropertyTypeSheet,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: palette.primaryFill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _propertyTypeIcon(selectedPropertyType),
                    size: 13,
                    color: white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  selectedPropertyType,
                  style: TextStyle(
                    color: palette.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: palette.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPropertyTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final palette = ctx.palette;
        return Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16, 16 + MediaQuery.of(ctx).padding.bottom),
          decoration: BoxDecoration(
            color: palette.paper,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.inkMuted.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'What are you looking for?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pick a category to browse',
                style: TextStyle(fontSize: 13, color: palette.inkSoft),
              ),
              const SizedBox(height: 16),
              ...propertyTypes.map((type) => _propertyTypeTile(ctx, type)),
            ],
          ),
        );
      },
    );
  }

  Widget _propertyTypeTile(BuildContext ctx, String type) {
    final palette = ctx.palette;
    final selected = type == selectedPropertyType;
    final hint = _propertyTypeHints[type] ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(ctx);
          if (!selected) _selectFeaturedType(type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                selected ? palette.primaryFill.withOpacity(0.10) : palette.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? palette.accent : palette.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? palette.primaryFill
                      : palette.primaryFill.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _propertyTypeIcon(type),
                  color: selected ? white : palette.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: palette.ink,
                      ),
                    ),
                    if (hint.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        hint,
                        style: TextStyle(fontSize: 12, color: palette.inkSoft),
                      ),
                    ],
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: selected
                    ? Icon(Icons.check_circle_rounded,
                        key: const ValueKey('on'), color: palette.accent)
                    : Icon(Icons.chevron_right_rounded,
                        key: const ValueKey('off'), color: palette.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget onlineUserWidget(Map userLocation) {
    List<String> newItems = [
      userLocation.isEmpty ? 'Set Location' : userLocation['address'],
      userLocation.isNotEmpty ? 'Change' : ''
    ];
    String selectedItem =
        userLocation.isEmpty ? 'Set Location' : userLocation['address'];
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      onlineUser == null
          ? GestureDetector(
              onTap: (() => goTo(
                  context,
                  const LoginScreen(
                    fromNav: true,
                  ),
                  false)),
              child: Row(
                children: [
                  Container(
                      width: 40,
                      height: 40,
                      child: ClipOval(
                          child: Image.asset(
                        imageRounte(name: avatarImage),
                        fit: BoxFit.cover,
                        color: white,
                      ))),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Hi,Anonymus',
                      style: TextStyle(color: white, fontSize: 14),
                    ),
                  )
                ],
              ),
            )
          : GestureDetector(
              onTap: (() => goTo(
                  context,
                  onlineUser!.userType == 'User'
                      ? const UserDashboard()
                      : UserAccount(
                          userId: onlineUser!.id,
                        ),
                  false)),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Fixed sizing: the ring container and inner image
                      // now agree with each other (48 outer, 3px padding
                      // = 42 inner) instead of the old 45/10/30 mix that
                      // forced the photo to overflow its own padding.
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            color: context.palette.paper,
                            borderRadius: appRadius(50.0)),
                        child: onlineUser!.profileImage == null
                            ? ClipOval(
                                child: Image.asset(
                                imageRounte(name: avatarImage),
                                fit: BoxFit.cover,
                                color: primaryColor,
                              ))
                            : onlineUser!.profileImage.toString().isEmpty
                                ? ClipOval(
                                    child: Image.asset(
                                    imageRounte(name: avatarImage),
                                    fit: BoxFit.cover,
                                    color: primaryColor,
                                  ))
                                : ClipOval(
                                    child: Image.network(
                                    onlineUser!.profileImage,
                                    fit: BoxFit.cover,
                                  )),
                      ),
                      // Was Icons.menu_rounded — a hamburger icon sitting on
                      // a profile photo reads as a stray debug icon rather
                      // than a real status indicator. Swapped for a small
                      // chevron, since tapping the avatar opens the profile
                      // screen (i.e. "more options"), which is what a
                      // chevron communicates.
                      Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(3),
                            decoration: BoxDecoration(
                                color: context.palette.primaryFill,
                                shape: BoxShape.circle,
                                border: Border.all(color: black, width: 1.5)),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              color: white,
                              size: 10,
                            ),
                          ))
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Hi,${onlineUser!.firstName}',
                      style: TextStyle(color: white, fontSize: 14),
                    ),
                  )
                ],
              ),
            ),
      states.isEmpty
          ? SizedBox.shrink()
          : Expanded(
              child: Align(
                alignment: Alignment.topRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: context.palette.accent,
                      size: 12,
                    ),
                    Container(
                      width: 120,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton2(
                          isExpanded: true,
                          hint: Row(
                            children: [
                              Icon(
                                Icons.list,
                                size: 16,
                                color: white,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Expanded(
                                child: Text(
                                  selectedState,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          items: states
                              .map((item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: context.palette.ink,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedState = value as String;
                              changingSettings = true;
                            });
                            easyAccessIntroDialog(context);
                          },
                          iconStyleData: IconStyleData(
                            icon: Icon(
                              Icons.arrow_drop_down,
                              size: 25,
                              color: white,
                            ),
                            iconSize: 14,
                            iconEnabledColor: white,
                            iconDisabledColor: Colors.grey,
                          ),
                          dropdownStyleData: DropdownStyleData(
                            maxHeight: 400,
                            width: 150,
                            padding: null,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: context.palette.paper,
                            ),
                            elevation: 8,
                            offset: const Offset(-20, 0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
    ]);
  }

  Widget quickAccessWidget() {
    return Container(
      height: 40,
      child: ListView.builder(
          shrinkWrap: true,
          primary: false,
          controller: quickAccessController,
          scrollDirection: Axis.horizontal,
          itemCount: quickAccessItems.length,
          itemBuilder: ((context, index) {
            return GestureDetector(
              onTap: (() {
                setState(() {
                  selecteQuickAccess = quickAccessItems[index];
                  currentIndex = index;
                });
              }),
              child: Card(
                elevation:
                    (selecteQuickAccess == quickAccessItems[index]) ? 10 : 0,
                color: (selecteQuickAccess == quickAccessItems[index])
                    ? context.palette.primaryFill
                    : transparent,
                shape: RoundedRectangleBorder(borderRadius: appRadius(10.0)),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(3.0),
                      child: quickIcons(currentIndex, 15.0)[index],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: Text(
                        quickAccessItems[index],
                        style: TextStyle(
                            fontSize: 15,
                            color:
                                (selecteQuickAccess == quickAccessItems[index])
                                    ? white
                                    : context.palette.ink),
                      ),
                    )
                  ],
                ),
              ),
            );
          })),
    );
  }

  Widget searchWidget() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Transform.translate(
        offset: const Offset(0, -10),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: GestureDetector(
                  onTap: () => showSearchSheet(context),
                  child: Container(
                    decoration: BoxDecoration(
                        border:
                            Border.all(color: context.palette.paper, width: 1),
                        borderRadius: appRadius(15.0)),
                    child: TextFormField(
                      enabled: false,
                      onSaved: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Propertice..',
                        isDense: true,
                        hintStyle: TextStyle(
                          color: white,
                          fontSize: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: context.palette.paper,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: context.palette.accent,
                            width: 1.5,
                          ),
                        ),
                        prefixIcon: Container(
                          padding: EdgeInsets.only(top: 15),
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: white,
                          ),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () {},
                          child: Container(
                            decoration: BoxDecoration(
                              color: context.palette.paper,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.search,
                              color: context.palette.accent,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: (() => filterDialog()),
              child: Container(
                child: SvgPicture.asset(
                  'assets/images/filter.svg',
                  color: white,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget noticeWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Aboostoplus',
            style: tHeading.copyWith(color: context.palette.accent),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            'Houses,Lands,Properties etc',
            style: th6,
          ),
        ),
      ],
    );
  }
}

// Faint scattered stars for the Service Apartments "night" panel.
class _NightSkyPainter extends CustomPainter {
  static const List<List<double>> _stars = [
    [0.08, 0.06, 1.4],
    [0.32, 0.03, 1.0],
    [0.58, 0.08, 1.6],
    [0.74, 0.04, 1.1],
    [0.94, 0.10, 1.3],
    [0.46, 0.14, 0.9],
    [0.86, 0.20, 1.0],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final s in _stars) {
      canvas.drawCircle(
          Offset(size.width * s[0], size.height * s[1]), s[2], paint);
    }
    // Soft moon-glow in the top-right corner.
    canvas.drawCircle(
      Offset(size.width * 0.95, 0),
      90,
      Paint()
        ..color = const Color(0xFFF5C76A).withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;

  const _IconBtn({required this.icon, this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.palette.card,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: context.palette.ink),
        ),
        if (badge != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// The light/dark switch in the home app bar: a compact pill with a
// purple-to-gold track and a sliding knob (moon on the left in light mode,
// sun on the right in dark mode). A real switch shape, so it reads as a
// control rather than another round icon button.
class _ThemeToggleBtn extends StatelessWidget {
  const _ThemeToggleBtn();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const purple = Color(0xFF6A3D7A);
    const gold = Color(0xFFE8A93B);
    const duration = Duration(milliseconds: 280);
    return Container(
      width: 58,
      height: 32,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [purple, gold]),
        border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOutCubic,
        alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: duration,
            child: Icon(
              isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
              key: ValueKey(isDark),
              size: 15,
              color: isDark ? const Color(0xFFE08A00) : purple,
            ),
          ),
        ),
      ),
    );
  }
}
