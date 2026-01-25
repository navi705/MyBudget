import 'package:equatable/equatable.dart';

class Language extends Equatable {
  final String language;
  final String languageCode;
  
  const Language({
    required this.language,
    required this.languageCode
  });



  @override 
  List<Object?> get props => [language, languageCode];
}