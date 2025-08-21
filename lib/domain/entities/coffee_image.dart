import 'package:equatable/equatable.dart';

class CoffeeImage extends Equatable {
  const CoffeeImage({
    required this.id,
    required this.remoteUrl,
  });

  final String id;
  final Uri remoteUrl;

  @override
  List<Object?> get props => [id, remoteUrl];
}
