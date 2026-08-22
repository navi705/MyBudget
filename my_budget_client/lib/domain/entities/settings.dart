import 'package:equatable/equatable.dart';

class Settings extends Equatable {
  final String key;
  final String value;
  final String device;

  const Settings({
    required this.key,
    required this.value,
    required this.device,
  });

  @override
  List<Object?> get props => [key, value, device];
}
