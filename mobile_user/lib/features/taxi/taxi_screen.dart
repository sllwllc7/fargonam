// 2026-08-20: Yandex MapKit vaqtincha o'chirilgan (APK ~71MB kamaytirish
// uchun, taksi hali 2-bosqich funksiyasi — hozir TaxiComingSoonScreen
// ko'rsatiladi, bu fayl app_shell.dart'dan chaqirilmaydi). Butun fayl
// pastda kommentariyga o'ralgan — o'zgartirilmagan, faqat "// " prefiksi
// qo'shilgan. Qaytarish: PROGRESS.md "Taksi qaytarish" bo'limiga qara.
// import 'dart:async';
// import 'dart:ui' as ui;
// 
// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:yandex_mapkit/yandex_mapkit.dart' as ymk;
// 
// import '../../core/api_client.dart';
// import '../../core/theme/app_colors.dart';
// import '../../core/widgets.dart';
// import '../../core/ws_service.dart';
// import '../addresses/addresses_screen.dart';
// import 'address_search.dart';
// import 'route_service.dart';
// 
// // Farg'ona shahar markazi (GPS olinmaguncha default)
// const _ferghanaCenter = LatLng(40.3842, 71.7872);
// 
// // LatLng (latlong2) → ymk.Point konvertor
// ymk.Point _toPoint(LatLng ll) =>
//     ymk.Point(latitude: ll.latitude, longitude: ll.longitude);
// 
// /// Yumaloq marker iconini Canvas yordamida yasash.
// /// Yandex MapKit native rendering ishlatadi, shuning uchun bitmap kerak.
// Future<ymk.BitmapDescriptor> _circleMarker({
//   required Color color,
//   required IconData icon,
//   double size = 110,
// }) async {
//   final recorder = ui.PictureRecorder();
//   final canvas = Canvas(recorder);
//   final center = Offset(size / 2, size / 2);
// 
//   // Tashqi glow halqasi
//   final glowPaint = Paint()..color = color.withValues(alpha: 0.28);
//   canvas.drawCircle(center, size / 2, glowPaint);
// 
//   // Asosiy doira
//   final solidPaint = Paint()..color = color;
//   canvas.drawCircle(center, size / 3.2, solidPaint);
// 
//   // Oq border
//   final borderPaint = Paint()
//     ..color = Colors.white
//     ..style = PaintingStyle.stroke
//     ..strokeWidth = 7;
//   canvas.drawCircle(center, size / 3.2, borderPaint);
// 
//   // Ikon
//   final iconChar = String.fromCharCode(icon.codePoint);
//   final tp = TextPainter(
//     text: TextSpan(
//       text: iconChar,
//       style: TextStyle(
//         fontSize: size / 2.6,
//         fontFamily: icon.fontFamily,
//         package: icon.fontPackage,
//         color: Colors.white,
//       ),
//     ),
//     textDirection: TextDirection.ltr,
//   )..layout();
//   tp.paint(canvas, Offset((size - tp.width) / 2, (size - tp.height) / 2));
// 
//   final picture = recorder.endRecording();
//   final image = await picture.toImage(size.toInt(), size.toInt());
//   final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
//   if (bytes == null) throw Exception('Marker ikon yaratishda xato: bytes null');
//   return ymk.BitmapDescriptor.fromBytes(bytes.buffer.asUint8List());
// }
// 
// /// Bitta marta yasalib, qayta ishlatish uchun cache qilinadi
// class _MarkerIcons {
//   static ymk.BitmapDescriptor? pickup;
//   static ymk.BitmapDescriptor? destination;
//   static ymk.BitmapDescriptor? driver;
// 
//   static Future<void> ensureLoaded() async {
//     pickup ??= await _circleMarker(
//         color: AppColors.success, icon: Icons.my_location);
//     destination ??= await _circleMarker(
//         color: AppColors.error, icon: Icons.location_on);
//     driver ??= await _circleMarker(
//         color: const Color(0xFFC77B1E), icon: Icons.local_taxi);
//   }
// }
// 
// /// GPS holatini bildiruvchi enum.
// enum GpsState { idle, loading, ok, denied, disabled }
// 
// /// GPS joylashuvni olish — natija va holatni qaytaradi.
// Future<({LatLng location, GpsState state})> _getCurrentLocation() async {
//   final enabled = await Geolocator.isLocationServiceEnabled();
//   if (!enabled) return (location: _ferghanaCenter, state: GpsState.disabled);
// 
//   var perm = await Geolocator.checkPermission();
//   if (perm == LocationPermission.denied) {
//     perm = await Geolocator.requestPermission();
//     if (perm == LocationPermission.denied) {
//       return (location: _ferghanaCenter, state: GpsState.denied);
//     }
//   }
//   if (perm == LocationPermission.deniedForever) {
//     return (location: _ferghanaCenter, state: GpsState.denied);
//   }
// 
//   try {
//     final pos = await Geolocator.getCurrentPosition(
//       locationSettings: const LocationSettings(
//           accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
//     );
//     return (location: LatLng(pos.latitude, pos.longitude), state: GpsState.ok);
//   } catch (_) {
//     return (location: _ferghanaCenter, state: GpsState.disabled);
//   }
// }
// 
// final activeRideProvider =
//     FutureProvider<Map<String, dynamic>?>((ref) async {
//   final res = await ref.watch(dioProvider).get('/rides/my',
//       queryParameters: {'active_only': true});
//   final list = (res.data as List).cast<Map<String, dynamic>>();
//   return list.isNotEmpty ? list.first : null;
// });
// 
// // ── Tariflar ────────────────────────────────────────────────
// 
// class _Tariff {
//   final String id;
//   final String name;
//   final String subtitle;
//   final IconData icon;
//   final double multiplier;
//   const _Tariff({
//     required this.id,
//     required this.name,
//     required this.subtitle,
//     required this.icon,
//     required this.multiplier,
//   });
// }
// 
// const _tariffs = <_Tariff>[
//   _Tariff(
//       id: 'econom',
//       name: 'Econom',
//       subtitle: 'Tez va arzon',
//       icon: Icons.directions_car,
//       multiplier: 1.0),
//   _Tariff(
//       id: 'comfort',
//       name: 'Komfort',
//       subtitle: 'Yangi mashinalar',
//       icon: Icons.airline_seat_recline_normal,
//       multiplier: 1.3),
//   _Tariff(
//       id: 'business',
//       name: 'Biznes',
//       subtitle: 'Premium sinf',
//       icon: Icons.local_taxi,
//       multiplier: 1.8),
// ];
// 
// // ══════════════════════════════════════════════════════════════
// // ASOSIY EKRAN
// // ══════════════════════════════════════════════════════════════
// 
// class TaxiScreen extends ConsumerStatefulWidget {
//   const TaxiScreen({super.key});
//   @override
//   ConsumerState<TaxiScreen> createState() => _TaxiScreenState();
// }
// 
// class _TaxiScreenState extends ConsumerState<TaxiScreen> {
//   bool _ratingShown = false;
//   int? _lastActiveRideId;
// 
//   @override
//   Widget build(BuildContext context) {
//     final rideAsync = ref.watch(activeRideProvider);
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       body: rideAsync.when(
//         loading: () => const Center(
//             child: CircularProgressIndicator(color: AppColors.success)),
//         error: (e, _) => ErrorRetryWidget(
//           error: e,
//           onRetry: () => ref.invalidate(activeRideProvider),
//         ),
//         data: (activeRide) {
//           // AnimatedSwitcher orqali request ↔ active ride silliq almashinishi
//           return AnimatedSwitcher(
//             duration: const Duration(milliseconds: 350),
//             switchInCurve: Curves.easeOutCubic,
//             switchOutCurve: Curves.easeInCubic,
//             transitionBuilder: (child, anim) => FadeTransition(
//               opacity: anim,
//               child: SlideTransition(
//                 position: Tween<Offset>(
//                   begin: const Offset(0, 0.05),
//                   end: Offset.zero,
//                 ).animate(anim),
//                 child: child,
//               ),
//             ),
//             child: () {
//               if (activeRide != null) {
//                 _lastActiveRideId = activeRide['id'] as int;
//                 _ratingShown = false;
//                 return _ActiveRideView(
//                   key: ValueKey('active_${activeRide['id']}'),
//                   ride: activeRide,
//                 );
//               }
//               if (_lastActiveRideId != null && !_ratingShown) {
//                 _ratingShown = true;
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   _showRatingDialog(_lastActiveRideId!);
//                 });
//               }
//               return const _RequestRideView(key: ValueKey('request'));
//             }(),
//           );
//         },
//       ),
//     );
//   }
// 
//   Future<void> _showRatingDialog(int rideId) async {
//     int rating = 0;
//     final result = await showDialog<int>(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => StatefulBuilder(
//         builder: (ctx, setDialogState) => AlertDialog(
//           backgroundColor: AppColors.surface,
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(24)),
//           title: const Row(
//             children: [
//               Icon(Icons.celebration, color: AppColors.success),
//               SizedBox(width: 10),
//               Text('Sayohat tugadi!'),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text('Haydovchini baholang:',
//                   style: TextStyle(color: AppColors.textSecondary)),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(
//                   5,
//                   (i) => GestureDetector(
//                     onTap: () {
//                       HapticFeedback.selectionClick();
//                       setDialogState(() => rating = i + 1);
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 4),
//                       child: AnimatedScale(
//                         scale: i < rating ? 1.15 : 1.0,
//                         duration: const Duration(milliseconds: 180),
//                         child: Icon(
//                           i < rating ? Icons.star : Icons.star_border,
//                           color: Colors.amber,
//                           size: 42,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(ctx, 0),
//               child: const Text("O'tkazish"),
//             ),
//             FilledButton(
//               onPressed:
//                   rating > 0 ? () => Navigator.pop(ctx, rating) : null,
//               child: const Text('Baholash'),
//             ),
//           ],
//         ),
//       ),
//     );
// 
//     if (result != null && result > 0) {
//       try {
//         await ref
//             .read(dioProvider)
//             .post('/ride-ratings/$rideId', data: {'rating': result});
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//                 content: Text('Rahmat! Bahoyingiz saqlandi'),
//                 backgroundColor: AppColors.success,
//                 duration: Duration(milliseconds: 1600)),
//           );
//         }
//       } catch (_) {}
//     }
//     _lastActiveRideId = null;
//   }
// }
// 
// // ══════════════════════════════════════════════════════════════
// // TAKSI CHAQIRISH EKRANI
// // ══════════════════════════════════════════════════════════════
// 
// class _RequestRideView extends ConsumerStatefulWidget {
//   const _RequestRideView({super.key});
//   @override
//   ConsumerState<_RequestRideView> createState() => _RequestRideViewState();
// }
// 
// class _RequestRideViewState extends ConsumerState<_RequestRideView>
//     with TickerProviderStateMixin {
//   final _pickupCtrl = TextEditingController();
//   final _destCtrl = TextEditingController();
//   final _sheetCtrl = DraggableScrollableController();
// 
//   ymk.YandexMapController? _mapCtrl;
// 
//   bool _loading = false;
//   String? _error;
// 
//   // GPS / joylashuv
//   LatLng _myLocation = _ferghanaCenter;
//   GpsState _gpsState = GpsState.loading;
// 
//   // Manzillar
//   LatLng? _destLocation;
//   List<LatLng>? _routePoints;
// 
//   // Hisob
//   double? _baseFare;       // backend'dan kelgan asosiy narx
//   double? _distanceKm;
//   int? _durationMin;
//   bool _estimating = false;
// 
//   // Tarif
//   String _selectedTariff = 'econom';
// 
//   // Animatsiya — swap tugmasi
//   late final AnimationController _swapCtrl;
// 
//   @override
//   void initState() {
//     super.initState();
//     _swapCtrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 300));
//     _MarkerIcons.ensureLoaded().then((_) {
//       if (mounted) setState(() {});
//     });
//     _loadLocation();
//   }
// 
//   Future<void> _loadLocation() async {
//     setState(() => _gpsState = GpsState.loading);
//     final res = await _getCurrentLocation();
//     if (!mounted) return;
//     setState(() {
//       _myLocation = res.location;
//       _gpsState = res.state;
//     });
//     await _mapCtrl?.moveCamera(
//       ymk.CameraUpdate.newCameraPosition(
//         ymk.CameraPosition(target: _toPoint(res.location), zoom: 15),
//       ),
//       animation: const ymk.MapAnimation(
//           type: ymk.MapAnimationType.smooth, duration: 0.4),
//     );
// 
//     // Reverse geocoding — pickup nomini avtomatik to'ldirish
//     if (res.state == GpsState.ok && _pickupCtrl.text.isEmpty) {
//       final name = await NominatimService.reverse(
//           res.location.latitude, res.location.longitude);
//       if (mounted && name != null && _pickupCtrl.text.isEmpty) {
//         final short = name.split(',').take(2).join(',').trim();
//         setState(() => _pickupCtrl.text = short);
//       }
//     }
//   }
// 
//   @override
//   void dispose() {
//     _pickupCtrl.dispose();
//     _destCtrl.dispose();
//     _swapCtrl.dispose();
//     _sheetCtrl.dispose();
//     super.dispose();
//   }
// 
//   /// Koordinatalar bilan narx + marshrut hisoblash
//   Future<void> _estimateWithCoords() async {
//     if (_destLocation == null) return;
//     setState(() => _estimating = true);
// 
//     // OSRM marshrut + backend narx parallel
//     final routeFuture = RouteService.getRoute(_myLocation, _destLocation!);
//     final fareFuture = ref.read(dioProvider).get('/rides/estimate',
//         queryParameters: {
//           'pickup_lat': _myLocation.latitude,
//           'pickup_lng': _myLocation.longitude,
//           'dest_lat': _destLocation!.latitude,
//           'dest_lng': _destLocation!.longitude,
//         });
// 
//     try {
//       final res = await fareFuture;
//       if (mounted) {
//         setState(() {
//           final fareStr = res.data['fare']?.toString();
//           _baseFare = fareStr != null ? double.tryParse(fareStr) : null;
//           _distanceKm = (res.data['distance_km'] as num?)?.toDouble();
//         });
//       }
//     } catch (e) {
//       debugPrint('Narx hisoblashda xato: $e');
//     }
// 
//     final route = await routeFuture;
//     if (route != null && mounted) {
//       setState(() {
//         _routePoints = route.points;
//         _durationMin = route.durationMin;
//         _distanceKm = route.distanceKm;
//       });
//       _fitMapToRoute();
//     }
// 
//     if (mounted) setState(() => _estimating = false);
//   }
// 
//   /// Xaritada ikkala nuqta + marshrut ko'rinishi
//   Future<void> _fitMapToRoute() async {
//     if (_destLocation == null || _mapCtrl == null) return;
//     final points = <ymk.Point>[
//       _toPoint(_myLocation),
//       _toPoint(_destLocation!),
//       if (_routePoints != null) ..._routePoints!.map(_toPoint),
//     ];
//     await _mapCtrl!.moveCamera(
//       ymk.CameraUpdate.newGeometry(
//         ymk.Geometry.fromPolyline(ymk.Polyline(points: points)),
//       ),
//       animation: const ymk.MapAnimation(
//           type: ymk.MapAnimationType.smooth, duration: 0.6),
//     );
//   }
// 
//   Future<void> _submit() async {
//     if (_pickupCtrl.text.trim().length < 3 ||
//         _destCtrl.text.trim().length < 3) {
//       setState(() => _error = 'Ikkala manzilni ham kiriting');
//       HapticFeedback.heavyImpact();
//       return;
//     }
//     HapticFeedback.mediumImpact();
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       await ref.read(dioProvider).post('/rides', data: {
//         'pickup_address': _pickupCtrl.text.trim(),
//         'destination_address': _destCtrl.text.trim(),
//         'pickup_lat': _myLocation.latitude,
//         'pickup_lng': _myLocation.longitude,
//         if (_destLocation != null) 'dest_lat': _destLocation!.latitude,
//         if (_destLocation != null) 'dest_lng': _destLocation!.longitude,
//         'tariff': _selectedTariff,
//       });
//       ref.invalidate(activeRideProvider);
//     } on DioException catch (e) {
//       setState(
//           () => _error = e.response?.data['detail']?.toString() ?? 'Xato');
//       HapticFeedback.heavyImpact();
//     } finally {
//       if (mounted) setState(() => _loading = false);
//     }
//   }
// 
//   void _swapAddresses() {
//     HapticFeedback.lightImpact();
//     _swapCtrl.forward(from: 0);
//     final tmp = _pickupCtrl.text;
//     _pickupCtrl.text = _destCtrl.text;
//     _destCtrl.text = tmp;
//   }
// 
//   @override
//   Widget build(BuildContext context) {
//     final selectedTariff =
//         _tariffs.firstWhere((t) => t.id == _selectedTariff);
//     final shownFare = _baseFare != null
//         ? _baseFare! * selectedTariff.multiplier
//         : null;
// 
//     final mapObjects = <ymk.MapObject>[
//       // Pickup marker
//       if (_MarkerIcons.pickup != null)
//         ymk.PlacemarkMapObject(
//           mapId: const ymk.MapObjectId('pickup'),
//           point: _toPoint(_myLocation),
//           opacity: 1.0,
//           icon: ymk.PlacemarkIcon.single(
//             ymk.PlacemarkIconStyle(
//               image: _MarkerIcons.pickup!,
//               scale: 0.7,
//             ),
//           ),
//         ),
//       // Destination marker
//       if (_destLocation != null && _MarkerIcons.destination != null)
//         ymk.PlacemarkMapObject(
//           mapId: const ymk.MapObjectId('destination'),
//           point: _toPoint(_destLocation!),
//           opacity: 1.0,
//           icon: ymk.PlacemarkIcon.single(
//             ymk.PlacemarkIconStyle(
//               image: _MarkerIcons.destination!,
//               scale: 0.7,
//             ),
//           ),
//         ),
//       // Marshrut chizig'i
//       if (_destLocation != null)
//         ymk.PolylineMapObject(
//           mapId: const ymk.MapObjectId('route'),
//           polyline: ymk.Polyline(
//             points: (_routePoints ?? [_myLocation, _destLocation!])
//                 .map(_toPoint)
//                 .toList(),
//           ),
//           strokeColor: AppColors.background,
//           strokeWidth: 5,
//           outlineColor: Colors.white,
//           outlineWidth: 2,
//         ),
//     ];
// 
//     return Stack(
//       children: [
//         // ── XARITA (Yandex MapKit) ──
//         ymk.YandexMap(
//           nightModeEnabled: true,
//           mapType: ymk.MapType.vector,
//           mapObjects: mapObjects,
//           onMapCreated: (controller) async {
//             _mapCtrl = controller;
//             await controller.moveCamera(
//               ymk.CameraUpdate.newCameraPosition(
//                 ymk.CameraPosition(
//                     target: _toPoint(_myLocation), zoom: 15),
//               ),
//             );
//           },
//           onMapTap: (point) async {
//             HapticFeedback.selectionClick();
//             final latLng = LatLng(point.latitude, point.longitude);
//             setState(() {
//               _destLocation = latLng;
//               _destCtrl.text =
//                   '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
//             });
//             _estimateWithCoords();
//             final name = await NominatimService.reverse(
//                 latLng.latitude, latLng.longitude);
//             if (name != null && mounted) {
//               final short = name.split(',').take(2).join(',').trim();
//               setState(() => _destCtrl.text = short);
//             }
//           },
//         ),
// 
//         // ── TEPADAGI GRADIENT ──
//         IgnorePointer(
//           child: Container(
//             height: 160,
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [
//                   AppColors.background.withValues(alpha: 0.95),
//                   AppColors.background.withValues(alpha: 0),
//                 ],
//               ),
//             ),
//           ),
//         ),
// 
//         // ── TEPADAGI HEADER ──
//         SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
//             child: Row(
//               children: [
//                 Container(
//                   width: 42,
//                   height: 42,
//                   decoration: BoxDecoration(
//                     color: AppColors.success,
//                     borderRadius: BorderRadius.circular(14),
//                     boxShadow: [
//                       BoxShadow(
//                         color:
//                             AppColors.success.withValues(alpha: 0.35),
//                         blurRadius: 16,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: const Icon(Icons.local_taxi,
//                       color: Colors.white, size: 22),
//                 ),
//                 const SizedBox(width: 14),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       'Fargonam Taxi',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w800,
//                         color: AppColors.textPrimary,
//                         letterSpacing: -0.5,
//                       ),
//                     ),
//                     Text(
//                       'Tez va qulay sayohat',
//                       style: TextStyle(
//                           fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
//                     ),
//                   ],
//                 ),
//                 const Spacer(),
//                 _CircleIconButton(
//                   icon: Icons.gps_fixed,
//                   color: _gpsState == GpsState.ok
//                       ? AppColors.success
//                       : const Color(0xFFC77B1E),
//                   onTap: _loadLocation,
//                   loading: _gpsState == GpsState.loading,
//                 ),
//               ],
//             ),
//           ),
//         ),
// 
//         // ── GPS BANNERI (agar muammo bo'lsa) ──
//         if (_gpsState == GpsState.denied || _gpsState == GpsState.disabled)
//           Positioned(
//             top: 80,
//             left: 16,
//             right: 16,
//             child: SafeArea(
//               child: _GpsBanner(
//                 state: _gpsState,
//                 onRetry: _loadLocation,
//               ),
//             ),
//           ),
// 
//         // ── DRAGGABLE BOTTOM SHEET ──
//         DraggableScrollableSheet(
//           controller: _sheetCtrl,
//           initialChildSize: 0.42,
//           minChildSize: 0.18,
//           maxChildSize: 0.85,
//           snap: true,
//           snapSizes: const [0.18, 0.42, 0.85],
//           builder: (context, scrollCtrl) => Container(
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius:
//                   const BorderRadius.vertical(top: Radius.circular(28)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.4),
//                   blurRadius: 30,
//                   offset: const Offset(0, -10),
//                 ),
//               ],
//             ),
//             child: ListView(
//               controller: scrollCtrl,
//               padding: EdgeInsets.zero,
//               children: [
//                 // Drag handle
//                 Center(
//                   child: Container(
//                     margin: const EdgeInsets.only(top: 10, bottom: 6),
//                     width: 44,
//                     height: 5,
//                     decoration: BoxDecoration(
//                       color: AppColors.border,
//                       borderRadius: BorderRadius.circular(3),
//                     ),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       const Text(
//                         'Qaerga boramiz?',
//                         style: TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.w800,
//                           color: AppColors.textPrimary,
//                           letterSpacing: -0.5,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
// 
//                       // Saqlangan manzillar
//                       _SavedAddressChips(
//                         onSelect: (address) {
//                           HapticFeedback.selectionClick();
//                           if (_pickupCtrl.text.trim().isEmpty) {
//                             _pickupCtrl.text = address;
//                           } else {
//                             _destCtrl.text = address;
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 12),
// 
//                       // Manzil inputlari
//                       Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: BoxDecoration(
//                           color: AppColors.surfaceAlt,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Column(
//                           children: [
//                             AddressInputField(
//                               controller: _pickupCtrl,
//                               hint: 'Qayerdan (olish manzili)',
//                               icon: Icons.radio_button_checked,
//                               iconColor: AppColors.success,
//                               nearLocation: _myLocation,
//                               onSelected: (s) {
//                                 HapticFeedback.selectionClick();
//                                 setState(() => _myLocation = s.latLng);
//                                 _mapCtrl?.moveCamera(
//                                   ymk.CameraUpdate.newCameraPosition(
//                                     ymk.CameraPosition(
//                                         target: _toPoint(s.latLng),
//                                         zoom: 15),
//                                   ),
//                                   animation: const ymk.MapAnimation(
//                                       type: ymk.MapAnimationType.smooth,
//                                       duration: 0.4),
//                                 );
//                                 if (_destLocation != null) {
//                                   _estimateWithCoords();
//                                 }
//                               },
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.symmetric(
//                                   horizontal: 20),
//                               child: Row(
//                                 children: [
//                                   const SizedBox(width: 14),
//                                   Container(
//                                     width: 1,
//                                     height: 16,
//                                     color: AppColors.border,
//                                   ),
//                                   const Spacer(),
//                                   GestureDetector(
//                                     onTap: _swapAddresses,
//                                     child: AnimatedBuilder(
//                                       animation: _swapCtrl,
//                                       builder: (_, child) => Transform.rotate(
//                                         angle: _swapCtrl.value * 3.14159,
//                                         child: child,
//                                       ),
//                                       child: Container(
//                                         width: 32,
//                                         height: 32,
//                                         decoration: BoxDecoration(
//                                           color: AppColors.surfaceAlt,
//                                           borderRadius:
//                                               BorderRadius.circular(10),
//                                         ),
//                                         child: const Icon(Icons.swap_vert,
//                                             color:
//                                                 AppColors.textSecondary,
//                                             size: 18),
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             AddressInputField(
//                               controller: _destCtrl,
//                               hint: 'Qayerga (borish manzili)',
//                               icon: Icons.location_on,
//                               iconColor: AppColors.error,
//                               nearLocation: _myLocation,
//                               onSelected: (s) {
//                                 HapticFeedback.selectionClick();
//                                 setState(() => _destLocation = s.latLng);
//                                 _estimateWithCoords();
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
// 
//                       const SizedBox(height: 16),
// 
//                       // Tariflar (faqat destination tanlanganda)
//                       AnimatedSize(
//                         duration: const Duration(milliseconds: 300),
//                         curve: Curves.easeOutCubic,
//                         child: _destLocation == null
//                             ? const SizedBox(width: double.infinity)
//                             : Column(
//                                 crossAxisAlignment:
//                                     CrossAxisAlignment.stretch,
//                                 children: [
//                                   _TariffSelector(
//                                     selected: _selectedTariff,
//                                     baseFare: _baseFare,
//                                     estimating: _estimating,
//                                     onSelect: (id) {
//                                       HapticFeedback.selectionClick();
//                                       setState(
//                                           () => _selectedTariff = id);
//                                     },
//                                   ),
//                                   const SizedBox(height: 16),
//                                 ],
//                               ),
//                       ),
// 
//                       // Narx kartochkasi yoki empty hint
//                       _FareCard(
//                         distanceKm: _distanceKm,
//                         durationMin: _durationMin,
//                         fare: shownFare,
//                         estimating: _estimating,
//                         hasDestination: _destLocation != null,
//                       ),
// 
//                       // Xato
//                       AnimatedSize(
//                         duration: const Duration(milliseconds: 250),
//                         child: _error == null
//                             ? const SizedBox.shrink()
//                             : Padding(
//                                 padding: const EdgeInsets.only(top: 10),
//                                 child: Container(
//                                   padding: const EdgeInsets.all(12),
//                                   decoration: BoxDecoration(
//                                     color: AppColors.error.withValues(alpha: 0.15),
//                                     borderRadius:
//                                         BorderRadius.circular(12),
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       const Icon(Icons.error_outline,
//                                           color: AppColors.error, size: 18),
//                                       const SizedBox(width: 8),
//                                       Expanded(
//                                         child: Text(_error!,
//                                             style: const TextStyle(
//                                                 color: AppColors.error,
//                                                 fontSize: 13)),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                       ),
// 
//                       const SizedBox(height: 16),
// 
//                       // Submit tugmasi
//                       _PrimaryActionButton(
//                         loading: _loading,
//                         enabled:
//                             _destLocation != null && _baseFare != null,
//                         label: 'Taksi chaqirish',
//                         icon: Icons.local_taxi,
//                         onTap: _submit,
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
// 
// // ══════════════════════════════════════════════════════════════
// // FAOL SAYOHAT EKRANI
// // ══════════════════════════════════════════════════════════════
// 
// class _ActiveRideView extends ConsumerStatefulWidget {
//   const _ActiveRideView({super.key, required this.ride});
//   final Map<String, dynamic> ride;
//   @override
//   ConsumerState<_ActiveRideView> createState() => _ActiveRideViewState();
// }
// 
// class _ActiveRideViewState extends ConsumerState<_ActiveRideView>
//     with TickerProviderStateMixin {
//   ymk.YandexMapController? _mapCtrl;
//   Timer? _pollTimer;
//   RideWsService? _ws;
//   LatLng? _driverLive;
//   bool _autoFitDone = false;
// 
//   @override
//   void initState() {
//     super.initState();
//     _MarkerIcons.ensureLoaded().then((_) {
//       if (mounted) setState(() {});
//     });
//     _pollTimer = Timer.periodic(const Duration(seconds: 5),
//         (_) => ref.invalidate(activeRideProvider));
//     _connectWs();
//   }
// 
//   Future<void> _connectWs() async {
//     final rideId = widget.ride['id'] as int;
//     final storage = ref.read(secureStorageProvider);
//     _ws = RideWsService(
//       onDriverLocation: (lat, lng) {
//         if (mounted) setState(() => _driverLive = LatLng(lat, lng));
//       },
//       onStatusChange: (status) {
//         HapticFeedback.mediumImpact();
//         ref.invalidate(activeRideProvider);
//       },
//     );
//     await _ws!.connect(rideId, storage);
//   }
// 
//   @override
//   void dispose() {
//     _pollTimer?.cancel();
//     _ws?.disconnect();
//     super.dispose();
//   }
// 
//   Future<void> _fitAll(LatLng pickup, LatLng? dest, LatLng? driver) async {
//     if (_mapCtrl == null) return;
//     final points = <ymk.Point>[
//       _toPoint(pickup),
//       if (dest != null) _toPoint(dest),
//       if (driver != null) _toPoint(driver),
//     ];
//     if (points.length < 2) {
//       await _mapCtrl!.moveCamera(
//         ymk.CameraUpdate.newCameraPosition(
//           ymk.CameraPosition(target: points.first, zoom: 15),
//         ),
//       );
//       return;
//     }
//     await _mapCtrl!.moveCamera(
//       ymk.CameraUpdate.newGeometry(
//         ymk.Geometry.fromPolyline(ymk.Polyline(points: points)),
//       ),
//       animation: const ymk.MapAnimation(
//           type: ymk.MapAnimationType.smooth, duration: 0.6),
//     );
//   }
// 
//   Future<void> _confirmCancel(int rideId) async {
//     HapticFeedback.lightImpact();
//     final ok = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: AppColors.surface,
//         shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: const Text('Sayohatni bekor qilish?'),
//         content: const Text(
//             'Haqiqatan ham bu sayohatni bekor qilmoqchimisiz?',
//             style: TextStyle(color: AppColors.textSecondary)),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text('Yo\'q'),
//           ),
//           FilledButton(
//             style: FilledButton.styleFrom(backgroundColor: AppColors.error),
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text('Ha, bekor qilish'),
//           ),
//         ],
//       ),
//     );
//     if (ok != true) return;
//     HapticFeedback.heavyImpact();
//     try {
//       await ref.read(dioProvider).post('/rides/$rideId/cancel');
//       ref.invalidate(activeRideProvider);
//     } catch (_) {}
//   }
// 
//   Future<void> _callDriver(String phone) async {
//     HapticFeedback.lightImpact();
//     final uri = Uri(scheme: 'tel', path: phone);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri);
//     } else if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Qo\'ng\'iroq qilib bo\'lmadi: $phone'),
//           duration: const Duration(milliseconds: 1600),
//         ),
//       );
//     }
//   }
// 
//   @override
//   Widget build(BuildContext context) {
//     final r = widget.ride;
//     final status = r['status'] as String;
//     final driverName = r['driver_name'] as String?;
//     final driverPhone = r['driver_phone'] as String?;
//     final carModel = r['car_model'] as String?;
//     final carNumber = r['car_number'] as String?;
//     final carColor = r['car_color'] as String?;
//     final fare = r['fare']?.toString();
// 
//     final statusInfo = _getStatusInfo(status);
// 
//     final pickupLat = r['pickup_lat'] as double?;
//     final pickupLng = r['pickup_lng'] as double?;
//     final destLat = r['dest_lat'] as double?;
//     final destLng = r['dest_lng'] as double?;
//     final driverLat = r['driver_lat'] as double?;
//     final driverLng = r['driver_lng'] as double?;
// 
//     final pickupPoint = (pickupLat != null && pickupLng != null)
//         ? LatLng(pickupLat, pickupLng)
//         : _ferghanaCenter;
//     final destPoint = (destLat != null && destLng != null)
//         ? LatLng(destLat, destLng)
//         : null;
//     final driverPoint = _driverLive ??
//         ((driverLat != null && driverLng != null)
//             ? LatLng(driverLat, driverLng)
//             : null);
// 
//     // Birinchi build'dan so'ng kamerani moslash
//     if (!_autoFitDone) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         if (mounted && !_autoFitDone) {
//           _autoFitDone = true;
//           _fitAll(pickupPoint, destPoint, driverPoint);
//         }
//       });
//     }
// 
//     final mapObjects = <ymk.MapObject>[
//       if (_MarkerIcons.pickup != null)
//         ymk.PlacemarkMapObject(
//           mapId: const ymk.MapObjectId('pickup'),
//           point: _toPoint(pickupPoint),
//           opacity: 1.0,
//           icon: ymk.PlacemarkIcon.single(
//             ymk.PlacemarkIconStyle(
//               image: _MarkerIcons.pickup!,
//               scale: 0.7,
//             ),
//           ),
//         ),
//       if (destPoint != null && _MarkerIcons.destination != null)
//         ymk.PlacemarkMapObject(
//           mapId: const ymk.MapObjectId('destination'),
//           point: _toPoint(destPoint),
//           opacity: 1.0,
//           icon: ymk.PlacemarkIcon.single(
//             ymk.PlacemarkIconStyle(
//               image: _MarkerIcons.destination!,
//               scale: 0.7,
//             ),
//           ),
//         ),
//       if (driverPoint != null && _MarkerIcons.driver != null)
//         ymk.PlacemarkMapObject(
//           mapId: const ymk.MapObjectId('driver'),
//           point: _toPoint(driverPoint),
//           opacity: 1.0,
//           icon: ymk.PlacemarkIcon.single(
//             ymk.PlacemarkIconStyle(
//               image: _MarkerIcons.driver!,
//               scale: 0.7,
//             ),
//           ),
//         ),
//       if (destPoint != null)
//         ymk.PolylineMapObject(
//           mapId: const ymk.MapObjectId('route'),
//           polyline: ymk.Polyline(
//             points: [
//               _toPoint(pickupPoint),
//               if (driverPoint != null) _toPoint(driverPoint),
//               _toPoint(destPoint),
//             ],
//           ),
//           strokeColor: AppColors.background,
//           strokeWidth: 4,
//           outlineColor: Colors.white,
//           outlineWidth: 2,
//           dashLength: 8,
//           gapLength: 6,
//         ),
//     ];
// 
//     return Stack(
//       children: [
//         // ── XARITA (Yandex MapKit) ──
//         ymk.YandexMap(
//           nightModeEnabled: true,
//           mapType: ymk.MapType.vector,
//           mapObjects: mapObjects,
//           onMapCreated: (controller) async {
//             _mapCtrl = controller;
//             await controller.moveCamera(
//               ymk.CameraUpdate.newCameraPosition(
//                 ymk.CameraPosition(
//                     target: _toPoint(pickupPoint), zoom: 14),
//               ),
//             );
//           },
//         ),
// 
//         // ── TEPADAGI STATUS ──
//         SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: AppColors.surface.withValues(alpha: 0.96),
//                 borderRadius: BorderRadius.circular(20),
//                 border: Border.all(color: AppColors.border),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.25),
//                     blurRadius: 20,
//                     offset: const Offset(0, 6),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   _StatusIcon(
//                     color: statusInfo.color,
//                     icon: statusInfo.icon,
//                     pulsing: status == 'searching',
//                   ),
//                   const SizedBox(width: 14),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           statusInfo.title,
//                           style: TextStyle(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w700,
//                             color: statusInfo.color,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           statusInfo.subtitle,
//                           style: TextStyle(
//                               fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (status == 'searching')
//                     SizedBox(
//                       width: 22,
//                       height: 22,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2.5,
//                         color: statusInfo.color,
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ),
//         ),
// 
//         // ── RECENTER TUGMA ──
//         Positioned(
//           right: 16,
//           bottom: 380,
//           child: SafeArea(
//             child: _CircleIconButton(
//               icon: Icons.center_focus_strong,
//               color: AppColors.primary,
//               onTap: () => _fitAll(pickupPoint, destPoint, driverPoint),
//             ),
//           ),
//         ),
// 
//         // ── PASTDAGI PANEL ──
//         Positioned(
//           bottom: 0,
//           left: 0,
//           right: 0,
//           child: Container(
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius:
//                   const BorderRadius.vertical(top: Radius.circular(28)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withValues(alpha: 0.5),
//                   blurRadius: 30,
//                   offset: const Offset(0, -10),
//                 ),
//               ],
//             ),
//             child: SafeArea(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Drag indicator
//                     Container(
//                       margin: const EdgeInsets.only(bottom: 10),
//                       width: 44,
//                       height: 5,
//                       decoration: BoxDecoration(
//                         color: AppColors.border,
//                         borderRadius: BorderRadius.circular(3),
//                       ),
//                     ),
// 
//                     _RouteInfo(
//                       pickup: r['pickup_address'] as String,
//                       destination: r['destination_address'] as String,
//                     ),
// 
//                     if (driverName != null) ...[
//                       const SizedBox(height: 16),
//                       Container(
//                         padding: const EdgeInsets.all(16),
//                         decoration: BoxDecoration(
//                           color: AppColors.surfaceAlt,
//                           borderRadius: BorderRadius.circular(20),
//                         ),
//                         child: Column(
//                           children: [
//                             Row(
//                               children: [
//                                 Container(
//                                   width: 50,
//                                   height: 50,
//                                   decoration: BoxDecoration(
//                                     color: AppColors.success,
//                                     borderRadius:
//                                         BorderRadius.circular(16),
//                                   ),
//                                   child: const Icon(Icons.person,
//                                       color: Colors.white, size: 26),
//                                 ),
//                                 const SizedBox(width: 14),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         driverName,
//                                         style: const TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.w700,
//                                           color: AppColors.textPrimary,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         [carModel, carColor, carNumber]
//                                             .where((s) => s != null)
//                                             .join('  •  '),
//                                         style: const TextStyle(
//                                             fontSize: 13,
//                                             color:
//                                                 AppColors.textSecondary),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 if (driverPhone != null)
//                                   GestureDetector(
//                                     onTap: () => _callDriver(driverPhone),
//                                     child: Container(
//                                       width: 44,
//                                       height: 44,
//                                       decoration: BoxDecoration(
//                                         color: AppColors.success.withValues(alpha: 0.15),
//                                         borderRadius:
//                                             BorderRadius.circular(14),
//                                         border: Border.all(
//                                           color: AppColors.success
//                                               .withValues(alpha: 0.4),
//                                         ),
//                                       ),
//                                       child: const Icon(Icons.phone,
//                                           color: AppColors.success,
//                                           size: 20),
//                                     ),
//                                   ),
//                               ],
//                             ),
//                             if (fare != null) ...[
//                               const SizedBox(height: 14),
//                               Container(
//                                 width: double.infinity,
//                                 padding: const EdgeInsets.symmetric(
//                                     vertical: 12),
//                                 decoration: BoxDecoration(
//                                   color: AppColors.surface,
//                                   borderRadius:
//                                       BorderRadius.circular(14),
//                                 ),
//                                 child: Center(
//                                   child: Text(
//                                     _formatPrice(fare),
//                                     style: const TextStyle(
//                                       fontSize: 22,
//                                       fontWeight: FontWeight.w800,
//                                       color: AppColors.success,
//                                       letterSpacing: -0.5,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ],
// 
//                     if (status == 'searching' || status == 'accepted') ...[
//                       const SizedBox(height: 16),
//                       GestureDetector(
//                         onTap: () => _confirmCancel(r['id'] as int),
//                         child: Container(
//                           height: 52,
//                           decoration: BoxDecoration(
//                             color: AppColors.error.withValues(alpha: 0.15),
//                             borderRadius: BorderRadius.circular(16),
//                             border: Border.all(
//                                 color: AppColors.error
//                                     .withValues(alpha: 0.3)),
//                           ),
//                           child: const Center(
//                             child: Text(
//                               'Bekor qilish',
//                               style: TextStyle(
//                                 color: AppColors.error,
//                                 fontSize: 15,
//                                 fontWeight: FontWeight.w700,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
// 
// // ══════════════════════════════════════════════════════════════
// // YORDAMCHI WIDGETLAR
// // ══════════════════════════════════════════════════════════════
// 
// 
// /// Status ikonkasi — searching paytida pulse qiladi
// class _StatusIcon extends StatefulWidget {
//   const _StatusIcon(
//       {required this.color, required this.icon, required this.pulsing});
//   final Color color;
//   final IconData icon;
//   final bool pulsing;
// 
//   @override
//   State<_StatusIcon> createState() => _StatusIconState();
// }
// 
// class _StatusIconState extends State<_StatusIcon>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
// 
//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 1200));
//     if (widget.pulsing) _ctrl.repeat(reverse: true);
//   }
// 
//   @override
//   void didUpdateWidget(covariant _StatusIcon old) {
//     super.didUpdateWidget(old);
//     if (widget.pulsing && !_ctrl.isAnimating) {
//       _ctrl.repeat(reverse: true);
//     } else if (!widget.pulsing && _ctrl.isAnimating) {
//       _ctrl.stop();
//       _ctrl.value = 0;
//     }
//   }
// 
//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }
// 
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _ctrl,
//       builder: (_, _) {
//         final scale = 1.0 + 0.12 * _ctrl.value;
//         return Transform.scale(
//           scale: scale,
//           child: Container(
//             width: 44,
//             height: 44,
//             decoration: BoxDecoration(
//               color: widget.color.withValues(alpha: 0.18),
//               borderRadius: BorderRadius.circular(14),
//             ),
//             child: Icon(widget.icon, color: widget.color, size: 22),
//           ),
//         );
//       },
//     );
//   }
// }
// 
// /// Yumaloq icon tugma (header / xarita ustida)
// class _CircleIconButton extends StatelessWidget {
//   const _CircleIconButton({
//     required this.icon,
//     required this.color,
//     required this.onTap,
//     this.loading = false,
//   });
//   final IconData icon;
//   final Color color;
//   final VoidCallback onTap;
//   final bool loading;
// 
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         HapticFeedback.lightImpact();
//         onTap();
//       },
//       child: Container(
//         width: 44,
//         height: 44,
//         decoration: BoxDecoration(
//           color: AppColors.surfaceAlt,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: AppColors.border),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.25),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Center(
//           child: loading
//               ? SizedBox(
//                   width: 18,
//                   height: 18,
//                   child: CircularProgressIndicator(
//                       strokeWidth: 2.2, color: color),
//                 )
//               : Icon(icon, color: color, size: 20),
//         ),
//       ),
//     );
//   }
// }
// 
// /// GPS holat banneri
// class _GpsBanner extends StatelessWidget {
//   const _GpsBanner({required this.state, required this.onRetry});
//   final GpsState state;
//   final VoidCallback onRetry;
// 
//   @override
//   Widget build(BuildContext context) {
//     final isDisabled = state == GpsState.disabled;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFC77B1E).withValues(alpha: 0.15),
//         borderRadius: BorderRadius.circular(16),
//         border:
//             Border.all(color: const Color(0xFFC77B1E).withValues(alpha: 0.4)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.location_off,
//               color: Color(0xFFC77B1E), size: 22),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   isDisabled
//                       ? 'GPS o\'chirilgan'
//                       : 'Joylashuvga ruxsat berilmagan',
//                   style: const TextStyle(
//                     color: Color(0xFFC77B1E),
//                     fontWeight: FontWeight.w700,
//                     fontSize: 13,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 const Text(
//                   'Manzilni qo\'lda kiriting yoki ruxsat bering',
//                   style: TextStyle(
//                       color: AppColors.textSecondary, fontSize: 11),
//                 ),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap: onRetry,
//             child: Container(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: const Color(0xFFC77B1E),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Text(
//                 'Qayta',
//                 style: TextStyle(
//                   color: AppColors.background,
//                   fontWeight: FontWeight.w700,
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// 
// /// Tariflar tanlash gorizontal qatori
// class _TariffSelector extends StatelessWidget {
//   const _TariffSelector({
//     required this.selected,
//     required this.baseFare,
//     required this.estimating,
//     required this.onSelect,
//   });
//   final String selected;
//   final double? baseFare;
//   final bool estimating;
//   final ValueChanged<String> onSelect;
// 
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       height: 86,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         padding: EdgeInsets.zero,
//         itemCount: _tariffs.length,
//         separatorBuilder: (_, _) => const SizedBox(width: 10),
//         itemBuilder: (context, i) {
//           final t = _tariffs[i];
//           final isSelected = t.id == selected;
//           final price = baseFare != null ? baseFare! * t.multiplier : null;
//           return GestureDetector(
//             onTap: () => onSelect(t.id),
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 220),
//               curve: Curves.easeOut,
//               width: 110,
//               padding: const EdgeInsets.symmetric(
//                   horizontal: 12, vertical: 10),
//               decoration: BoxDecoration(
//                 color: isSelected
//                     ? AppColors.success.withValues(alpha: 0.15)
//                     : AppColors.surfaceAlt,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(
//                   color: isSelected
//                       ? AppColors.success
//                       : AppColors.border,
//                   width: isSelected ? 1.5 : 0.5,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Icon(t.icon,
//                       color: isSelected
//                           ? AppColors.success
//                           : AppColors.textSecondary,
//                       size: 20),
//                   const SizedBox(height: 6),
//                   Text(
//                     t.name,
//                     style: TextStyle(
//                       fontSize: 13,
//                       fontWeight: FontWeight.w800,
//                       color: isSelected
//                           ? AppColors.textPrimary
//                           : AppColors.textSecondary,
//                     ),
//                   ),
//                   const Spacer(),
//                   if (estimating)
//                     const ShimmerBox(width: 60, height: 12, borderRadius: 4)
//                   else if (price != null)
//                     Text(
//                       _formatPrice(price.toStringAsFixed(0)),
//                       style: TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w700,
//                         color: isSelected
//                             ? AppColors.success
//                             : AppColors.textSecondary.withValues(alpha: 0.7),
//                       ),
//                     )
//                   else
//                     Text(
//                       t.subtitle,
//                       style: TextStyle(
//                           fontSize: 10, color: AppColors.textSecondary.withValues(alpha: 0.7)),
//                     ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
// 
// /// Narx + masofa + vaqt kartasi (yoki bo'sh holat)
// class _FareCard extends StatelessWidget {
//   const _FareCard({
//     required this.distanceKm,
//     required this.durationMin,
//     required this.fare,
//     required this.estimating,
//     required this.hasDestination,
//   });
//   final double? distanceKm;
//   final int? durationMin;
//   final double? fare;
//   final bool estimating;
//   final bool hasDestination;
// 
//   @override
//   Widget build(BuildContext context) {
//     return AnimatedSwitcher(
//       duration: const Duration(milliseconds: 250),
//       child: !hasDestination
//           ? Container(
//               key: const ValueKey('empty'),
//               padding: const EdgeInsets.symmetric(
//                   horizontal: 16, vertical: 18),
//               decoration: BoxDecoration(
//                 color: AppColors.surfaceAlt,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: AppColors.border),
//               ),
//               child: const Row(
//                 children: [
//                   Icon(Icons.touch_app,
//                       color: AppColors.textSecondary, size: 22),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'Manzilni tanlang yoki xaritada bosing',
//                       style: TextStyle(
//                           color: AppColors.textSecondary, fontSize: 13),
//                     ),
//                   ),
//                 ],
//               ),
//             )
//           : Container(
//               key: const ValueKey('fare'),
//               padding: const EdgeInsets.symmetric(
//                   horizontal: 16, vertical: 14),
//               decoration: BoxDecoration(
//                 color: AppColors.surfaceAlt,
//                 borderRadius: BorderRadius.circular(16),
//                 border: Border.all(color: AppColors.border),
//               ),
//               child: Row(
//                 children: [
//                   if (estimating && distanceKm == null)
//                     const ShimmerBox(width: 60, height: 16)
//                   else
//                     _StatChip(
//                       icon: Icons.route,
//                       value: distanceKm != null
//                           ? '${distanceKm!.toStringAsFixed(1)} km'
//                           : '-- km',
//                       color: AppColors.primary,
//                     ),
//                   const SizedBox(width: 14),
//                   Container(
//                       width: 1, height: 28, color: AppColors.border),
//                   const SizedBox(width: 14),
//                   if (estimating && durationMin == null)
//                     const ShimmerBox(width: 50, height: 16)
//                   else
//                     _StatChip(
//                       icon: Icons.schedule,
//                       value: durationMin != null
//                           ? '$durationMin min'
//                           : '-- min',
//                       color: AppColors.success,
//                     ),
//                   const Spacer(),
//                   if (estimating && fare == null)
//                     const ShimmerBox(width: 80, height: 28, borderRadius: 12)
//                   else
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 14, vertical: 8),
//                       decoration: BoxDecoration(
//                         color: AppColors.success.withValues(alpha: 0.15),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         fare != null
//                             ? _formatPrice(fare!.toStringAsFixed(0))
//                             : '-- UZS',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w800,
//                           color: AppColors.success,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
// 
// /// Asosiy submit tugmasi — disabled / loading holatlari bilan
// class _PrimaryActionButton extends StatelessWidget {
//   const _PrimaryActionButton({
//     required this.loading,
//     required this.enabled,
//     required this.label,
//     required this.icon,
//     required this.onTap,
//   });
//   final bool loading;
//   final bool enabled;
//   final String label;
//   final IconData icon;
//   final VoidCallback onTap;
// 
//   @override
//   Widget build(BuildContext context) {
//     final disabled = loading || !enabled;
//     return GestureDetector(
//       onTap: disabled ? null : onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 220),
//         curve: Curves.easeOut,
//         height: 56,
//         decoration: BoxDecoration(
//           color: disabled ? AppColors.surfaceAlt : AppColors.success,
//           borderRadius: BorderRadius.circular(18),
//           boxShadow: disabled
//               ? null
//               : [
//                   BoxShadow(
//                     color: AppColors.success.withValues(alpha: 0.35),
//                     blurRadius: 22,
//                     offset: const Offset(0, 10),
//                   ),
//                 ],
//         ),
//         child: Center(
//           child: loading
//               ? const SizedBox(
//                   height: 24,
//                   width: 24,
//                   child: CircularProgressIndicator(
//                       strokeWidth: 2.5, color: Colors.white),
//                 )
//               : Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(icon,
//                         color: disabled
//                             ? AppColors.textSecondary.withValues(alpha: 0.7)
//                             : Colors.white,
//                         size: 22),
//                     const SizedBox(width: 10),
//                     Text(
//                       label,
//                       style: TextStyle(
//                         color: disabled
//                             ? AppColors.textSecondary.withValues(alpha: 0.7)
//                             : Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       ),
//     );
//   }
// }
// 
// /// Statistik chip (masofa, vaqt)
// class _StatChip extends StatelessWidget {
//   final IconData icon;
//   final String value;
//   final Color color;
// 
//   const _StatChip({
//     required this.icon,
//     required this.value,
//     required this.color,
//   });
// 
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: color, size: 18),
//         const SizedBox(width: 6),
//         Text(
//           value,
//           style: TextStyle(
//             color: color,
//             fontWeight: FontWeight.w700,
//             fontSize: 14,
//           ),
//         ),
//       ],
//     );
//   }
// }
// 
// /// Marshrut ma'lumoti (olish va borish manzillari)
// class _RouteInfo extends StatelessWidget {
//   final String pickup;
//   final String destination;
// 
//   const _RouteInfo({required this.pickup, required this.destination});
// 
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.surfaceAlt,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Row(
//         children: [
//           Column(
//             children: [
//               Container(
//                 width: 10,
//                 height: 10,
//                 decoration: const BoxDecoration(
//                   color: AppColors.success,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//               Container(width: 1.5, height: 28, color: AppColors.border),
//               Container(
//                 width: 10,
//                 height: 10,
//                 decoration: const BoxDecoration(
//                   color: AppColors.error,
//                   shape: BoxShape.circle,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   pickup,
//                   style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.textPrimary),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 const SizedBox(height: 18),
//                 Text(
//                   destination,
//                   style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: AppColors.textPrimary),
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// 
// /// Status holat ma'lumoti
// class _StatusInfo {
//   final String title;
//   final String subtitle;
//   final Color color;
//   final IconData icon;
//   const _StatusInfo(this.title, this.subtitle, this.color, this.icon);
// }
// 
// _StatusInfo _getStatusInfo(String status) {
//   return switch (status) {
//     'searching' => const _StatusInfo(
//         'Haydovchi qidirilmoqda',
//         'Iltimos kuting, tez orada topiladi...',
//         Color(0xFFC77B1E),
//         Icons.search,
//       ),
//     'accepted' => const _StatusInfo(
//         'Haydovchi yo\'lda',
//         'Haydovchi sizga qarab kelmoqda',
//         AppColors.primary,
//         Icons.directions_car,
//       ),
//     'arrived' => const _StatusInfo(
//         'Haydovchi yetib keldi!',
//         'Mashinaga chiqishingiz mumkin',
//         AppColors.success,
//         Icons.place,
//       ),
//     'in_progress' => const _StatusInfo(
//         'Sayohat davom etmoqda',
//         'Manzilingizga yaqinlashyapsiz...',
//         AppColors.success,
//         Icons.navigation,
//       ),
//     _ => _StatusInfo(status, '', AppColors.textSecondary, Icons.info_outline),
//   };
// }
// 
// /// Saqlangan manzillar — tez tanlash uchun chiplar
// class _SavedAddressChips extends ConsumerWidget {
//   const _SavedAddressChips({required this.onSelect});
//   final void Function(String address) onSelect;
// 
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final addrsAsync = ref.watch(addressesProvider);
//     return addrsAsync.when(
//       loading: () => const SizedBox.shrink(),
//       error: (_, _) => const SizedBox.shrink(),
//       data: (addrs) {
//         if (addrs.isEmpty) return const SizedBox.shrink();
//         return SizedBox(
//           height: 36,
//           child: ListView.separated(
//             scrollDirection: Axis.horizontal,
//             itemCount: addrs.length,
//             separatorBuilder: (_, _) => const SizedBox(width: 8),
//             itemBuilder: (context, i) {
//               final a = addrs[i];
//               final label = a['label'] as String;
//               final address = a['address'] as String;
//               IconData icon = Icons.location_on;
//               final lower = label.toLowerCase();
//               if (lower.contains('uy') || lower.contains('home')) {
//                 icon = Icons.home;
//               } else if (lower.contains('ish') || lower.contains('work')) {
//                 icon = Icons.work;
//               }
//               return GestureDetector(
//                 onTap: () => onSelect(address),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   decoration: BoxDecoration(
//                     color: AppColors.surfaceAlt,
//                     borderRadius: BorderRadius.circular(20),
//                     border:
//                         Border.all(color: AppColors.border, width: 0.5),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(icon, size: 16, color: AppColors.primary),
//                       const SizedBox(width: 6),
//                       Text(label,
//                           style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.w600)),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         );
//       },
//     );
//   }
// }
// 
// /// Narxni formatlash: 15000 -> 15 000 UZS
// String _formatPrice(String raw) {
//   final num = double.tryParse(raw);
//   if (num == null) return '$raw UZS';
//   final intStr = num.toInt().toString();
//   final buf = StringBuffer();
//   for (var i = 0; i < intStr.length; i++) {
//     if (i > 0 && (intStr.length - i) % 3 == 0) buf.write(' ');
//     buf.write(intStr[i]);
//   }
//   return '$buf UZS';
// }
