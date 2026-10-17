import 'package:flutter/material.dart';

const String kServiceApartment = 'Service Apartment';

// Shown as selectable chips on the service apartment upload form; the
// selected values are stored in the property's `requirements` list.
const List<String> serviceApartmentAmenities = [
  'Wi-Fi',
  '24/7 Power',
  'Air Conditioning',
  'Water Supply',
  'Security',
  'Parking',
  'Daily Cleaning',
  'Fully Furnished',
  'Kitchen',
  'Smart TV',
  'Generator',
  'Swimming Pool',
];

IconData serviceApartmentAmenityIcon(String amenity) {
  switch (amenity) {
    case 'Wi-Fi':
      return Icons.wifi_rounded;
    case '24/7 Power':
    case 'Generator':
      return Icons.bolt_rounded;
    case 'Air Conditioning':
      return Icons.ac_unit_rounded;
    case 'Water Supply':
      return Icons.water_drop_outlined;
    case 'Security':
      return Icons.shield_outlined;
    case 'Parking':
      return Icons.local_parking_rounded;
    case 'Daily Cleaning':
      return Icons.cleaning_services_outlined;
    case 'Fully Furnished':
      return Icons.weekend_outlined;
    case 'Kitchen':
      return Icons.kitchen_outlined;
    case 'Smart TV':
      return Icons.tv_rounded;
    case 'Swimming Pool':
      return Icons.pool_rounded;
    default:
      return Icons.check_circle_outline_rounded;
  }
}

class HouseTypeModel {
  String type;
  HouseTypeModel({required this.type});
}

List<HouseTypeModel> houseTypes = [
  HouseTypeModel(type: 'Duplex'),
  HouseTypeModel(type: 'Self-Contain'),
  HouseTypeModel(type: '1Bed-Room'),
  HouseTypeModel(type: '2Bed-Room'),
  HouseTypeModel(type: '3Bed-Room'),
  HouseTypeModel(type: '4Bed-Room'),
  HouseTypeModel(type: '1-Room'),
  HouseTypeModel(type: 'Bongalo'),
  HouseTypeModel(type: kServiceApartment),
  HouseTypeModel(type: 'Land'),
  HouseTypeModel(type: 'Office Space'),
  HouseTypeModel(type: 'Hall'),
  HouseTypeModel(type: 'Property Sales'),
];
List<String> itemTypes = [
  'Funiture',
  'Electronics',
  'Clothing',
  'Toiletries',
  'Health & Beauty',
  'Sports & Outdoors',
  'Automotive',
  'Home & Garden',
  'Tools & Home Improvement',
  'Office Products',
  'Pet Supplies',
  'Baby Products',
  'Musical Instruments',
  'Books',
];

// Home services live in their own system (service-providers.php), separate
// from the marketplace - providers list via the "List your service" screen.

const List<String> homeServiceTypes = [
  'Moving & Haulage',
  'Cleaning',
  'Painting',
  'Power & Solar',
  'Plumbing',
  'Electrical',
  'Fumigation',
];

class HomeServiceInfo {
  final IconData icon;
  final String blurb;
  final Color color;
  const HomeServiceInfo(this.icon, this.blurb, this.color);
}

const Map<String, HomeServiceInfo> homeServiceInfo = {
  'Moving & Haulage': HomeServiceInfo(Icons.local_shipping_rounded,
      'Trucks, packers and loaders', Color(0xFF6A3D7A)),
  'Cleaning': HomeServiceInfo(Icons.cleaning_services_rounded,
      'Move-in & deep cleaning', Color(0xFF2E9E8F)),
  'Painting': HomeServiceInfo(Icons.format_paint_rounded,
      'Fresh walls before you move in', Color(0xFFD9578A)),
  'Power & Solar': HomeServiceInfo(Icons.solar_power_rounded,
      'Inverters, solar & generators', Color(0xFFE8A93B)),
  'Plumbing': HomeServiceInfo(
      Icons.plumbing_rounded, 'Leaks, taps & water tanks', Color(0xFF3A86E0)),
  'Electrical': HomeServiceInfo(Icons.electrical_services_rounded,
      'Wiring, sockets & meters', Color(0xFFC98E23)),
  'Fumigation': HomeServiceInfo(Icons.pest_control_rounded,
      'Pest control before you move', Color(0xFF2E9E5B)),
};

