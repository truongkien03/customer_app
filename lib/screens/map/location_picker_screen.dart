import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:customer_app/models/address_model.dart';
import 'package:customer_app/widgets/custom_button.dart';
import 'dart:async';

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
  bool _mapReady = false;
  Timer? _debouncer;

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
    _initializeMap();
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      setState(() {
        _isLoading = true;
        _mapReady = false;
      });

      // Khởi tạo vị trí ban đầu
      if (widget.initialAddress != null) {
        _selectedLocation = LatLng(
          widget.initialAddress!.lat,
          widget.initialAddress!.lon,
        );
        _address = widget.initialAddress!.desc;
      } else {
        _selectedLocation = _vietnamCenter;
      }

      setState(() {
        _mapReady = true;
      });

      // Delay một chút để map render xong trước khi get current location
      await Future.delayed(const Duration(milliseconds: 500));

      if (widget.initialAddress == null) {
        _getCurrentLocationSafe();
      }
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _selectedLocation = _vietnamCenter;
        _mapReady = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _isLocationInVietnam(LatLng point) {
    return _vietnamBounds.contains(point);
  }

  Future<void> _getCurrentLocationSafe() async {
    // Chạy get location trong background để không block UI
    _getCurrentLocation().catchError((error) {
      print('Error getting location: $error');
      // Không cần hiển thị error, chỉ log và để mặc định là vietnam center
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // Kiểm tra quyền truy cập vị trí với timeout
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      // Lấy vị trí hiện tại với timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location timeout'),
      );

      if (!mounted) return;

      final location = LatLng(position.latitude, position.longitude);

      // Kiểm tra xem vị trí có trong Việt Nam không
      if (_isLocationInVietnam(location)) {
        setState(() {
          _selectedLocation = location;
        });

        // Chỉ move map nếu đã sẵn sàng
        if (_mapReady) {
          _mapController.move(location, _defaultZoom);
        }

        await _getAddressFromLatLng(location);
      } else {
        // Nếu không ở Việt Nam, di chuyển đến trung tâm Việt Nam
        _setDefaultLocation();
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        _showErrorSnackBar('Không thể lấy vị trí hiện tại');
        _setDefaultLocation();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  void _setDefaultLocation() {
    if (!mounted) return;

    setState(() {
      _selectedLocation = _vietnamCenter;
    });

    if (_mapReady) {
      _mapController.move(_vietnamCenter, _defaultZoom);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    if (!mounted) return;

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
        localeIdentifier: 'vi_VN',
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Geocoding timeout'),
      );

      if (!mounted) return;

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
        ].where((element) => element != null && element.isNotEmpty).join(', ');

        if (mounted) {
          setState(() {
            _address = address.isNotEmpty ? address : 'Vị trí đã chọn';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _address = 'Vị trí đã chọn';
          });
        }
      }
    } catch (e) {
      print('Error getting address: $e');
      if (mounted) {
        setState(() {
          _address = 'Vị trí đã chọn';
        });
      }
    }
  }

  void _onTapMap(TapPosition tapPosition, LatLng point) async {
    if (!_isLocationInVietnam(point)) {
      _showErrorSnackBar('Vui lòng chọn địa điểm trong lãnh thổ Việt Nam');
      return;
    }

    // Cancel previous debouncer
    _debouncer?.cancel();

    setState(() {
      _selectedLocation = point;
      _address = 'Đang tải địa chỉ...';
    });

    // Debounce địa chỉ lookup để tránh quá nhiều request
    _debouncer = Timer(const Duration(milliseconds: 500), () async {
      if (mounted) {
        setState(() => _isLoading = true);
        await _getAddressFromLatLng(point);
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    });
  }

  void _onSearchPressed() async {
    // Hiển thị dialog tìm kiếm
    final searchResult = await showDialog<String>(
      context: context,
      builder: (context) => _SearchDialog(),
    );

    if (searchResult != null && searchResult.isNotEmpty && mounted) {
      setState(() => _isLoading = true);
      try {
        // Thêm "Việt Nam" vào chuỗi tìm kiếm để ưu tiên kết quả trong Việt Nam
        final searchQuery = '$searchResult, Việt Nam';
        final locations = await locationFromAddress(searchQuery).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Search timeout'),
        );

        if (!mounted) return;

        if (locations.isNotEmpty) {
          final location = locations.first;
          final point = LatLng(location.latitude, location.longitude);

          if (_isLocationInVietnam(point)) {
            setState(() => _selectedLocation = point);
            if (_mapReady) {
              _mapController.move(point, _defaultZoom);
            }
            await _getAddressFromLatLng(point);
          } else {
            _showErrorSnackBar('Địa điểm không nằm trong lãnh thổ Việt Nam');
          }
        } else {
          _showErrorSnackBar('Không tìm thấy địa điểm');
        }
      } catch (e) {
        print('Search error: $e');
        if (mounted) {
          _showErrorSnackBar('Không tìm thấy địa điểm');
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
            onPressed: _mapReady ? _onSearchPressed : null,
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _mapReady ? () => _getCurrentLocationSafe() : null,
          ),
        ],
      ),
      body: _mapReady ? _buildMapContent() : _buildLoadingContent(),
    );
  }

  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang khởi tạo bản đồ...'),
        ],
      ),
    );
  }

  Widget _buildMapContent() {
    return Stack(
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
              // Thêm error tile để xử lý khi không load được tile
              errorTileCallback: (tile, error, stackTrace) {
                print('Error loading tile: $error');
              },
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
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Chọn vị trí này',
                    onPressed: () {
                      if (!_isLoading) {
                        Navigator.pop(
                          context,
                          AddressModel(
                            lat: _selectedLocation!.latitude,
                            lon: _selectedLocation!.longitude,
                            desc: _address,
                          ),
                        );
                      }
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
