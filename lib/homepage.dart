import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? temperature;
  String location = 'Jakarta';
  String? weather;

  // kode unik untuk kota tertentu
  int woeid = 1047378;

  // api url
  String searchApiUrl = 'https://www.metaweather.com/api/location/search/?query=';
  String locationApiUrl = 'https://www.metaweather.com/api/location/';

  // variabel untuk icon dan error message
  String abbreviation = '';
  String errorMessage = '';
  
  // variabel untuk list temperature
  var minTemperatureForecast = List.filled(7, 0);
  var maxTemperatureForecast = List.filled(7, 0);
  var abbreviationForecast = List.filled(7, '');

  Future<void> fetchSearch(String input) async {
    try {
      var searchResult = await http.get(Uri.parse(searchApiUrl + input));
      var result = jsonDecode(searchResult.body)[0];

      setState(() {
        location = result['title'];
        woeid = result['woeid'];
        errorMessage = '';
      });
    } catch (error) {
      print(error);
      setState(() {
        errorMessage = 'Kota yang anda cari tidak ditemukan.';
      });
    }
  }

  Future<void> fetchLocation() async {
    var locationResult =
        await http.get(Uri.parse(locationApiUrl + woeid.toString()));
    var result = jsonDecode(locationResult.body);
    var consolidatedWeather = result['consolidated_weather'];
    var data = consolidatedWeather[0];

    setState(() {
      temperature = (data['the_temp'] as num).round();
      weather = data['weather_state_name'].replaceAll(' ', '').toLowerCase();
      abbreviation = data['weather_state_abbr'];
    });
  }

  Future<void> fetchSevenDays() async {
    var today = DateTime.now();
    for (var i = 0; i < 7; i++) {
      var locationDayResult = await http.get(Uri.parse(
        locationApiUrl + woeid.toString() + '/' + DateFormat('y/M/d').format(
            today.add(Duration(days: i + 1))
        ).toString()
      ));
      var result = jsonDecode(locationDayResult.body);
      var data = result[0];

      setState(() {
        minTemperatureForecast[i] = data['min_temp'].round();
        maxTemperatureForecast[i] = data['max_temp'].round();
        abbreviationForecast[i] = data['weather_state_abbr'];
      });
    }
  }

  void onTextFieldSubmitted(String input) async {
    await fetchSearch(input);
    await fetchLocation();
    await fetchSevenDays();
  }

  @override
  void initState() {
    super.initState();
    fetchLocation();
    fetchSevenDays();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/$weather.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.6),
            BlendMode.dstATop
          )
        )
      ),
      child: temperature == null ? const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator()
        )) : Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100),
          child: Column(
            children: [
              Column(
                children: [
                  Center(
                    child: Image.network(
                      'https://www.metaweather.com/static/img/weather/png/$abbreviation.png',
                      width: 100,
                      color: Colors.white
                    ),
                  ),
                  Center(
                    child: Text(
                      temperature.toString() + ' °C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 60
                      )
                    )
                  ),
                  Center(
                    child: Text(
                        location,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40
                        )
                    )
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top:50),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (var i = 0; i < 7; i++)
                            forecastElement(
                              i + 1,
                              abbreviationForecast[i],
                              maxTemperatureForecast[i],
                              minTemperatureForecast[i]
                            )
                        ],
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 300,
                        child: TextField(
                          onSubmitted: (String input) {
                            onTextFieldSubmitted(input);
                          },
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search location...',
                            hintStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 18
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white
                            )
                          )
                        )
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 15
                      )
                    ),
                  )
                ]
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget forecastElement(daysFromNow, abbreviation, maxTemp, minTemp) {
    var now = DateTime.now();
    var oneDayFromNow = now.add(Duration(days: daysFromNow));
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(285, 212, 228, 8.2),
          borderRadius: BorderRadius.circular(10.0)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                DateFormat.E().format(oneDayFromNow),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 25
                ),
              ),
              Text(
                DateFormat.MMMd().format(oneDayFromNow),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20
                )
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Image.network(
                  'https://www.metaweather.com/static/img/weather/png/$abbreviation.png',
                  width: 50.0
                ),
              ),
              Text(
                'High $maxTemp °C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20
                ),
              ),
              Text(
                'Min $minTemp °C',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20
                ),
              ),
            ]
          ),
        ),
      ),
    );
  }
}
