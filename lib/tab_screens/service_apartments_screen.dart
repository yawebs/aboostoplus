import 'package:eafind/screens/house_details_screen.dart';
import 'package:eafind/services/providers/data_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/recomemded_widget.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../const/constant.dart';

class ServiceApartmentsScreen extends StatefulWidget {
  const ServiceApartmentsScreen({Key? key}) : super(key: key);

  @override
  State<ServiceApartmentsScreen> createState() =>
      _ServiceApartmentsScreenState();
}

class _ServiceApartmentsScreenState extends State<ServiceApartmentsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<DataProvider>(context, listen: false).fetchServiceApartments();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildWeb(BuildContext context) {
    final dataProvider = context.watch<DataProvider>();
    final properties = dataProvider.serviceApartments;
    return Theme(
      data: AppTheme.theme,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(4),
        child: !dataProvider.hasFetchedServiceApartments
            ? Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
              )
            : properties.isEmpty
                ? const EmptyState(
                    icon: Icons.apartment_outlined,
                    title: 'No service apartments yet',
                    message: 'Check back soon for new listings',
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
    final properties = dataProvider.serviceApartments;
    return ListView(
      shrinkWrap: true,
      primary: false,
      children: [
        const SizedBox(height: 10),
        !dataProvider.hasFetchedServiceApartments
            ? listLoader()
            : properties.isEmpty
                ? Container(
                    height: 300,
                    child: const Center(
                      child: Text('No service apartments yet'),
                    ),
                  )
                : RecommendedWidget(properties: properties),
      ],
    );
  }
}
