abstract class ErrorBase {
  final String message;

  ErrorBase({required this.message});
}

class Failure extends ErrorBase {
  Failure({required super.message});
}
