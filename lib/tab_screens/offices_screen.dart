import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/services/providers/data_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/recomemded_widget.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../screens/house_details_screen.dart';
import '../screens/view_story_screen.dart';

const String _category = 'Office Space';

class OfficesScreen extends StatefulWidget {
  const OfficesScreen({Key? key}) : super(key: key);

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false)
        .fetchCategoryProperties(_category);
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildWeb(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final properties = dataProvider.categoryProperties[_category];
    return Theme(
      data: AppTheme.theme,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(4),
        child: properties == null
            ? Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            : properties.isEmpty
                ? const EmptyState(
                    icon: Icons.business_outlined,
                    title: 'No office spaces found',
                  )
                : WebPropertyGrid(
                    properties: properties,
                    onTap: (p) =>
                        goTo(context, HouseDetailsScreen(property: p), false),
                  ),
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final properties = dataProvider.categoryProperties[_category];
    return ListView(
      shrinkWrap: true,
      primary: false,
      children: [
        const SizedBox(
          height: 10,
        ),
        properties == null
            ? listLoader()
            : properties.isEmpty
                ? Container(
                    height: 300,
                    child: const Center(
                      child: Text('No Data Found'),
                    ),
                  )
                : RecommendedWidget(
                    properties: properties,
                  ),
      ],
    );
  }

  Widget officesWidget() {
    return GestureDetector(
      onTap: (() => ''),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: appRadius(15.0),
          color: context.palette.paper,
          image: const DecorationImage(
            fit: BoxFit.cover,
            image: AssetImage('assets/images/office1.jpg'),
          ),
        ),
        child: Stack(children: [
          Positioned(
            right: 5.0,
            top: 5.0,
            child: GestureDetector(
              onTap: (() {
                goTo(
                    context,
                    const ViewStoryScreen(
                      images: [],
                    ),
                    false);
              }),
              child: Container(
                width: 40,
                height: 40,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: appRadius(20.0)),
                  child: Icon(
                    Icons.remove_red_eye,
                    size: 15,
                    color: context.palette.accent,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
              bottom: 10,
              child: Container(
                width: width(context),
                decoration: BoxDecoration(
                  borderRadius: appRadius(10.0),
                  color: shadowColor,
                ),
                padding: const EdgeInsets.only(left: 5, top: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'N300,000 ',
                      style: TextStyle(
                        color: white,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        '24 Rumuomasi',
                        style: TextStyle(
                            color: white, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              borderRadius: appRadius(50.0), color: context.palette.paper),
                          child: Icon(
                            Icons.lan_outlined,
                            size: 15,
                            color: context.palette.accent,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            '15/15',
                            style: TextStyle(color: white),
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              borderRadius: appRadius(50.0), color: context.palette.paper),
                          child: Icon(
                            Icons.calendar_today,
                            size: 15,
                            color: context.palette.accent,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Yearly',
                            style: TextStyle(color: white),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ))
        ]),
      ),
    );
  }
}
