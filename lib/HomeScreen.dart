import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import "package:geolocator/geolocator.dart";
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:weather_app/Methods.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? temperature;
  var minTemperatureForecast = List<dynamic>.filled(7, 0, growable: false);
  var maxTemperatureForecast = List<dynamic>.filled(7, 0, growable: false);
  String location = 'Dhaka';
  int woeid = 1915035;
  String weather = 'clear';
  String abbrevation = '';
  var abbreviationForecast = List<dynamic>.filled(7, 0, growable: false);
  String errorMessage = '';

  Position? _currentPosition;
  String? _currentAddress;

  //final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;

  String searchApiUrl =
      'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  get geocoding => null;

  @override
  void initState() {
    super.initState();
    fetchLocation();
    fetchLocationDay();
    getLocation1();
  }

  getLocation1() async {
    _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      printLocation();
    } else {
      requestPermission();
    }
  }

  requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      printLocation();
    } else {
      requestPermission();
    }
  }

  printLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10));
    print(position);
  }

  fetchSearch(String input) async {
    try {
      var searchResult = await http.get(Uri.parse(searchApiUrl + input));
      var result = json.decode(searchResult.body)[0];

      setState(() {
        location = result["title"];
        woeid = result["woeid"];
        errorMessage = '';
      });
    } catch (error) {
      errorMessage =
          "Sorry, we don't have data about this city. thy another one";
    }
  }

  fetchLocation() async {
    var locationResult =
        await http.get(Uri.parse(locationApiUrl + woeid.toString()));
    var result = json.decode(locationResult.body);
    var consolidated_weather = result["consolidated_weather"];
    var data = consolidated_weather[0];

    setState(() {
      temperature = data["the_temp"].round();
      weather = data["weather_state_name"].replaceAll(' ', '').toLowerCase();
      abbrevation = data["weather_state_abbr"];
    });
  }

  fetchLocationDay() async {
    var today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(Uri.parse(locationApiUrl +
          woeid.toString() +
          '/' +
          DateFormat('y/M/d')
              .format(today.add(Duration(days: i + 1)))
              .toString()));
      var result = json.decode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data["min_temp"].round();
        maxTemperatureForecast[i] = data["max_temp"].round();
        abbreviationForecast[i] = data["weather_state_abbr"];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
    await fetchLocationDay();
  }

  _getCurrentLocation() {
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
      });
      _getAddressFromLatLng();
    }).catchError((e) {
      print(e);
    });
  }

  _getAddressFromLatLng() async {
    try {
      List<Placemark> p = await geocoding.placemarkFromCoordinates(
          _currentPosition?.latitude, _currentPosition?.longitude);

      Placemark place = p[0];

      setState(() {
        _currentAddress =
            "${place.locality}, ${place.postalCode}, ${place.country}";
      });
      onTextFieldSubmitted((place.locality).toString());
      print(place.locality);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Container(
      decoration: BoxDecoration(
          image: DecorationImage(
        image: AssetImage('images/$weather.png'),
        fit: BoxFit.cover,
        colorFilter:
            ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.dstATop),
      )),
      child: temperature == null
          ? const Center(child: CircularProgressIndicator())
          : Scaffold(
              appBar: AppBar(
                actions: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(right: 305.0),
                    child: GestureDetector(
                      onTap: () => logOut(context),
                      child: const Icon(Icons.logout_outlined, size: 36.0),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: GestureDetector(
                      onTap: () {
                        getLocation();
                        _getCurrentLocation();
                      },
                      child: const Icon(Icons.location_city, size: 36.0),
                    ),
                  ),
                ],
                backgroundColor: Colors.transparent,
                elevation: 00,
              ),
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              body: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      Center(
                        child: Image.network(
                          'https://www.metaweather.com/static/img/weather/png/' +
                              abbrevation +
                              '.png',
                          width: 100,
                        ),
                      ),
                      Center(
                        child: Text(
                          temperature.toString() + '°C',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 60.0),
                        ),
                      ),
                      Center(
                        child: Text(
                          location,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 40.0),
                        ),
                      )
                    ],
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        forecastElement(
                            1,
                            abbreviationForecast[0].toString(),
                            minTemperatureForecast[0].toString(),
                            maxTemperatureForecast[0]),
                        forecastElement(
                            2,
                            abbreviationForecast[1].toString(),
                            minTemperatureForecast[1].toString(),
                            maxTemperatureForecast[1]),
                        forecastElement(
                            3,
                            abbreviationForecast[2].toString(),
                            minTemperatureForecast[2].toString(),
                            maxTemperatureForecast[2]),
                        forecastElement(
                            4,
                            abbreviationForecast[3].toString(),
                            minTemperatureForecast[3].toString(),
                            maxTemperatureForecast[3]),
                        forecastElement(
                            5,
                            abbreviationForecast[4].toString(),
                            minTemperatureForecast[4].toString(),
                            maxTemperatureForecast[4]),
                        forecastElement(
                            6,
                            abbreviationForecast[5].toString(),
                            minTemperatureForecast[5].toString(),
                            maxTemperatureForecast[5]),
                        forecastElement(
                            7,
                            abbreviationForecast[6].toString(),
                            minTemperatureForecast[6].toString(),
                            maxTemperatureForecast[6]),
                      ],
                    ),
                  ),
                  Column(
                    children: <Widget>[
                      SizedBox(
                        width: 300,
                        child: TextField(
                          onSubmitted: (String input) {
                            onTextFieldSubmitted(input);
                          },
                          style: const TextStyle(
                              color: Colors.white, fontSize: 25.0),
                          decoration: const InputDecoration(
                            hintText: 'Search another location...',
                            hintStyle:
                                TextStyle(color: Colors.white, fontSize: 18),
                            prefixIcon: Icon(Icons.search, color: Colors.white),
                          ),
                        ),
                      ),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: Platform.isAndroid ? 15.0 : 20.0),
                      )
                    ],
                  )
                ],
              ),
            ),
    ));
  }
}

Widget forecastElement(
    daysFromNow, abbreviation, minTemperature, maxTemperature) {
  var now = DateTime.now();
  var oneDayFromNow = now.add(Duration(days: daysFromNow));
  return Padding(
    padding: const EdgeInsets.only(left: 16.0),
    child: Container(
      decoration: BoxDecoration(
        color: const Color.fromRGBO(205, 212, 228, 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              DateFormat.E().format(oneDayFromNow),
              style: const TextStyle(color: Colors.white, fontSize: 25),
            ),
            Text(
              DateFormat.MMMd().format(oneDayFromNow),
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: Image.network(
                  'https://www.metaweather.com/static/img/weather/png/' +
                      abbreviation +
                      '.png',
                  width: 50,
                ),
              ),
            ),
            Text(
              'High: ' + maxTemperature.toString() + ' °C',
              style: const TextStyle(color: Colors.white, fontSize: 20.0),
            ),
            Text(
              'Low: ' + minTemperature.toString() + ' °C',
              style: const TextStyle(color: Colors.white, fontSize: 20.0),
            ),
          ],
        ),
      ),
    ),
  );
}
