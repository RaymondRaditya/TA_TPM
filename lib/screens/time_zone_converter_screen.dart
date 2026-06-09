import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class TimeZoneConverterScreen extends StatefulWidget {
  const TimeZoneConverterScreen({super.key});

  @override
  State<TimeZoneConverterScreen> createState() =>
      _TimeZoneConverterScreenState();
}

class _TimeZoneConverterScreenState extends State<TimeZoneConverterScreen> {
  static const Map<String, String> _indonesianRegionsMapping = {
    // WIB
    'Indonesia - DKI Jakarta (WIB)': 'Asia/Jakarta',
    'Indonesia - Jawa Barat (WIB)': 'Asia/Jakarta',
    'Indonesia - Jawa Tengah (WIB)': 'Asia/Jakarta',
    'Indonesia - DI Yogyakarta (WIB)': 'Asia/Jakarta',
    'Indonesia - Jawa Timur (WIB)': 'Asia/Jakarta',
    'Indonesia - Banten (WIB)': 'Asia/Jakarta',
    'Indonesia - Aceh (WIB)': 'Asia/Jakarta',
    'Indonesia - Sumatera Utara (WIB)': 'Asia/Jakarta',
    'Indonesia - Sumatera Barat (WIB)': 'Asia/Jakarta',
    'Indonesia - Riau (WIB)': 'Asia/Jakarta',
    'Indonesia - Kepulauan Riau (WIB)': 'Asia/Jakarta',
    'Indonesia - Jambi (WIB)': 'Asia/Jakarta',
    'Indonesia - Sumatera Selatan (WIB)': 'Asia/Jakarta',
    'Indonesia - Kepulauan Bangka Belitung (WIB)': 'Asia/Jakarta',
    'Indonesia - Bengkulu (WIB)': 'Asia/Jakarta',
    'Indonesia - Lampung (WIB)': 'Asia/Jakarta',
    'Indonesia - Kalimantan Barat (WIB)': 'Asia/Jakarta',
    'Indonesia - Kalimantan Tengah (WIB)': 'Asia/Jakarta',
    // WITA
    'Indonesia - Bali (WITA)': 'Asia/Makassar',
    'Indonesia - Nusa Tenggara Barat (WITA)': 'Asia/Makassar',
    'Indonesia - Nusa Tenggara Timur (WITA)': 'Asia/Makassar',
    'Indonesia - Kalimantan Selatan (WITA)': 'Asia/Makassar',
    'Indonesia - Kalimantan Timur (WITA)': 'Asia/Makassar',
    'Indonesia - Kalimantan Utara (WITA)': 'Asia/Makassar',
    'Indonesia - Sulawesi Utara (WITA)': 'Asia/Makassar',
    'Indonesia - Gorontalo (WITA)': 'Asia/Makassar',
    'Indonesia - Sulawesi Tengah (WITA)': 'Asia/Makassar',
    'Indonesia - Sulawesi Barat (WITA)': 'Asia/Makassar',
    'Indonesia - Sulawesi Selatan (WITA)': 'Asia/Makassar',
    'Indonesia - Sulawesi Tenggara (WITA)': 'Asia/Makassar',
    // WIT
    'Indonesia - Maluku (WIT)': 'Asia/Jayapura',
    'Indonesia - Maluku Utara (WIT)': 'Asia/Jayapura',
    'Indonesia - Papua (WIT)': 'Asia/Jayapura',
    'Indonesia - Papua Barat (WIT)': 'Asia/Jayapura',
    'Indonesia - Papua Selatan (WIT)': 'Asia/Jayapura',
    'Indonesia - Papua Tengah (WIT)': 'Asia/Jayapura',
    'Indonesia - Papua Pegunungan (WIT)': 'Asia/Jayapura',
    'Indonesia - Papua Barat Daya (WIT)': 'Asia/Jayapura',
  };

  String _resolveTimeZoneLocation(String zone) {
    return _indonesianRegionsMapping[zone] ?? zone;
  }

