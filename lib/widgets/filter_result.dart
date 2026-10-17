import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/screens/house_details_screen.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/recomemded_widget.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/property_model.dart';
import '../providers/navigation_provider.dart';

class FilterResultScreen extends StatefulWidget {
  final List<PropertyModel> properties;
  const FilterResultScreen({Key? key, required this.properties})
      : super(key: key);

  @override
  State<FilterResultScreen> createState() => _FilterResultScreenState();
}

class _FilterResultScreenState extends State<FilterResultScreen> {
  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios,
                      size: 25,
                    ),
                    Text(
                      '${widget.properties.length} Results Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: grey,
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.grid_on,
                      color: grey,
                      size: 18,
                    )
                  ],
                )
              ],
            ),
          ),
          h10(),
          Divider(),
          widget.properties.isEmpty
              ? Container(
                  child: SingleChildScrollView(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          Image.asset(
                            imageRounte(name: 'oops.png'),
                          ),
                          Text(
                              'We could not find this  property in this location'),
                          Divider(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              'You can make a request an agent would follow you up',
                              style: TextStyle(
                                  color: context.palette.accent,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 50),
                          GestureDetector(
                            onTap: () {
                              Provider.of<NavigationProvider>(context,
                                      listen: false)
                                  .setScreen(1);
                              goTo(context, const BottomNavHome(), true);
                            },
                            child: Container(
                              height: 45,
                              width: 150,
                              decoration: BoxDecoration(
                                borderRadius: appRadius(20.0),
                                color: context.palette.primaryFill,
                              ),
                              child: Center(
                                  child: Text(
                                'Make Request',
                                style: TextStyle(
                                  color: white,
                                ),
                              )),
                            ),
                          )
                        ]),
                  ),
                )
              : RecommendedWidget(properties: widget.properties)
        ],
      ),
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
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => goBack(context),
                            child: const Icon(Icons.arrow_back,
                                color: AppColors.textDark),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${widget.properties.length} results found',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (widget.properties.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const EmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No properties found in this location',
                              message:
                                  'You can make a request and an agent will follow up',
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 200,
                              child: MiaButton(
                                text: 'Make request',
                                onPressed: () {
                                  Provider.of<NavigationProvider>(context,
                                          listen: false)
                                      .setScreen(1);
                                  goTo(context, const BottomNavHome(), true);
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      WebPropertyGrid(
                        properties: widget.properties,
                        onTap: (p) => goTo(
                            context, HouseDetailsScreen(property: p), false),
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
}
