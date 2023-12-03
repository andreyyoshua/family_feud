import 'package:json_annotation/json_annotation.dart';

enum Mode {
  @JsonValue(1)
  membering, 
  @JsonValue(2)
  gameStarted, 
  @JsonValue(3)
  gameFinished
}