List<String> communities = [
  'Alakahia',
  'Atali',
  'Awalama',
  'Choba',
  'Egbelu',
  'Elelenwo',
  'Eligbam',
  'Elimgbu',
  'Elioparanwo',
  'Eliozu',
  'Eneka',
  'Eligbolo',
  'Iriebe',
  'Mgbuesilaru',
  'Mgbuoba',
  'Mgbuosimini',
  'Mpakurche',
  'Nkpa',
  'Nkpelu',
  'Ogbogoro',
  'Oginigba',
  'Oro-Igwe',
  'Oroazi',
  'Ozuoba',
  'Rukpokwu',
  'Rumuadaolu',
  'Rumuaghaolu',
  'Rumualogu',
  'Rumuchiorlu',
  'Rumudara',
  'Rumudogo',
  'Rumuekini',
  'Rumuekwe',
  'Rumueme',
  'Rumuepirikom',
  'Rumuesara',
  'Rumuewhara',
  'Rumuibekwe',
  'Rumuigbo',
  'Rumukalagbor',
  'Rumunduru',
  'Rumuobiokani',
  'Rumuogba',
  'Rumuokparali',
  'rumorukakolisi',
  'Rumuolumeni',
  'Rumuobochi',
  'Rumuodomaya',
  'Rumuoji',
  'Rumuokoro',
  'Rumuokwu',
  'Rumuokwachi',
  'Rumuokwuota',
  'Rumuokwurusi',
  'Rumuola',
  'Rumuolukwu',
  'Rumuomasi',
  'Rumuomoi',
  'Rumuosi',
  'Rumuoto',
  'Rumurolu',
  'Rumuwaji',
  'Rumuwegwu',
  'Trans-Amadi',
  'Woji'
];

// Icon for each property type, used by the property type picker.
IconData propertyTypeIcon(String type) {
  switch (type) {
    case 'Duplex':
      return Icons.holiday_village_rounded;
    case 'Bongalo':
      return Icons.cottage_rounded;
    case 'Self-Contain':
      return Icons.single_bed_rounded;
    case '1-Room':
      return Icons.door_front_door_rounded;
    case '1Bed-Room':
    case '2Bed-Room':
    case '3Bed-Room':
    case '4Bed-Room':
      return Icons.king_bed_rounded;
    case kServiceApartment:
      return Icons.apartment_rounded;
    case 'Land':
      return Icons.terrain_rounded;
    case 'Office Space':
      return Icons.business_center_rounded;
    case 'Hall':
      return Icons.celebration_rounded;
    case 'Property Sales':
      return Icons.sell_rounded;
    default:
      return Icons.home_rounded;
  }
}

// Readable name for a stored type value (the values themselves are saved
// as listing categories, so they stay unchanged).
String propertyTypeLabel(String type) {
  const labels = {
    'Bongalo': 'Bungalow',
    'Self-Contain': 'Self-contain',
    '1-Room': 'Single room',
    '1Bed-Room': '1 Bedroom',
    '2Bed-Room': '2 Bedroom',
    '3Bed-Room': '3 Bedroom',
    '4Bed-Room': '4 Bedroom',
  };
  return labels[type] ?? type;
}

// Short hint under the name in the picker.
String propertyTypeHint(String type) {
  switch (type) {
    case 'Duplex':
      return 'Multi-storey home';
    case 'Bongalo':
      return 'Single-storey home';
    case 'Self-Contain':
      return 'Room + own kitchen & bath';
    case '1-Room':
      return 'Shared facilities';
    case kServiceApartment:
      return 'Priced per night';
    case 'Land':
      return 'Opens the land sale form';
    case 'Office Space':
      return 'For businesses';
    case 'Hall':
      return 'Events & gatherings';
    case 'Property Sales':
      return 'Buildings for sale';
    default:
      return 'Flat / apartment';
  }
}

// Picker sections, in display order.
const Map<String, List<String>> propertyTypeGroups = {
  'Homes': [
    'Duplex',
    'Bongalo',
    '1Bed-Room',
    '2Bed-Room',
    '3Bed-Room',
    '4Bed-Room',
    'Self-Contain',
    '1-Room',
  ],
  'Short stays': [kServiceApartment],
  'Land & commercial': ['Land', 'Office Space', 'Hall', 'Property Sales'],
};
