import 'dart:async';
import 'package:flutter_myuber/Models/Place_details.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_myuber/AllScreens/loginScreen.dart';
import 'package:flutter_myuber/AllScreens/searchScreen.dart';
import 'package:flutter_myuber/AllWidgets/Divider.dart';
import 'package:flutter_myuber/AllWidgets/progressDialog.dart';
import 'package:flutter_myuber/Assistants/assistantMethods.dart';
import 'package:flutter_myuber/DataHandler/appData.dart';
import 'package:flutter_myuber/Models/directDetails.dart';
import 'package:flutter_myuber/configMaps.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geodesy/geodesy.dart' as gds;
import 'package:google_maps_webservice/places.dart';

import 'exploreScreen.dart';

class MainScreen extends StatefulWidget {
  static const String idScreen = "mainScreen";
  @override
  _MainScreenState createState() => _MainScreenState();
}

const colorizeColors = [
  Colors.green,
  Colors.purple,
  Colors.pink,
  Colors.blue,
  Colors.yellow,
  Colors.red,
];

const colorizeTextStyle = TextStyle(
  fontSize: 50.0,
  fontFamily: 'Signatra',
);

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  DirectionDetails tripDirectionDetails;

  List<LatLng> pLineCoordinates = [];
  Set<Polyline> polylineSet = {};

  Position currentPosition;
  var geoLocator = Geolocator();
  double bottomPaddingofMap = 0;

  Set<Marker> markersSet = {};
  Set<Marker> markersSet2 = {};
  List<Place> newPlaces = [];
  Set<Marker> _shops = {};
  Set<Circle> circlesSet = {};

  double rideDetailsContainerHeight = 0;
  double searchContainerHeight = 300.0;
  double requestRideContainerHeight = 0;
  bool drawerOpen = true;
  DatabaseReference rideRequestRef;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    AssistantMethods.getCurrentOnlineUserInfo();
  }

  void saveRideRequest() {
    rideRequestRef =
        FirebaseDatabase.instance.reference().child("Ride Requests");

    var pickUp = Provider.of<AppData>(context, listen: false).pickUpLocation;
    var dropOff = Provider.of<AppData>(context, listen: false).dropOffLocation;

    Map pickUpLocMap = {
      "latitude": pickUp.latitude.toString(),
      "longitude": pickUp.longitude.toString(),
    };

    Map dropOffLocMap = {
      "latitude": dropOff.latitude.toString(),
      "longitude": dropOff.longitude.toString(),
    };

    Map rideInfoMap = {
      "driver_id": "waiting",
      "payment_method": "cash",
      "pickup": pickUpLocMap,
      "dropOff": dropOffLocMap,
      "created_at": DateTime.now().toString(),
      "rider_name": userCurrentInfo.name,
      "rider_phone": userCurrentInfo.phone,
      "pickup_address": pickUp.placeName,
      "dropoff_address": dropOff.placeName,
    };

    rideRequestRef.push().set(rideInfoMap);
  }

  void cancelRideRequest() {
    rideRequestRef.remove();
  }

  void displayRequestRideContainer() {
    setState(() {
      requestRideContainerHeight = 320.0;
      rideDetailsContainerHeight = 0;
      bottomPaddingofMap = 230.0;
      drawerOpen = true;
    });

    saveRideRequest();
  }

  resetApp() {
    setState(() {
      drawerOpen = true;
      searchContainerHeight = 300.0;
      rideDetailsContainerHeight = 0;
      requestRideContainerHeight = 0;
      bottomPaddingofMap = 230.0;

      polylineSet.clear();
      markersSet.clear();
      markersSet2.clear();
      newPlaces.clear();
      circlesSet.clear();
      pLineCoordinates.clear();
    });

    locatePosition();
  }

  void displayRideDetailsContainer() async {
    await getPlaceDirections();

    setState(() {
      searchContainerHeight = 0.0;
      rideDetailsContainerHeight = 320.0;
      bottomPaddingofMap = 230.0;
      drawerOpen = false;
    });
  }

  void locatePosition() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentPosition = position;

    LatLng latLatPosition = LatLng(position.latitude, position.longitude);

    CameraPosition cameraPosition =
        new CameraPosition(target: latLatPosition, zoom: 14);
    newGoogleMapController
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String address =
        await AssistantMethods.searchCoordinatesAddress(position, context);
    print("This is your address :: " + address);
  }

  Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController newGoogleMapController;
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        title: Text("Main Screen"),
      ),
      drawer: Container(
        color: Colors.white,
        width: 300.0,
        child: Drawer(
          child: ListView(
            children: [
              Container(
                height: 165.0,
                child: DrawerHeader(
                  decoration: BoxDecoration(color: Colors.white),
                  child: Row(
                    children: [
                      Image.asset(
                        "images/user_icon.png",
                        height: 65.0,
                        width: 65.0,
                      ),
                      SizedBox(
                        width: 16.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Profile Name",
                            style: TextStyle(
                                fontSize: 16.0, fontFamily: "Brand-Bold"),
                          ),
                          SizedBox(
                            height: 6.0,
                          ),
                          Text("Visit Profile"),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              DividerWidget(),
              SizedBox(
                height: 12.0,
              ),
              ListTile(
                leading: Icon(Icons.history),
                title: Text("History",
                    style: TextStyle(
                      fontSize: 15.0,
                    )),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text("Visit Profile",
                    style: TextStyle(
                      fontSize: 15.0,
                    )),
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text("About",
                    style: TextStyle(
                      fontSize: 15.0,
                    )),
              ),
              GestureDetector(
                onTap: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, LoginScreen.idScreen, (route) => false);
                },
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text("Sign Out",
                      style: TextStyle(
                        fontSize: 15.0,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingofMap),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;
              setState(() {
                bottomPaddingofMap = 265;
              });
              locatePosition();
            },
          ),
          Positioned(
            top: 38.0,
            left: 22.0,
            child: GestureDetector(
              onTap: () {
                if (drawerOpen) {
                  scaffoldKey.currentState.openDrawer();
                } else {
                  resetApp();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 6.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      )
                    ]),
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon((drawerOpen) ? Icons.menu : Icons.close),
                  radius: 20.0,
                ),
              ),
            ),
          ),
          Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 10.0,
              child: AnimatedSize(
                vsync: this,
                curve: Curves.bounceIn,
                duration: new Duration(milliseconds: 160),
                child: Container(
                  height: searchContainerHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18.0),
                        topRight: Radius.circular(18.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 6.0),
                        Text(
                          "Hi there, ",
                          style: TextStyle(fontSize: 10.0),
                        ),
                        Text(
                          "Where to?, ",
                          style: TextStyle(
                              fontSize: 20.0, fontFamily: "Brand-Bold"),
                        ),
                        SizedBox(height: 10.0),
                        GestureDetector(
                          onTap: () async {
                            var res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SearchScreen()));

                            if (res == "obtainDirection") {
                              displayRideDetailsContainer();
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(5.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 6.0,
                                  spreadRadius: 0.5,
                                  offset: Offset(0.7, 0.7),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: Colors.yellowAccent,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text("Search Drop Off")
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10.0),
                        Row(
                          children: [
                            Icon(
                              Icons.home,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: 12.0,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(Provider.of<AppData>(context)
                                            .pickUpLocation !=
                                        null
                                    ? Provider.of<AppData>(context)
                                        .pickUpLocation
                                        .placeName
                                    : "Add Home"),
                                SizedBox(
                                  height: 4.0,
                                ),
                                Text(
                                  "Your living home address",
                                  style: TextStyle(
                                      color: Colors.grey[200], fontSize: 12.0),
                                ),
                              ],
                            )
                          ],
                        ),
                        SizedBox(height: 10.0),
                        DividerWidget(),
                        SizedBox(
                          height: 16.0,
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.work,
                              color: Colors.grey,
                            ),
                            SizedBox(
                              width: 12.0,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Add Work"),
                                SizedBox(
                                  height: 4.0,
                                ),
                                Text(
                                  "Your Office address",
                                  style: TextStyle(
                                      color: Colors.grey[200], fontSize: 12.0),
                                ),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: AnimatedSize(
              vsync: this,
              curve: Curves.bounceIn,
              duration: new Duration(milliseconds: 160),
              child: Container(
                height: rideDetailsContainerHeight,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16.0),
                      topRight: Radius.circular(16.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 16.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      )
                    ]),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Colors.tealAccent[100],
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Image.asset("images/taxi.png",
                                height: 70.0, width: 80.0),
                            SizedBox(
                              width: 16.0,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Car",
                                  style: TextStyle(
                                      fontSize: 18.0, fontFamily: "Brand-Bold"),
                                ),
                                Text(
                                  ((tripDirectionDetails != null)
                                      ? tripDirectionDetails.distanceText
                                      : ''),
                                  style: TextStyle(
                                      fontSize: 16.0, color: Colors.grey),
                                )
                              ],
                            ),
                            Expanded(child: Container()),
                            Text(
                              ((tripDirectionDetails != null)
                                  ? '\$${AssistantMethods.calculateFares(tripDirectionDetails)}'
                                  : ''),
                              style: TextStyle(fontFamily: "Brand-Bold"),
                            )
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 20.0,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.moneyCheckAlt,
                            size: 18.0,
                            color: Colors.black54,
                          ),
                          SizedBox(
                            width: 16.0,
                          ),
                          Text("Cash"),
                          SizedBox(
                            width: 6.0,
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black54,
                            size: 16.0,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 24.0,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Theme.of(context).accentColor),
                        ),
                        onPressed: () {
                          displayRequestRideContainer();
                        },
                        child: Padding(
                          padding: EdgeInsets.all(17.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Request",
                                style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Icon(
                                FontAwesomeIcons.taxi,
                                color: Colors.white,
                                size: 26.0,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 10.0),
                    SizedBox(height: 10.0),
                    Builder(builder: (context) {
                      final GlobalKey<SlideActionState> _key = GlobalKey();
                      return Padding(
                        padding: EdgeInsets.all(1.0),
                        child: SlideAction(
                          innerColor: Colors.black,
                          outerColor: Colors.white,
                          child: Text("Explore Nearby"),
                          sliderButtonIcon: Icon(
                            Icons.local_dining_rounded,
                            color: Colors.white,
                          ),
                          borderRadius: 16.0,
                          submittedIcon: Icon(Icons.done),
                          animationDuration: Duration(milliseconds: 300),
                          key: _key,
                          onSubmit: () async {
                            var res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ExploreScreen(
                                        markersSet2, newPlaces, polylineSet)));

                            Future.delayed(
                              Duration(milliseconds: 700),
                              () => _key.currentState.reset(),
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0.0,
            left: 0.0,
            right: 0.0,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.0),
                    topRight: Radius.circular(16.0),
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      spreadRadius: 0.5,
                      blurRadius: 16.0,
                      color: Colors.black54,
                      offset: Offset(0.7, 0.7),
                    )
                  ]),
              height: requestRideContainerHeight,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 12.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: AnimatedTextKit(
                        animatedTexts: [
                          ColorizeAnimatedText(
                            'Requesting a Ride...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                          ),
                          ColorizeAnimatedText(
                            'Please Wait...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                          ),
                          ColorizeAnimatedText(
                            'Finding a Driver...',
                            textStyle: colorizeTextStyle,
                            colors: colorizeColors,
                          ),
                        ],
                        isRepeatingAnimation: true,
                        onTap: () {
                          print("Tap Event");
                        },
                      ),
                    ),
                    SizedBox(
                      height: 22.0,
                    ),
                    GestureDetector(
                      onTap: () {
                        cancelRideRequest();
                        resetApp();
                      },
                      child: Container(
                        height: 60.0,
                        width: 60.0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26.0),
                          border:
                              Border.all(width: 2.0, color: Colors.grey[300]),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 26.0,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      width: double.infinity,
                      child: Text(
                        "Cancel Ride",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.0),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getPlaceDirections() async {
    var initialPos =
        Provider.of<AppData>(context, listen: false).pickUpLocation;

    //var initialPos2 = LatLng(22.5985633, 88.3662865);
    var finalPos = Provider.of<AppData>(context, listen: false).dropOffLocation;

    var pickUpLatLng = LatLng(initialPos.latitude, initialPos.longitude);
    var dropOffLatLng = LatLng(finalPos.latitude, finalPos.longitude);

    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Please wait...",
            ));

    var details = await AssistantMethods.obtainPlaceDirectionDetails(
        pickUpLatLng, dropOffLatLng);
    setState(() {
      tripDirectionDetails = details;
    });
    Navigator.pop(context);

    print("This is the encoded points :: ");
    print(details.encodedPoints);

    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResult =
        polylinePoints.decodePolyline(details.encodedPoints);
    pLineCoordinates.clear();
    if (decodedPolyLinePointsResult.isNotEmpty) {
      decodedPolyLinePointsResult.forEach((PointLatLng pointLatLng) {
        pLineCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    polylineSet.clear();
    setState(() {
      Polyline polyline = Polyline(
        color: Colors.pink,
        polylineId: PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoordinates,
        width: 5,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    });

    LatLngBounds latLngBounds;
    if (pickUpLatLng.latitude > dropOffLatLng.latitude &&
        pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds =
          LatLngBounds(southwest: dropOffLatLng, northeast: pickUpLatLng);
    } else if (pickUpLatLng.longitude > dropOffLatLng.longitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude),
          northeast: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude));
    } else if (pickUpLatLng.latitude > dropOffLatLng.latitude) {
      latLngBounds = LatLngBounds(
          southwest: LatLng(dropOffLatLng.latitude, pickUpLatLng.longitude),
          northeast: LatLng(pickUpLatLng.latitude, dropOffLatLng.longitude));
    } else {
      latLngBounds =
          LatLngBounds(southwest: pickUpLatLng, northeast: dropOffLatLng);
    }

    newGoogleMapController
        .animateCamera(CameraUpdate.newLatLngBounds(latLngBounds, 70));

    Marker pickUpLocMarker = Marker(
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        infoWindow:
            InfoWindow(title: initialPos.placeName, snippet: "my Location"),
        position: pickUpLatLng,
        markerId: MarkerId("pickUpId"));

    Marker dropOffLocMarker = Marker(
      //icons = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(title: finalPos.placeName, snippet: "my Location"),
      position: dropOffLatLng,
      markerId: MarkerId("dropOffId"),
    );
    print("shops before" + _shops.length.toString());
    getShopsInPath(pLineCoordinates, pickUpLatLng);
    print("shops after" + _shops.length.toString());

    setState(() {
      markersSet.add(pickUpLocMarker);
      markersSet2.add(pickUpLocMarker);
      markersSet.add(dropOffLocMarker);
      markersSet2.add(dropOffLocMarker);
      // for (var it in _shops) {
      //   markersSet.add(it);
      // }
      // _shops.clear();
      print("number of markers:");
      print(markersSet.length);
    });

    Circle pickUpLocCircle = Circle(
      fillColor: Colors.yellow,
      center: pickUpLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.yellowAccent,
      circleId: CircleId("pickUpId"),
    );

    Circle dropOffLocCircle = Circle(
      fillColor: Colors.blueAccent,
      center: dropOffLatLng,
      radius: 12,
      strokeWidth: 4,
      strokeColor: Colors.purple,
      circleId: CircleId("dropOffId"),
    );

    setState(() {
      circlesSet.add(pickUpLocCircle);
      circlesSet.add(dropOffLocCircle);
    });
  }

  Future<void> _retrieveNearbyRestaurants(LatLng _userLocation) async {
    PlacesSearchResponse _response = await places.searchNearbyWithRadius(
        Location(lat: _userLocation.latitude, lng: _userLocation.longitude),
        100,
        type: "restaurant");

    // Set<Marker> _restaurantMarkers = _response.results
    //     .map((result) => Marker(
    //         markerId: MarkerId(result.placeId),
    //         // Use an icon with different colors to differentiate between current location
    //         // and the restaurants
    //         icon: BitmapDescriptor.defaultMarkerWithHue(
    //             BitmapDescriptor.hueAzure),
    //         infoWindow: InfoWindow(
    //             title: result.name,
    //             snippet:
    //                 "Ratings: " + (result.rating?.toString() ?? "Not Rated")),
    //         position: LatLng(
    //             result.geometry.location.lat, result.geometry.location.lng)))
    //     .toSet();

    var result = _response.results[0];

    Marker mark = Marker(
        markerId: MarkerId(result.placeId),
        // Use an icon with different colors to differentiate between current location
        // and the restaurants
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(
            title: result.name,
            snippet: "Ratings: " + (result.rating?.toString() ?? "Not Rated")),
        position:
            LatLng(result.geometry.location.lat, result.geometry.location.lng));

    List<Photo> emp = [];
    setState(() {
      markersSet2.add(mark);
      newPlaces.add(Place(
        result.name,
        result.placeId,
        (result.photos) ?? emp,
        result.geometry.location.lat,
        result.geometry.location.lng,
      ));
    });
  }

  void getShopsInPath(List<LatLng> pLineCoordinates, LatLng pickUpLatLng) {
    // Set<Marker> _shops = {};
    Set<LatLng> shopsCood = {};
    shopsCood.add(pickUpLatLng);
    gds.LatLng prvLoc =
        gds.LatLng(pickUpLatLng.latitude, pickUpLatLng.longitude);
    gds.Geodesy geodesy = gds.Geodesy();
    var totDist = 0;
    var wpDist = 100;
    num dist = wpDist;
    for (var i = 1; i < pLineCoordinates.length; i++) {
      gds.LatLng waypt = gds.LatLng(
          pLineCoordinates[i].latitude, pLineCoordinates[i].longitude);
      // while (geodesy.distanceBetweenTwoGeoPoints(prvLoc, waypt) > 100) {
      //   prvLoc = geodesy.destinationPointByDistanceAndBearing(
      //       prvLoc, 100, geodesy.bearingBetweenTwoGeoPoints(prvLoc, waypt));
      //   shopsCood.add(LatLng(prvLoc.latitude, prvLoc.longitude));
      // }
      // prvLoc = waypt;
      // shopsCood.add(LatLng(waypt.latitude, waypt.longitude));
      if (geodesy.distanceBetweenTwoGeoPoints(prvLoc, waypt) < dist) {
        dist -= geodesy.distanceBetweenTwoGeoPoints(prvLoc, waypt);
        prvLoc = waypt;
        continue;
      }
      prvLoc = geodesy.destinationPointByDistanceAndBearing(
          prvLoc, dist, geodesy.bearingBetweenTwoGeoPoints(prvLoc, waypt));
      shopsCood.add(LatLng(prvLoc.latitude, prvLoc.longitude));

      if (geodesy.distanceBetweenTwoGeoPoints(prvLoc,
              gds.LatLng(pickUpLatLng.latitude, pickUpLatLng.longitude)) >
          1000) {
        break;
      }

      dist = wpDist;
      while (geodesy.distanceBetweenTwoGeoPoints(prvLoc, waypt) > dist) {
        shopsCood.add(LatLng(prvLoc.latitude, prvLoc.longitude));
        prvLoc = geodesy.destinationPointByDistanceAndBearing(
            prvLoc, wpDist, geodesy.bearingBetweenTwoGeoPoints(prvLoc, waypt));
        if (geodesy.distanceBetweenTwoGeoPoints(prvLoc,
                gds.LatLng(pickUpLatLng.latitude, pickUpLatLng.longitude)) >
            1000) {
          break;
        }
      }
      dist -= geodesy.distanceBetweenTwoGeoPoints(prvLoc, waypt);
      prvLoc = waypt;
      if (geodesy.distanceBetweenTwoGeoPoints(prvLoc,
              gds.LatLng(pickUpLatLng.latitude, pickUpLatLng.longitude)) >
          1000) {
        break;
      }
      // prvLoc = waypt;
      // shopsCood.add(LatLng(waypt.latitude, waypt.longitude));
    }
    var ind = 0;
    for (LatLng it in shopsCood) {
      _retrieveNearbyRestaurants(it);
      ind += 1;
    }
  }
}
