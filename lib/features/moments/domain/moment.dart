/// Which way a moment counts.
enum MomentDirection { down, up, both }

/// Moment categories from the specification, section 6.
enum MomentCategory {
  birthday,
  exam,
  travel,
  work,
  health,
  festival,
  memorial,
  custom,
}

/// One record that moves through Next, Now and Then on its own.
class Moment {
  const Moment({
    required this.id,
    required this.title,
    required this.targetUtc,
    this.subtitle,
    this.endUtc,
    this.isAllDay = true,
    this.direction = MomentDirection.down,
    this.category = MomentCategory.custom,
    this.notes,
    required this.createdAtUtc,
    this.pinned = false,
  });

  final String id;
  final String title;
  final String? subtitle;

  /// The instant the moment happens. For an ongoing event this is its start.
  final DateTime targetUtc;

  /// Optional end for ongoing moments such as a trip.
  final DateTime? endUtc;

  final bool isAllDay;
  final MomentDirection direction;
  final MomentCategory category;
  final String? notes;
  final DateTime createdAtUtc;
  final bool pinned;

  bool get isOngoing => endUtc != null && endUtc!.isAfter(targetUtc);

  Moment copyWith({
    String? title,
    String? subtitle,
    DateTime? targetUtc,
    DateTime? endUtc,
    bool? isAllDay,
    MomentDirection? direction,
    MomentCategory? category,
    String? notes,
    bool? pinned,
  }) {
    return Moment(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      targetUtc: targetUtc ?? this.targetUtc,
      endUtc: endUtc ?? this.endUtc,
      isAllDay: isAllDay ?? this.isAllDay,
      direction: direction ?? this.direction,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAtUtc: createdAtUtc,
      pinned: pinned ?? this.pinned,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'targetUtc': targetUtc.toUtc().toIso8601String(),
    'endUtc': endUtc?.toUtc().toIso8601String(),
    'isAllDay': isAllDay,
    'direction': direction.name,
    'category': category.name,
    'notes': notes,
    'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
    'pinned': pinned,
  };

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      targetUtc: DateTime.parse(json['targetUtc'] as String).toUtc(),
      endUtc: json['endUtc'] == null
          ? null
          : DateTime.parse(json['endUtc'] as String).toUtc(),
      isAllDay: json['isAllDay'] as bool? ?? true,
      direction: MomentDirection.values.firstWhere(
        (value) => value.name == json['direction'],
        orElse: () => MomentDirection.down,
      ),
      category: MomentCategory.values.firstWhere(
        (value) => value.name == json['category'],
        orElse: () => MomentCategory.custom,
      ),
      notes: json['notes'] as String?,
      createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toUtc(),
      pinned: json['pinned'] as bool? ?? false,
    );
  }
}
