import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:flutter_myuber/AllScreens/place_detail.dart';
import 'package:flutter_myuber/Assistants/assistantMethods.dart';
import 'package:flutter_myuber/Assistants/requestAssistant.dart';
import 'package:flutter_myuber/DataHandler/appData.dart';
import 'package:flutter_myuber/Models/Place_details.dart';
import 'package:flutter_myuber/Models/placePredictions.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_webservice/places.dart';
import '../configMaps.dart';
import 'package:location/location.dart' as LocationManager;

final places =
    GoogleMapsPlaces(apiKey: "AIzaSyBecGfD_fSFXtYk9E42GvOO3LAVDIV1ysk");

Set<Marker> markerSet;
List<Place> newPlaces;
Set<Polyline> polyLineSet;

class ExploreScreen extends StatefulWidget {
  ExploreScreen(Set<Marker> _markerSet, List<Place> _newPlaces,
      Set<Polyline> _polyLineSet) {
    markerSet = _markerSet;
    newPlaces = _newPlaces;
    polyLineSet = _polyLineSet;
  }

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<ExploreScreen> {
  List<Widget> ini = [];
  // ignore: non_constant_identifier_names
  String name1 = "BOX8-MEALS", name2, name3, name4;
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController dropOffTextEditingController = TextEditingController();
  final homeScaffoldKey = GlobalKey<ScaffoldState>();
  GoogleMapController newGoogleMapController;
  List<PlacePredictions> placePredictionList = [];
  Position currentPosition;
  Completer<GoogleMapController> _controller = Completer();
  Future<Position> _currentLocation;
  Set<Marker> _markers = {};
  Queue<Place> allPlaces = new Queue();

  List<Photo> ph = <Photo>[];
  Photo _newPhoto = Photo(photoReference: "https://images.unsplash.com/photo-1504940892017-d23b9053d5d4?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=60");

  List<PlacesSearchResult> nearbyPlaces = [];
  double buttonHeight = 75.0;
  double containerHeight = 0;

  void displayRequestRideContainer() {
    setState(() {
      buttonHeight = 0;
      containerHeight = 150.0;
    });
    //_handlePressButton();
    _buildContainer();
    //ini.add(_buildContainer());
  }

  @override
  void initState() {
    super.initState();
    _currentLocation =
        Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _retrieveNearbyRestaurants(LatLng _userLocation) async {
    PlacesSearchResponse _response = await places.searchNearbyWithRadius(
        Location(lat: _userLocation.latitude, lng: _userLocation.longitude),
        1000,
        type: "restaurant");

    Set<Marker> _restaurantMarkers = _response.results
        .map((result) => Marker(
            markerId: MarkerId(result.name),
            // Use an icon with different colors to differentiate between current location
            // and the restaurants
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure),
            infoWindow: InfoWindow(
                title: result.name,
                snippet:
                    "Ratings: " + (result.rating?.toString() ?? "Not Rated")),
            position: LatLng(
                result.geometry.location.lat, result.geometry.location.lng)))
        .toSet();
    print(_response);
    List<Photo> emp = [];
    List<Place> _placeInfo = _response.results
        .map((result) => Place(
              result.name,
              result.placeId,
              (result.photos) ?? emp,
              result.geometry.location.lat,
              result.geometry.location.lng,
            ))
        .toList();

    for (int i = 0; i < _placeInfo.length; i++) {
      allPlaces.addFirst(_placeInfo[i]);
      if(allPlaces.length>5) {
        allPlaces.removeLast();
      }
      print("----------------------------");
      print(_placeInfo[i].name);
      // print(allPlaces[i].placeId);
      // print(allPlaces[i].photo);
      // print(allPlaces[i].name);
      print("****************************");
    }

    setState(() {
      _markers.addAll(_restaurantMarkers);
      if (_response.status == "OK") {
        this.nearbyPlaces = _response.results;
      }
    });
  }

  double zoomVal = 5.0;
  @override
  Widget build(BuildContext context) {
    ph.add(_newPhoto);
    Place emb = Place("Blue Tavern", "Abcd", ph, 0.0, 0.0);
    allPlaces.add(emb);
    allPlaces.add(emb);
    allPlaces.add(emb);
    allPlaces.add(emb);
    allPlaces.add(emb);
    allPlaces.add(emb);
    allPlaces.add(emb);
    ini.addAll(<Widget>[
      _buildGoogleMap(context),
      _zoomMinusFunction(),
      _zoomPlusFunction(),
      _buildButton(),
      _buildContainer(),
    ]);

    String placeAddress =
        Provider.of<AppData>(context).pickUpLocation.placeName ?? "";
    pickUpTextEditingController.text = placeAddress;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(FontAwesomeIcons.arrowLeft),
            onPressed: () {
                Navigator.pop(context);
            }),
        title: TextField(
          onChanged: (val) {
            findPlace(val);
          },
          controller: pickUpTextEditingController,
          decoration: InputDecoration(
            hintText: "Where to?",
            fillColor: Colors.grey[400],
            filled: true,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.only(left: 11.0, top: 8.0, bottom: 8.0),
          ),
          //controller: pickUpTextEditingController
        ),
      ),
      body: Stack(

        children: ini,
      ),
    );
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

  void findPlace(String placeName) async {
    if (placeName.length > 1) {
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$placeName&key=$mapKey&sessiontoken=1234567890&components=country:in";

      var res = await RequestAssistant.getRequest(autoCompleteUrl);
      if (res == "Failed") {
        return;
      }

      if (res["status"] == "OK") {
        var predictions = res["predictions"];
        var placesList = (predictions as List)
            .map((e) => PlacePredictions.fromJson(e))
            .toList();
        setState(() {
          placePredictionList = placesList;
        });
      }
    }
  }

  Widget _zoomMinusFunction() {
    return Align(
      alignment: Alignment.topLeft,
      child: IconButton(
          icon: Icon(FontAwesomeIcons.searchMinus, color: Color(0xff6200ee)),
          onPressed: () {
            zoomVal--;
            _minus(zoomVal);
          }),
    );
  }

  Widget _zoomPlusFunction() {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
          icon: Icon(FontAwesomeIcons.searchPlus, color: Color(0xff6200ee)),
          onPressed: () {
            zoomVal++;
            _plus(zoomVal);
          }),
    );
  }

  Widget _buildButton() {
    return Positioned(
      bottom: 0.0,
      left: 0.0,
      right: 0.0,
      child: Container(
        height: buttonHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  Theme.of(context).accentColor),
            ),
            onPressed: () {
              //await _buildGoogleMap(context);
              displayRequestRideContainer();
              //_buildContainer();
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
                    FontAwesomeIcons.delicious,
                    color: Colors.white,
                    size: 26.0,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _minus(double zoomVal) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(40.712776, -74.005974), zoom: zoomVal)));
  }

  Future<void> _plus(double zoomVal) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(40.712776, -74.005974), zoom: zoomVal)));
  }

  String buildPhotoURL(String photoReference) {
    return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=$mapKey";
  }

  Widget _buildContainer() {
    // for (int i = 0; i < min(5, allPlaces.length); i++) {
    //   print(allPlaces[i].name);
    //   print("=======================");
    // }
    List<Place> _nowPlace = allPlaces.toList();
    for (int i = 0; i < min(5, allPlaces.length); i++) {
      print(_nowPlace[i].name);
      print("=======================");
    }
    String locationPhotoRef;
    return Positioned(
      bottom: 0.0,
      left: 0.0,
      right: 0.0,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 20.0),
        height: containerHeight,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            SizedBox(width: 10.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _boxes(
                  //locationPhotoRef,
                  buildPhotoURL(_nowPlace[0].photo[0].photoReference),
                  //"https://lh5.googleusercontent.com/p/AF1QipMKRN-1zTYMUVPrH-CcKzfTo6Nai7wdL7D8PMkt=w340-h160-k-no",
                  _nowPlace[0].lat,
                  _nowPlace[0].lng,
                  _nowPlace[0].name),

              //allPlaces[0].geometry.location.lat, allPlaces[0].geometry.location.lng,allPlaces[0].name),
            ),
            SizedBox(width: 10.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _boxes(
                  buildPhotoURL(_nowPlace[1].photo[0].photoReference),
                  //"https://lh5.googleusercontent.com/p/AF1QipMKRN-1zTYMUVPrH-CcKzfTo6Nai7wdL7D8PMkt=w340-h160-k-no",
                  _nowPlace[1].lat,
                  _nowPlace[1].lng,
                  _nowPlace[1].name),
            ),
            SizedBox(width: 10.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _boxes(
                  buildPhotoURL(_nowPlace[2].photo[0].photoReference),
                  //"https://images.unsplash.com/photo-1504940892017-d23b9053d5d4?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=60",
                  _nowPlace[2].lat,
                  _nowPlace[2].lng,
                  _nowPlace[2].name),
            ),
            SizedBox(width: 10.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _boxes(
                  buildPhotoURL(_nowPlace[3].photo[0].photoReference),
                  //"https://images.unsplash.com/photo-1504940892017-d23b9053d5d4?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=60",
                  _nowPlace[3].lat,
                  _nowPlace[3].lng,
                  _nowPlace[3].name),
            ),
            SizedBox(width: 10.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _boxes(
                  buildPhotoURL(_nowPlace[4].photo[0].photoReference),
                  //"https://images.unsplash.com/photo-1504940892017-d23b9053d5d4?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=crop&w=500&q=60",
                  _nowPlace[4].lat,
                  _nowPlace[4].lng,
                  _nowPlace[4].name),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _gotoLocation(double lat, double long) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(lat, long),
      zoom: 15,
      tilt: 50.0,
      bearing: 45.0,
    )));
  }

  Widget _boxes(String _image, double lat, double long, String restaurantName) {
    return GestureDetector(
      onTap: () {
        _gotoLocation(lat, long);
      },
      child: Container(
        child: new FittedBox(
          child: Material(
              color: Colors.white,
              elevation: 14.0,
              borderRadius: BorderRadius.circular(24.0),
              shadowColor: Color(0x802196F3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                    width: 180,
                    height: 200,
                    child: ClipRRect(
                      borderRadius: new BorderRadius.circular(24.0),
                      child: Image(
                        fit: BoxFit.fill,
                        image: NetworkImage(_image),
                      ),
                    ),
                  ),
                  Container(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: myDetailsContainer1(restaurantName),
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildGoogleMap(BuildContext context) {
    return FutureBuilder(
        future: _currentLocation,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasData) {
              // The user location returned from the snapshot
              Position snapshotData = snapshot.data;
              LatLng _userLocation =
                  LatLng(snapshotData.latitude, snapshotData.longitude);
              if (_markers.isEmpty) {
                _retrieveNearbyRestaurants(_userLocation);
              }
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _userLocation,
                  zoom: 12,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  newGoogleMapController = controller;
                  locatePosition();
                },
                markers: markerSet,
                polylines: polyLineSet,
              );
            } else {
              return Center(child: Text("Failed to get user location."));
            }
          }
          // While the connection is not in the done state yet
          return Center(child: CircularProgressIndicator());
        });
  }

  void onError(PlacesAutocompleteResponse response) {
    homeScaffoldKey.currentState.showSnackBar(
      SnackBar(content: Text(response.errorMessage)),
    );
  }



  // ignore: missing_return
  // ListView buildPlacesList() {
  //   final placesWidget = places.map((f) {
  //     List<Widget> list = [
  //       Padding(
  //         padding: EdgeInsets.only(bottom: 4.0),
  //         child: Text(
  //           f.name,
  //           style: Theme
  //               .of(context)
  //               .textTheme
  //               .subtitle2,
  //         ),
  //       )
  //     ];
  //     if (f.formattedAddress != null) {
  //       list.add(Padding(
  //         padding: EdgeInsets.only(bottom: 2.0),
  //         child: Text(
  //           f.formattedAddress,
  //           style: Theme
  //               .of(context)
  //               .textTheme
  //               .subtitle2,
  //         ),
  //       ));
  //     }
  //
  //     if (f.vicinity != null) {
  //       list.add(Padding(
  //         padding: EdgeInsets.only(bottom: 2.0),
  //         child: Text(
  //           f.vicinity,
  //           style: Theme
  //               .of(context)
  //               .textTheme
  //               .bodyText2,
  //         ),
  //       ));
  //     }
  //
  //     if (f.types?.first != null) {
  //       list.add(Padding(
  //         padding: EdgeInsets.only(bottom: 2.0),
  //         child: Text(
  //           f.types.first,
  //           style: Theme
  //               .of(context)
  //               .textTheme
  //               .caption,
  //         ),
  //       ));
  //     }
  //
  //     return Padding(
  //       padding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
  //       child: Card(
  //         child: InkWell(
  //           onTap: () {
  //             showDetailPlace(f.placeId);
  //           },
  //           highlightColor: Colors.lightBlueAccent,
  //           splashColor: Colors.red,
  //           child: Padding(
  //             padding: EdgeInsets.all(8.0),
  //             child: Column(
  //               mainAxisAlignment: MainAxisAlignment.start,
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: list,
  //             ),
  //           ),
  //         ),
  //       ),
  //     );
  //   }).toList();
  //
  //   return ListView(shrinkWrap: true, children: placesWidget);
  // }

  Widget myDetailsContainer1(String restaurantName) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
              child: Text(
            restaurantName,
            style: TextStyle(
                color: Color(0xff6200ee),
                fontSize: 24.0,
                fontWeight: FontWeight.bold),
          )),
        ),
        SizedBox(height: 5.0),
        Container(
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Container(
                child: Text(
              "4.1",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 18.0,
              ),
            )),
            Container(
              child: Icon(
                FontAwesomeIcons.solidStar,
                color: Colors.amber,
                size: 15.0,
              ),
            ),
            Container(
              child: Icon(
                FontAwesomeIcons.solidStar,
                color: Colors.amber,
                size: 15.0,
              ),
            ),
            Container(
              child: Icon(
                FontAwesomeIcons.solidStar,
                color: Colors.amber,
                size: 15.0,
              ),
            ),
            Container(
              child: Icon(
                FontAwesomeIcons.solidStar,
                color: Colors.amber,
                size: 15.0,
              ),
            ),
            Container(
              child: Icon(
                FontAwesomeIcons.solidStarHalf,
                color: Colors.amber,
                size: 15.0,
              ),
            ),
            Container(
                child: Text(
              "(946)",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 18.0,
              ),
            )),
          ],
        )),
        SizedBox(height: 5.0),
        Container(
            child: Text(
          "Continental \u00B7 \u0024\u0024 \u00B7 1.6 mi",
          style: TextStyle(
            color: Colors.black54,
            fontSize: 18.0,
          ),
        )),
        SizedBox(height: 5.0),
        Container(
            child: Text(
          "Closed \u00B7 Opens 17:00 Thu",
          style: TextStyle(
              color: Colors.black54,
              fontSize: 18.0,
              fontWeight: FontWeight.bold),
        )),
      ],
    );
  }
}
