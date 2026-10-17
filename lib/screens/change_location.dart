// import 'dart:convert';
// import 'dart:math';
// import 'dart:async';
// import 'package:eafind/const/constant.dart';
// import 'package:eafind/providers/location_provider.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_place_picker_mb/google_maps_place_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:location/location.dart' as loc;
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:google_api_headers/google_api_headers.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_webservice/places.dart';

// import 'package:google_maps_place_picker_mb/src/google_map_place_picker.dart';
// import 'places_autocomplete.dart';

// class BookingLocation extends StatefulWidget {
//   bool change = false;
//   bool isMultiple;
//   BookingLocation({Key? key, required this.change, required this.isMultiple})
//       : super(key: key);

//   @override
//   _BookingLocationState createState() => _BookingLocationState();
// }

// final homeScaffoldKey = GlobalKey<ScaffoldState>();
// final searchScaffoldKey = GlobalKey<ScaffoldState>();
// const kGoogleApiKey = GoogleApiKey;

// class _BookingLocationState extends State<BookingLocation> {
//   void onError(PlacesAutocompleteResponse response) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(response.errorMessage!)),
//     );
//   }

//   var lati;
//   var lngi;
//   Future<void> _handlePressButton() async {
//     // show input autocomplete with selected mode
//     // then get the Prediction selected
//     Mode _mode = Mode.overlay;
//     Prediction? p = await PlacesAutocomplete.show(
//       offset: 0,
//       radius: 1000,
//       strictbounds: false,
//       region: 'ng',
//       sessionToken: Uuid().generateV4(),
//       context: context,
//       apiKey: GoogleApiKey,
//       onError: onError,
//       mode: Mode.overlay,
//       language: "ng",
//       decoration: InputDecoration(
//         hintText: currentAddress,
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(20),
//           borderSide: BorderSide(
//             color: Colors.white,
//           ),
//         ),
//       ),
//       components: [Component(Component.country, "ng")],
//       types: ["address"],
//       logo: Icon(Icons.map),
//     );

//     GoogleMapsPlaces _places = GoogleMapsPlaces(
//       apiKey: kGoogleApiKey,
//       apiHeaders: await GoogleApiHeaders().getHeaders(),
//     );
//     PlacesDetailsResponse detail =
//         await _places.getDetailsByPlaceId(p!.placeId!);
//     final lat = detail.result.geometry!.location.lat;
//     final lng = detail.result.geometry!.location.lng;
//     print('this is p details ${detail.result.formattedAddress}');

//     setState(() {
//       currentAddress = detail.result.formattedAddress!;
//       var target = LatLng(lat, lng);
//       lati = lat;
//       lngi = lng;
//       initialPostion = CameraPosition(target: target, zoom: 13);
//     });
//   }

//   var currentAddress = '';
//   getLocation() async {
//     final locData = await Geolocator.getCurrentPosition();

//     final url =
//         'https://maps.googleapis.com/maps/api/geocode/json?latlng=${locData.latitude},${locData.longitude}&key=$GoogleApiKey';
//     final response = await http.get(Uri.parse(url));
//     final result = json.decode(response.body);
//     var target = LatLng(locData.latitude, locData.longitude);
//     print(result);
//     if (!mounted) return;
//     setState(() {
//       initialPostion = CameraPosition(target: target, zoom: 13);
//       currentAddress = result['results'][0]['formatted_address'];
//       lati = locData.latitude;
//       lngi = locData.longitude;
//     });

//     Map location = {'location': currentAddress, 'lat': lati, 'lng': lngi};
//   }

//   Completer<GoogleMapController> _controller = Completer();

//   CameraPosition? initialPostion;
//   @override
//   void initState() {
//     super.initState();
//     getLocation();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//           appBar: AppBar(
//             backgroundColor: transparent,
//             elevation: 0.0,
//             leading: GestureDetector(
//               onTap: (() => goBack(context)),
//               child: Icon(
//                 Icons.arrow_back,
//                 color: primaryColor,
//               ),
//             ),
//           ),
//           body: Stack(
//             children: [
//               Container(
//                 child: initialPostion == null
//                     ? Center(
//                         child: CircularProgressIndicator(),
//                       )
//                     : GoogleMap(
//                         initialCameraPosition: initialPostion!,
//                         mapType: MapType.terrain,
//                         onMapCreated: (GoogleMapController controller) {
//                           _controller.complete(controller);
//                         },
//                       ),
//               ),
//               Positioned(
//                 top: 35,
//                 left: 10,
//                 right: 10,
//                 child: GestureDetector(
//                   onTap: () => _handlePressButton(),
//                   child: Card(
//                     elevation: 10,
//                     child: Container(
//                       width: MediaQuery.of(context).size.width,
//                       padding: EdgeInsets.all(15),
//                       margin: EdgeInsets.symmetric(horizontal: 15),
//                       child: Text(
//                         'Enter new Location',
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               Positioned(
//                 bottom: 1.0,
//                 left: 2.0,
//                 right: 2.0,
//                 child: Container(
//                   width: MediaQuery.of(context).size.width,
//                   child: Card(
//                     elevation: 15,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(20),
//                         topRight: Radius.circular(20),
//                       ),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           height: 10,
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: GestureDetector(
//                             onTap: () => _handlePressButton(),
//                             child: Text(
//                               'Set your location',
//                             ),
//                           ),
//                         ),
//                         Divider(
//                           thickness: 1.0,
//                           color: grey,
//                         ),
//                         Row(
//                           children: [
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Icon(
//                                 Icons.location_on,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                             Expanded(
//                               child: Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(
//                                   currentAddress,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                             )
//                           ],
//                         ),
//                         Divider(
//                           thickness: 1.0,
//                           color: grey,
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(15),
//                           child: Container(
//                             decoration: BoxDecoration(
//                                 color: primaryColor,
//                                 borderRadius: BorderRadius.all(
//                                   Radius.circular(20),
//                                 )),
//                             width: MediaQuery.of(context).size.width,
//                             margin: EdgeInsets.symmetric(horizontal: 18),
//                             child: MaterialButton(
//                               onPressed: () async {
//                                 if (currentAddress.isNotEmpty) {
//                                   Map location = {
//                                     'address': currentAddress,
//                                     'lat': lati,
//                                     'lng': lngi
//                                   };
//                                   Provider.of<LocationProvider>(context,
//                                           listen: false)
//                                       .setLoation(location);
//                                 }
//                                 goBack(context);
//                                 Fluttertoast.showToast(msg: 'Location updated');
//                               },
//                               child: Text(
//                                 'Confirm Location',
//                                 style: TextStyle(color: white),
//                               ),
//                             ),
//                           ),
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//               )
//             ],
//           )),
//     );
//   }
// }

// class Uuid {
//   final Random _random = Random();

//   String generateV4() {
//     // Generate xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx / 8-4-4-4-12.
//     final int special = 8 + _random.nextInt(4);

//     return '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
//         '${_bitsDigits(16, 4)}-'
//         '4${_bitsDigits(12, 3)}-'
//         '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
//         '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
//   }

//   String _bitsDigits(int bitCount, int digitCount) =>
//       _printDigits(_generateBits(bitCount), digitCount);

//   int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

//   String _printDigits(int value, int count) =>
//       value.toRadixString(16).padLeft(count, '0');
// }
