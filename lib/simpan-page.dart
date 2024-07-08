import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as myHttp;
import 'package:location/location.dart';
import 'package:presensi/login-page.dart';
import 'package:presensi/models/auth_service.dart';
import 'package:presensi/models/save-presensi-response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class SimpanPage extends StatefulWidget {
  const SimpanPage({super.key});

  @override
  State<SimpanPage> createState() => _SimpanPageState();
}

class _SimpanPageState extends State<SimpanPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _token;

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });
  }

  Future<LocationData?> _currentLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    Location location = Location();

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return null;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    return await location.getLocation();
  }

 Future<void> savePresensi(double? latitude, double? longitude) async {
  if (latitude == null || longitude == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lokasi tidak valid')),
    );
    return;
  }

  try {
    String token = await _token;
    Map<String, String> body = {
      "latitude": latitude.toString(),
      "longitude": longitude.toString()
    };

    Map<String, String> headers = {'Authorization': 'Bearer $token'};

    var response = await myHttp.post(
      Uri.parse("http://127.0.0.1:8000/api/save-presensi"),
      body: body,
      headers: headers,
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      if (jsonResponse is Map<String, dynamic>) {
        SavePresensiResponseModel savePresensiResponseModel =
            SavePresensiResponseModel.fromJson(jsonResponse);

        if (savePresensiResponseModel.success) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sukses simpan Presensi')));
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Anda sudah melakukan Absen')));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Respon tidak valid dari server')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal terhubung ke server')));
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Terjadi kesalahan')));
  }
}

  void _logout() async {
    await AuthService().logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            const LoginPage(), // Ganti dengan halaman login Anda
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Presensi"),
      ),
      body: FutureBuilder<LocationData?>(
        future: _currentLocation(),
        builder: (BuildContext context, AsyncSnapshot<LocationData?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text('Error retrieving location'),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            final LocationData currentLocation = snapshot.data!;
            print(
                "Lokasi : ${currentLocation.latitude} | ${currentLocation.longitude}");
            return SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: SfMaps(
                      layers: [
                        MapTileLayer(
                          initialFocalLatLng: MapLatLng(
                              currentLocation.latitude!,
                              currentLocation.longitude!),
                          initialZoomLevel: 15,
                          initialMarkersCount: 1,
                          urlTemplate:
                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          markerBuilder: (BuildContext context, int index) {
                            return MapMarker(
                              latitude: currentLocation.latitude!,
                              longitude: currentLocation.longitude!,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                              ),
                            );
                          },
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      savePresensi(
                          currentLocation.latitude, currentLocation.longitude);
                    },
                    child: const Text("Simpan Presensi"),
                  ),
                  const SizedBox(height: 100),
                  ElevatedButton(
                      onPressed: () {
                        _logout();
                      },
                      child: const Text('logout'))
                ],
              ),
            );
          } else {
            return const Center(
              child: Text('Tidak dapat menemukan lokasi'),
            );
          }
        },
      ),
    );
  }
}
