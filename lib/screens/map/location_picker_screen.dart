import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:customer_app/models/address_model.dart';
import 'package:customer_app/widgets/custom_button.dart';

class LocationPickerScreen extends StatefulWidget {
  final AddressModel? initialAddress;

  const LocationPickerScreen({
    Key? key,
    this.initialAddress,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedLocation;
  String _address = '';
  bool _isLoading = false;

  // Giới hạn vùng Việt Nam
  static final LatLng _vietnamCenter = LatLng(16.047079, 108.206230); // Đà Nẵng
  static const double _defaultZoom = 12.0;

  // Giới hạn vùng chọn địa điểm
  static final LatLngBounds _vietnamBounds = LatLngBounds(
    LatLng(8.18, 102.14), // Southwest point
    LatLng(23.39, 109.46), // Northeast point
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      _selectedLocation = LatLng(
        widget.initialAddress!.lat,
        widget.initialAddress!.lon,
      );
      _address = widget.initialAddress!.desc;
    }
    _getCurrentLocation();
  }

  bool _isLocationInVietnam(LatLng point) {
    return _vietnamBounds.contains(point);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      // Kiểm tra quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      // Lấy vị trí hiện tại
      final position = await Geolocator.getCurrentPosition();
      final location = LatLng(position.latitude, position.longitude);

      // Kiểm tra xem vị trí có trong Việt Nam không
      if (_isLocationInVietnam(location)) {
        setState(() {
          _selectedLocation = location;
        });
        _mapController.move(location, _defaultZoom);
        await _getAddressFromLatLng(location);
      } else {
        // Nếu không ở Việt Nam, di chuyển đến trung tâm Việt Nam
        setState(() {
          _selectedLocation = _vietnamCenter;
        });
        _mapController.move(_vietnamCenter, _defaultZoom);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      // Di chuyển đến trung tâm Việt Nam nếu có lỗi
      setState(() {
        _selectedLocation = _vietnamCenter;
      });
      _mapController.move(_vietnamCenter, _defaultZoom);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address = [
          if (place.subThoroughfare?.isNotEmpty ?? false) place.subThoroughfare,
          if (place.thoroughfare?.isNotEmpty ?? false) place.thoroughfare,
          if (place.subLocality?.isNotEmpty ?? false) place.subLocality,
          if (place.locality?.isNotEmpty ?? false) place.locality,
          if (place.administrativeArea?.isNotEmpty ?? false)
            place.administrativeArea,
          "Việt Nam"
        ].where((element) => element != null).join(', ');

        setState(() {
          _address = address;
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void _onTapMap(TapPosition tapPosition, LatLng point) async {
    if (!_isLocationInVietnam(point)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn địa điểm trong lãnh thổ Việt Nam'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _selectedLocation = point;
      _isLoading = true;
    });

    await _getAddressFromLatLng(point);
    setState(() => _isLoading = false);
  }

  void _onSearchPressed() async {
    // Hiển thị dialog tìm kiếm
    final searchResult = await showDialog<String>(
      context: context,
      builder: (context) => _SearchDialog(),
    );

    if (searchResult != null && searchResult.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        // Thêm "Việt Nam" vào chuỗi tìm kiếm để ưu tiên kết quả trong Việt Nam
        final searchQuery = '$searchResult, Việt Nam';
        final locations = await locationFromAddress(searchQuery);

        if (locations.isNotEmpty) {
          final location = locations.first;
          final point = LatLng(location.latitude, location.longitude);

          if (_isLocationInVietnam(point)) {
            setState(() => _selectedLocation = point);
            _mapController.move(point, _defaultZoom);
            await _getAddressFromLatLng(point);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Địa điểm không nằm trong lãnh thổ Việt Nam'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy địa điểm'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy địa điểm'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn vị trí'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _onSearchPressed,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation ?? _vietnamCenter,
              initialZoom: _defaultZoom,
              onTap: _onTapMap,
              // Giới hạn vùng có thể di chuyển
              cameraConstraint: CameraConstraint.contain(
                bounds: _vietnamBounds,
              ),
              minZoom: 5, // Giới hạn zoom out
              maxZoom: 18, // Giới hạn zoom in
              // Cho phép zoom bằng cử chỉ
              interactionOptions: const InteractionOptions(
                enableScrollWheel: true,
                enableMultiFingerGestureRace: true,
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.customer_app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              // Thêm nút điều khiển zoom
              Positioned(
                right: 16,
                bottom: _selectedLocation != null ? 200 : 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: "btn_zoom_in",
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        if (currentZoom < 18) {
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom + 1,
                          );
                        }
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: "btn_zoom_out",
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        if (currentZoom > 5) {
                          _mapController.move(
                            _mapController.camera.center,
                            currentZoom - 1,
                          );
                        }
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_selectedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _address,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: 'Chọn vị trí này',
                      onPressed: () {
                        Navigator.pop(
                          context,
                          AddressModel(
                            lat: _selectedLocation!.latitude,
                            lon: _selectedLocation!.longitude,
                            desc: _address,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchDialog extends StatelessWidget {
  final _searchController = TextEditingController();

  _SearchDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tìm kiếm địa chỉ'),
      content: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          hintText: 'Nhập địa chỉ cần tìm',
        ),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _searchController.text),
          child: const Text('Tìm kiếm'),
        ),
      ],
    );
  }
}
