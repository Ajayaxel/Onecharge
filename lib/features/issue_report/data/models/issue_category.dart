import 'package:equatable/equatable.dart';

class IssueCategory extends Equatable {
  const IssueCategory({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory IssueCategory.fromJson(Map<String, dynamic> json) {
    return IssueCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
    );
  }

  @override
  List<Object> get props => [id, name];
}