  late List<String> _availableTimeZones;
  late String _sourceTimeZone;
  late List<String> _selectedTimeZones;
  late DateTime _selectedLocalDateTime;
  bool _isLive = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    tzdata.initializeTimeZones();
    final officialZones = tz.timeZoneDatabase.locations.keys.toList()..sort();
    _availableTimeZones = [
      ..._indonesianRegionsMapping.keys,
      ...officialZones,
    ];
    _sourceTimeZone = 'Asia/Jakarta';
    _selectedTimeZones = ['Asia/Jakarta', 'America/New_York', 'Europe/London'];
    _selectedLocalDateTime = DateTime.now();

    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isLive) {
        setState(() {
          _selectedLocalDateTime = DateTime.now();
        });
      }
    });
  }

  DateTime get _sourceUtcDateTime {
    final location = tz.getLocation(_resolveTimeZoneLocation(_sourceTimeZone));
    // Since _selectedLocalDateTime is from DateTime.now() (system local), 
    // we need to be careful if _sourceTimeZone is NOT the system local.
    // If _isLive is true, _selectedLocalDateTime is indeed the current system time.
    
    // To convert correctly: 
    // 1. If it's live, we just use DateTime.now().toUtc()
    // 2. If it's manual, we treat _selectedLocalDateTime as being in _sourceTimeZone.
    
    if (_isLive) {
      return DateTime.now().toUtc();
    } else {
      final sourceTime = tz.TZDateTime(
        location,
        _selectedLocalDateTime.year,
        _selectedLocalDateTime.month,
        _selectedLocalDateTime.day,
        _selectedLocalDateTime.hour,
        _selectedLocalDateTime.minute,
        _selectedLocalDateTime.second,
      );
      return sourceTime.toUtc();
    }
  }

  void _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedLocalDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null) return;

    setState(() {
      _isLive = false;
      _selectedLocalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedLocalDateTime.hour,
        _selectedLocalDateTime.minute,
      );
    });
  }

  void _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedLocalDateTime),
    );

    if (pickedTime == null) return;

    setState(() {
      _isLive = false;
      _selectedLocalDateTime = DateTime(
        _selectedLocalDateTime.year,
        _selectedLocalDateTime.month,
        _selectedLocalDateTime.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _toggleLive() {
    setState(() {
      _isLive = !_isLive;
      if (_isLive) {
        _selectedLocalDateTime = DateTime.now();
      }
    });
  }

  void _addTimeZone(String? zone) {
    if (zone == null) return;
    setState(() {
      if (!_selectedTimeZones.contains(zone)) {
        _selectedTimeZones.add(zone);
      }
    });
  }

  void _removeTimeZone(String zone) {
    setState(() {
      _selectedTimeZones.remove(zone);
    });
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final absoluteOffset = offset.abs();
    final hours = absoluteOffset.inHours.toString().padLeft(2, '0');
    final minutes = (absoluteOffset.inMinutes % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$minutes';
  }

  @override
  Widget build(BuildContext context) {
    final utcDateTime = _sourceUtcDateTime;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Zone Converter'),
        actions: [
          Row(
            children: [
              const Text('Live', style: TextStyle(fontSize: 12)),
              Switch(
                value: _isLive,
                onChanged: (value) => _toggleLive(),
                activeColor: Colors.white,
                activeTrackColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(utcDateTime),
            const SizedBox(height: 16),
            _buildInputPanel(),
            const SizedBox(height: 16),
            _buildAddZonePanel(),
            const SizedBox(height: 16),
            _buildZoneResults(utcDateTime),
            const SizedBox(height: 16),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime utcDateTime) {
    final sourceLocation = tz.getLocation(_resolveTimeZoneLocation(_sourceTimeZone));
    final sourceTime = tz.TZDateTime.from(utcDateTime, sourceLocation);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.deepPurple.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_isLive ? Icons.timer : Icons.schedule),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time Converter',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (_isLive)
                      const Text(
                        'Real-time from Device',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${_formatDate(sourceTime)} ${_formatTime(sourceTime)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            _sourceTimeZone,
            style: TextStyle(fontSize: 14, color: Colors.deepPurple.shade700),
          ),
          const SizedBox(height: 6),
          Text(
            'UTC reference: ${_formatDate(utcDateTime)} ${_formatTime(utcDateTime)}',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Convert From',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final selected = await _showTimeZoneSearchModal(
                  zones: _availableTimeZones,
                  title: 'Select Source Time Zone',
                  currentSelection: _sourceTimeZone,
                );
                if (selected != null) {
                  setState(() => _sourceTimeZone = selected);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Source Time Zone',
                  prefixIcon: Icon(Icons.public),
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _sourceTimeZone,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            if (!_isLive) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(_formatDate(_selectedLocalDateTime)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_formatTime(_selectedLocalDateTime)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _toggleLive,
                  icon: const Icon(Icons.restore),
                  label: const Text('Back to Real-time'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddZonePanel() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Target Time Zones',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final remainingZones = _availableTimeZones
                    .where((zone) => !_selectedTimeZones.contains(zone))
                    .toList();
                final selected = await _showTimeZoneSearchModal(
                  zones: remainingZones,
                  title: 'Add Target Time Zone',
                );
                if (selected != null) {
                  _addTimeZone(selected);
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: const InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select time zone to add',
                  hintText: 'Choose a timezone...',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                child: Text(
                  'Search & choose timezone...',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneResults(DateTime utcDateTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Conversion Results',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._selectedTimeZones.map((zone) {
          final location = tz.getLocation(_resolveTimeZoneLocation(zone));
          final localDateTime = tz.TZDateTime.from(
            utcDateTime,
            location,
          );
          final offset = localDateTime.timeZoneOffset;
          final isSource = zone == _sourceTimeZone;

          return Card(
            elevation: isSource ? 3 : 1,
            color: isSource ? Colors.deepPurple.shade50 : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isSource ? Colors.deepPurple : Colors.grey.shade300,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSource
                          ? Colors.deepPurple.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          zone,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatOffset(offset),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(localDateTime),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(localDateTime),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  if (!isSource)
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => _removeTimeZone(zone),
                      padding: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.checkroom, color: Colors.deepPurple),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Use this for print deadlines, supplier calls, and team '
                'coordination across any time zones worldwide.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showTimeZoneSearchModal({
    required List<String> zones,
    required String title,
    String? currentSelection,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _TimeZoneSearchModal(
          zones: zones,
          title: title,
          currentSelection: currentSelection,
        );
      },
    );
  }
}

class _TimeZoneSearchModal extends StatefulWidget {
  final List<String> zones;
  final String title;
  final String? currentSelection;

  const _TimeZoneSearchModal({
    required this.zones,
    required this.title,
    this.currentSelection,
  });

  @override
  State<_TimeZoneSearchModal> createState() => _TimeZoneSearchModalState();
}

class _TimeZoneSearchModalState extends State<_TimeZoneSearchModal> {
  late List<String> _filteredZones;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredZones = widget.zones;
    _searchController.addListener(_filterZones);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterZones() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredZones = widget.zones
          .where((zone) => zone.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari kota atau wilayah...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _filteredZones.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada zona waktu ditemukan',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredZones.length,
                      itemBuilder: (context, index) {
                        final zone = _filteredZones[index];
                        final isSelected = zone == widget.currentSelection;
                        return ListTile(
                          title: Text(zone),
                          selected: isSelected,
                          selectedColor: Colors.deepPurple,
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.deepPurple)
                              : null,
                          onTap: () => Navigator.pop(context, zone),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
