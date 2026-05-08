class SystemService {
  final String name;
  final String displayName;
  final String state; // active, inactive, failed
  final String subState;
  final bool enabled; // enabled, disabled, static

  SystemService({
    required this.name,
    required this.displayName,
    required this.state,
    required this.subState,
    required this.enabled,
  });

  factory SystemService.fromString(String line) {
    // Parse output from: systemctl list-units --all --no-pager --output=json
    // For simple parsing from status line
    final parts = line.split(RegExp(r'\s+'));
    if (parts.length >= 4) {
      return SystemService(
        name: parts[0],
        displayName: parts[0],
        state: parts[2],
        subState: parts[3],
        enabled: parts[2].contains('active'),
      );
    }
    return SystemService(
      name: 'unknown',
      displayName: 'Unknown',
      state: 'unknown',
      subState: 'unknown',
      enabled: false,
    );
  }

  factory SystemService.fromJson(Map<String, dynamic> json) {
    return SystemService(
      name: json['unit'] ?? 'unknown',
      displayName: json['description'] ?? json['unit'] ?? 'Unknown',
      state: json['active_state'] ?? 'unknown',
      subState: json['sub_state'] ?? 'unknown',
      enabled: (json['enabled_state'] ?? 'disabled') != 'disabled',
    );
  }

  bool get isActive => state == 'active' || state.contains('activ');
}
