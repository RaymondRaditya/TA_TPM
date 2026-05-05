import 'package:flutter/material.dart';

class TimeZoneConverterScreen extends StatefulWidget {
  const TimeZoneConverterScreen({super.key});

  @override
  State<TimeZoneConverterScreen> createState() =>
      _TimeZoneConverterScreenState();
}

class _TimeZoneConverterScreenState extends State<TimeZoneConverterScreen> {
  static const List<_TimeZoneInfo> _zones = [
    _TimeZoneInfo(
      code: 'WIB',
      name: 'Western Indonesia Time',
      city: 'Jakarta',
      baseUtcOffsetHours: 7,
    ),
    _TimeZoneInfo(
      code: 'WITA',
      name: 'Central Indonesia Time',
      city: 'Makassar',
      baseUtcOffsetHours: 8,
    ),
    _TimeZoneInfo(
      code: 'WIT',
      name: 'Eastern Indonesia Time',
      city: 'Jayapura',
      baseUtcOffsetHours: 9,
    ),
    _TimeZoneInfo(
      code: 'London',
      name: 'London Time',
      city: 'London',
      baseUtcOffsetHours: 0,
      observesUkDaylightSaving: true,
    ),
  ];

  String _sourceZoneCode = 'WIB';
  late DateTime _selectedLocalDateTime;

  @override
  void initState() {
    super.initState();
    _selectedLocalDateTime = DateTime.now();
  }

  _TimeZoneInfo get _sourceZone {
    return _zones.firstWhere((zone) => zone.code == _sourceZoneCode);
  }

  DateTime get _sourceUtcDateTime {
    final offset = _sourceZone.offsetForLocalDate(_selectedLocalDateTime);
    return _selectedLocalDateTime.subtract(offset);
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedLocalDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedLocalDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        _selectedLocalDateTime.hour,
        _selectedLocalDateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedLocalDateTime),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedLocalDateTime = DateTime(
        _selectedLocalDateTime.year,
        _selectedLocalDateTime.month,
        _selectedLocalDateTime.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _useCurrentTime() {
    setState(() {
      _selectedLocalDateTime = DateTime.now();
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
    return '$hour:$minute';
  }

  String _formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final absoluteOffset = offset.abs();
    final hours = absoluteOffset.inHours.toString();
    return 'UTC$sign$hours';
  }

  @override
  Widget build(BuildContext context) {
    final utcDateTime = _sourceUtcDateTime;

    return Scaffold(
      appBar: AppBar(title: const Text('Time Zone Converter')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(utcDateTime),
            const SizedBox(height: 16),
            _buildInputPanel(),
            const SizedBox(height: 16),
            _buildZoneResults(utcDateTime),
            const SizedBox(height: 16),
            _buildCourseUseCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(DateTime utcDateTime) {
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
                child: const Icon(Icons.schedule),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Production Time Planner',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            '${_formatDate(_selectedLocalDateTime)} '
            '${_formatTime(_selectedLocalDateTime)} $_sourceZoneCode',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'UTC reference: ${_formatDate(utcDateTime)} ${_formatTime(utcDateTime)}',
            style: TextStyle(color: Colors.grey.shade700),
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
          children: [
            DropdownButtonFormField<String>(
              value: _sourceZoneCode,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Source time zone',
                prefixIcon: Icon(Icons.public),
                border: OutlineInputBorder(),
              ),
              items: _zones
                  .map(
                    (zone) => DropdownMenuItem<String>(
                      value: zone.code,
                      child: Text('${zone.code} - ${zone.city}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _sourceZoneCode = value);
              },
            ),
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
                onPressed: _useCurrentTime,
                icon: const Icon(Icons.my_location),
                label: const Text('Use Current Time'),
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
      children: _zones.map((zone) {
        final offset = zone.offsetForUtcDate(utcDateTime);
        final localDateTime = utcDateTime.add(offset);
        final isSource = zone.code == _sourceZoneCode;

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
                  child: Icon(
                    zone.observesUkDaylightSaving
                        ? Icons.nightlight_round
                        : Icons.wb_sunny,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${zone.code} - ${zone.city}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${zone.name} (${_formatOffset(offset)})'),
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
                    Text(_formatDate(localDateTime)),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseUseCard() {
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
                'Use this for print deadlines, supplier calls, and TPM project '
                'team coordination across Indonesia and London.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeZoneInfo {
  const _TimeZoneInfo({
    required this.code,
    required this.name,
    required this.city,
    required this.baseUtcOffsetHours,
    this.observesUkDaylightSaving = false,
  });

  final String code;
  final String name;
  final String city;
  final int baseUtcOffsetHours;
  final bool observesUkDaylightSaving;

  Duration offsetForLocalDate(DateTime localDateTime) {
    if (!observesUkDaylightSaving) {
      return Duration(hours: baseUtcOffsetHours);
    }

    return Duration(hours: _isUkDaylightSavingByLocalDate(localDateTime) ? 1 : 0);
  }

  Duration offsetForUtcDate(DateTime utcDateTime) {
    if (!observesUkDaylightSaving) {
      return Duration(hours: baseUtcOffsetHours);
    }

    return Duration(hours: _isUkDaylightSavingByUtcDate(utcDateTime) ? 1 : 0);
  }

  bool _isUkDaylightSavingByLocalDate(DateTime localDateTime) {
    final startDate = _lastSundayOfMonth(localDateTime.year, DateTime.march);
    final endDate = _lastSundayOfMonth(localDateTime.year, DateTime.october);
    final dstStartLocal = DateTime(
      localDateTime.year,
      DateTime.march,
      startDate.day,
      2,
    );
    final dstEndLocal = DateTime(
      localDateTime.year,
      DateTime.october,
      endDate.day,
      2,
    );

    return !localDateTime.isBefore(dstStartLocal) &&
        localDateTime.isBefore(dstEndLocal);
  }

  bool _isUkDaylightSavingByUtcDate(DateTime utcDateTime) {
    final startDate = _lastSundayOfMonth(utcDateTime.year, DateTime.march);
    final endDate = _lastSundayOfMonth(utcDateTime.year, DateTime.october);
    final dstStartUtc = DateTime(
      utcDateTime.year,
      DateTime.march,
      startDate.day,
      1,
    );
    final dstEndUtc = DateTime(
      utcDateTime.year,
      DateTime.october,
      endDate.day,
      1,
    );

    return !utcDateTime.isBefore(dstStartUtc) &&
        utcDateTime.isBefore(dstEndUtc);
  }

  DateTime _lastSundayOfMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return lastDay.subtract(Duration(days: lastDay.weekday % 7));
  }
}
