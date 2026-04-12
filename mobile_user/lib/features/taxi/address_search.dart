import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme.dart';

/// Nominatim (OpenStreetMap) orqali manzil qidirish
class NominatimService {
  static final _dio = Dio(BaseOptions(
    baseUrl: 'https://nominatim.openstreetmap.org',
    headers: {'User-Agent': 'FargonamApp/1.0'},
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  /// Manzil qidirish — matn bo'yicha
  static Future<List<AddressSuggestion>> search(String query, {LatLng? near}) async {
    if (query.trim().length < 3) return [];
    try {
      final params = <String, dynamic>{
        'q': query,
        'format': 'json',
        'addressdetails': 1,
        'limit': 5,
        'countrycodes': 'uz',
        'accept-language': 'uz,ru',
      };
      // Yaqin atrofdan qidirish (Farg'ona viloyati)
      if (near != null) {
        params['viewbox'] = '${near.longitude - 0.5},${near.latitude + 0.3},${near.longitude + 0.5},${near.latitude - 0.3}';
        params['bounded'] = 1;
      }
      final res = await _dio.get('/search', queryParameters: params);
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map((j) => AddressSuggestion(
        displayName: j['display_name'] as String,
        lat: double.parse(j['lat'] as String),
        lng: double.parse(j['lon'] as String),
        type: j['type'] as String? ?? '',
      )).toList();
    } catch (e) {
      debugPrint('Nominatim xato: $e');
      return [];
    }
  }

  /// Koordinatadan manzil olish (reverse geocoding)
  static Future<String?> reverse(double lat, double lng) async {
    try {
      final res = await _dio.get('/reverse', queryParameters: {
        'lat': lat, 'lon': lng,
        'format': 'json',
        'accept-language': 'uz,ru',
      });
      return res.data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}

class AddressSuggestion {
  final String displayName;
  final double lat;
  final double lng;
  final String type;
  const AddressSuggestion({required this.displayName, required this.lat, required this.lng, required this.type});

  /// Qisqa nom (shahar + ko'cha)
  String get shortName {
    final parts = displayName.split(',');
    if (parts.length >= 2) return '${parts[0].trim()}, ${parts[1].trim()}';
    return parts.first.trim();
  }

  LatLng get latLng => LatLng(lat, lng);
}

/// Manzil kiritish — autocomplete bilan
class AddressInputField extends StatefulWidget {
  const AddressInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
    this.nearLocation,
    this.onSelected,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final LatLng? nearLocation;
  final void Function(AddressSuggestion)? onSelected;
  final ValueChanged<String>? onChanged;

  @override
  State<AddressInputField> createState() => _AddressInputFieldState();
}

class _AddressInputFieldState extends State<AddressInputField> {
  List<AddressSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String val) {
    widget.onChanged?.call(val);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (val.trim().length < 3) {
        setState(() { _suggestions = []; _showSuggestions = false; });
        return;
      }
      final results = await NominatimService.search(val, near: widget.nearLocation);
      if (mounted) {
        setState(() { _suggestions = results; _showSuggestions = results.isNotEmpty; });
      }
    });
  }

  void _selectSuggestion(AddressSuggestion s) {
    widget.controller.text = s.shortName;
    setState(() { _showSuggestions = false; _suggestions = []; });
    widget.onSelected?.call(s);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: widget.controller,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          onChanged: _onChanged,
          onTap: () {
            if (_suggestions.isNotEmpty) setState(() => _showSuggestions = true);
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.all(14),
              child: Icon(widget.icon, color: widget.iconColor, size: 20),
            ),
            filled: true,
            fillColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        // Autocomplete takliflar
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider, width: 0.5),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _suggestions.length,
              itemBuilder: (context, i) {
                final s = _suggestions[i];
                return InkWell(
                  onTap: () => _selectSuggestion(s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: widget.iconColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(s.shortName,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
