import 'dart:convert';

import 'package:earthquake/models/earthquake_model.dart';
import 'package:earthquake/utils/helper_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as gc;
import 'package:http/http.dart' as http;

class AppDataProvider with ChangeNotifier {
  final baseUrl = Uri.parse('https://earthquake.usgs.gov/fdsnws/event/1/query');
  Map<String, dynamic> queryParams = {};
  double _maxRadiusKm = 500;
  double _latitude = 0.0, _longitude = 0.0;
  String _startTime = '', _endTime = '';
  String _orderBy = 'time';
  String? _currentCity;
  final double _maxRadiusKmThreshold = 20001.6;
  bool _shouldUseLocation = false;
  EarthquakeModel? earthquakeModel;
  int _minMagnitude = 4;

  double get maxRadiusKm => _maxRadiusKm;

  double get latitude => _latitude;

  get longitude => _longitude;

  String get startTime => _startTime;

  get endTime => _endTime;

  String get orderBy => _orderBy;

  String? get currentCity => _currentCity;

  double get maxRadiusKmThreshold => _maxRadiusKmThreshold;

  bool get shouldUseLocation => _shouldUseLocation;

  bool get hasDataLoaded => earthquakeModel != null;


  int get minMagnitude => _minMagnitude;

  set minMagnitude(int value) {
    _minMagnitude = value;
    _setQueryParams();
    notifyListeners();
  }

  set orderBy(String value) {
    _orderBy = value;
    notifyListeners();
    _setQueryParams();
    getEarthquakeData();
  }

  set startTime(String value) {
    _startTime = value;
    _setQueryParams();
    notifyListeners();
  }

  set endTime(value) {
    _endTime = value;
    _setQueryParams();
    notifyListeners();
  }

  set shouldUseLocation(bool value) {
    _shouldUseLocation = value;
    notifyListeners();
  }


  set maxRadiusKm(double value) {
    _maxRadiusKm = value;
    notifyListeners();
  }

  _setQueryParams() {
    queryParams['format'] = 'geojson';
    queryParams['starttime'] = startTime;
    queryParams['endtime'] = endTime;
    queryParams['minmagnitude'] = '$minMagnitude';
    queryParams['orderby'] = orderBy;
    queryParams['limit'] = '500';
    queryParams['latitude'] = '$latitude';
    queryParams['longitude'] = '$longitude';
    queryParams['maxradiuskm'] = '$maxRadiusKm';
  }

  init() {
    _startTime = getFormattedDateTime(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch);
    _endTime = getFormattedDateTime(DateTime.now().millisecondsSinceEpoch);
    _maxRadiusKm = maxRadiusKmThreshold;
    _setQueryParams();
    getEarthquakeData();
  }

  Color getAlertColor(String color) {
    return switch (color) {
      'green' => Colors.green,
      'yellow' => Colors.yellow,
      'orange' => Colors.orange,
      _ => Colors.green
    };
  }

  Future<void> getEarthquakeData() async {
    final uri = Uri.https(baseUrl.authority, baseUrl.path, queryParams);
    print(uri.toString());
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        earthquakeModel = EarthquakeModel.fromJson(json);
        notifyListeners();
      }
    } catch (error) {
      print(error.toString());
    }
  }

  Future<void> setLocation(bool value) async {
    shouldUseLocation = value;
    if (value) {
      final position = await _determinePosition();
      _latitude = position.latitude;
      _longitude = position.longitude;
      _getCurrentCity();
      _maxRadiusKm = 500;
      _setQueryParams();
      getEarthquakeData();
    } else{
      _longitude = 0.0;
      _longitude = 0.0;
      _maxRadiusKm = _maxRadiusKmThreshold;
      _currentCity = null;
      _setQueryParams();
      getEarthquakeData();
    }
  }

  Future<void> _getCurrentCity() async {
    try {
      final placeMarkList = await gc.placemarkFromCoordinates(latitude, longitude);
      if(placeMarkList.isNotEmpty){
        final placemark = placeMarkList.first;
        _currentCity = placemark.locality;
        print(placeMarkList.first);
        notifyListeners();
      }
    } catch (error) {
      print(error);
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
