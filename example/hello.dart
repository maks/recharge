import 'dart:async';
import 'dart:isolate';
import 'package:recharge/recharge.dart';

// Build recharge. Execute main after reload.
var recharge = Recharge(
  onReload: () => main(),
);

void main() async {
  // Initialize recharge
  await recharge.init();

  // Say hello. After running change this text
  // and save it again.
  print(mesg());

  final isolate = await Isolate.spawn<String>(worker, 'hi');
  print("iso started: $isolate");
}

String mesg() => "Hello world";

void worker(String message) async {
  print("iso mesg: $message");
  while (true) {
    await Future.delayed(Duration(seconds: 1));
  }
}
