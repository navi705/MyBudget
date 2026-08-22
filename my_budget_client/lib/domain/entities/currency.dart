import 'package:equatable/equatable.dart';

enum TypeCurrency {
  currency,
  crypto,
  commoditity,
  obligation,
  stock,
  realAsset,
  other,
}

class Currency extends Equatable {
  final String name;
  final String code;
  final String languageCode;
  final TypeCurrency type;

  const Currency({
    required this.name,
    required this.code,
    required this.languageCode,
    required this.type,
  });

  Currency copyWith({
    String? name,
    String? code,
    String? languageCode,
    TypeCurrency? type,
  }) {
    return Currency(
      name: name ?? this.name,
      code: code ?? this.code,
      languageCode: languageCode ?? this.languageCode,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [name, code, languageCode, type];
}
