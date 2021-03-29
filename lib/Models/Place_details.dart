import 'package:google_maps_webservice/places.dart';

class Place {
  String name;
  String placeId;
  List<Photo> photo;
  double lat;
  double lng;

  Place(
    this.name,
    this.placeId,
    this.photo,
    this.lat,
    this.lng,
  );
}