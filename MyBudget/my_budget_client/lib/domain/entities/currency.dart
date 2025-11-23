import 'package:equatable/equatable.dart';

class Currency extends Equatable {
  final String name;
  final String code;

  const Currency({
    required this.name,
    required this.code,
  });

  Currency copyWith({
    String? name,
    String? code,
  }) {
    return Currency(
      name: name ?? this.name,
      code: code ?? this.code,
    );
  }

  @override
  List<Object?> get props => [name, code];
}
