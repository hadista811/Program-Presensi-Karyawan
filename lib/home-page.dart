import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:presensi/models/home-response.dart';
import 'package:presensi/simpan-page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as myHttp;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _name, _token;
  HomeResponseModel? homeResponseModel;
  Datum? hariIni;
  List<Datum> riwayat = [];

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });

    _token.then((token) {
      if (token != "") {
        getData(token);
      }
    });
  }

  Future<void> getData(String token) async {
    final Map<String, String> headers = {
      'Authorization': 'Bearer $token'
    };
    var response = await myHttp.get(
        Uri.parse('http://127.0.0.1:8000/api/get-presensi'),
        headers: headers);
    if (response.statusCode == 200) {
      homeResponseModel = HomeResponseModel.fromJson(json.decode(response.body));
      riwayat.clear();
      for (var element in homeResponseModel!.data) {
        if (element.isHariIni) {
          hariIni = element;
        } else {
          riwayat.add(element);
        }
      }
      setState(() {}); // Memperbarui tampilan setelah data diambil
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data presensi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _token,
        builder: (context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder(
                      future: _name,
                      builder: (context, AsyncSnapshot<String> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        } else {
                          String name = snapshot.data ?? "-";
                          return Text(name, style: const TextStyle(fontSize: 18));
                        }
                      }
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 400,
                      decoration: BoxDecoration(color: Colors.blue[800]),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(hariIni?.tanggal ?? '-', style: const TextStyle(color: Colors.white, fontSize: 16)),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Text(hariIni?.masuk ?? '-', style: const TextStyle(color: Colors.white, fontSize: 24)),
                                    const Text("Masuk", style: TextStyle(color: Colors.white, fontSize: 16))
                                  ],
                                ),
                                Column(
                                  children: [
                                    Text(hariIni?.pulang ?? '-', style: const TextStyle(color: Colors.white, fontSize: 24)),
                                    const Text("Pulang", style: TextStyle(color: Colors.white, fontSize: 16))
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("Riwayat Presensi"),
                    Expanded(
                      child: ListView.builder(
                        itemCount: riwayat.length,
                        itemBuilder: (context, index) => Card(
                          child: ListTile(
                            leading: Text(riwayat[index].tanggal),
                            title: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(riwayat[index].masuk, style: const TextStyle(fontSize: 18)),
                                    const Text("Masuk", style: TextStyle(fontSize: 14))
                                  ],
                                ),
                                const SizedBox(width: 20),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(riwayat[index].pulang, style: const TextStyle(fontSize: 18)),
                                    const Text("Pulang", style: TextStyle(fontSize: 14))
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => const SimpanPage()))
              .then((value) {
            _token.then((token) {
              if (token != "") {
                getData(token);
              }
            });
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
