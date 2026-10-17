import 'package:eafind/screens/house_details_screen.dart';
import 'package:eafind/services/providers/data_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';
import '../widgets/recomemded_widget.dart';

const String _category = 'Land';

class LandScreen extends StatefulWidget {
  const LandScreen({Key? key}) : super(key: key);

  @override
  State<LandScreen> createState() => _LandScreenState();
}

class _LandScreenState extends State<LandScreen> {
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
                    icon: Icons.terrain_outlined,
                    title: 'No lands found',
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
}
