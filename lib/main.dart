import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
// ignore: unnecessary_new

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(title: 'Map Page'),
    );
  }
}

class MapSample extends StatefulWidget {
  MapSample({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  //구글 맵의 움직임을 컨트롤 하는 변수
  // late키워드는 값의 초기화를 뒤로 미룸. null 실수로 사용 방지
  late GoogleMapController _controller;

  Marker? marker;
  Circle? circle;
  final Location _locationTracker = Location();
  StreamSubscription? _locationSubscription;

  static late CameraPosition _initialPosition;
  var initLocationData;

  //초기 기기의 좌표를 가져오는 함수
  Future<CameraPosition> getInitCoordinate() async {
    LocationData initData = await _locationTracker.getLocation();
    LatLng startPoint = LatLng(initData.latitude!, initData.longitude!);
    _initialPosition = CameraPosition(target: startPoint, zoom: 17);
    return _initialPosition;
  }

  // 현재 기기의 좌표에 마커와 원을 그리는 함수
  void updateMarkerAndCircle(LocationData newLocalData) {
    LatLng latlng = LatLng(newLocalData.latitude!, newLocalData.longitude!);
    setState(() {
      marker = Marker(
          markerId: const MarkerId("home"),
          position: latlng,
          draggable: false,
          zIndex: 2,
          icon: BitmapDescriptor.defaultMarker);
      circle = Circle(
          circleId: const CircleId("car"),
          radius: newLocalData.accuracy!,
          zIndex: 1,
          strokeColor: Colors.blue,
          center: latlng,
          fillColor: Colors.blue.withAlpha(50));
    });
  }

  // 버튼 클릭 시 현재 기기의 좌표로 이동하는 함수
  void getCurrentLocation() async {
    try {
      var location = await _locationTracker.getLocation();
      updateMarkerAndCircle(location);
      if (_locationSubscription != null) {
        _locationSubscription!.cancel();
      }
      _locationSubscription =
          _locationTracker.onLocationChanged.listen((newLocalData) {
        if (_controller != null) {
          _controller.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(newLocalData.latitude!, newLocalData.longitude!),
              tilt: 0,
              zoom: 15.00,
            ),
          ));
          updateMarkerAndCircle(newLocalData);
        }
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      }
    }
  }

  // initState는 위젯의 생명주기에서 한번만 실행됨
  @override
  void initState() {
    initLocationData = getInitCoordinate();
    if (initLocationData == null) {
      // ! 좌표 못찾을 경우 에러처리
    }
    super.initState();
  }

  // 위젯이 생명주기가 끝나고 종료될 때 실행, 주로 메모리에서 해제할 것들
  @override
  void dispose() {
    if (_locationSubscription != null) {
      _locationSubscription!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track order",
            style: TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder(
          future: initLocationData,
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            _initialPosition = snapshot.data;
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _initialPosition,
                  markers: Set.of((marker != null) ? [marker!] : []),
                  circles: Set.of((circle != null) ? [circle!] : []),
                  onMapCreated: (GoogleMapController controller) {
                    _controller = controller;
                  },
                  zoomControlsEnabled: false,
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: FloatingActionButton(
                    child: const Icon(Icons.location_searching),
                    onPressed: () {
                      getCurrentLocation();
                    },
                  ),
                )
              ]);
            } else if (snapshot.connectionState == snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(fontSize: 15),
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}
