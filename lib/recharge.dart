import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:vm_service/vm_service.dart' show IsolateRef, VmService;
import 'package:vm_service/vm_service_io.dart' as vms;
import 'package:vm_service/utils.dart' as vmutils;

// Recharge watches for changes in given path and reloads
// VM on an event. It reports back this with the onReload
// callback.
class Recharge {
  final void Function() onReload;

  VmService _service;

  Recharge({this.onReload}) {
    // Start watching for file changes in the path
    print("Starting recharge pid: $pid");
    listenForSignal();
  }

  void listenForSignal() {
    ProcessSignal.sigusr1.watch().listen((signal) async {
      print("sig: $signal");
      if (await reload()) onReload?.call();
    });
  }

  // init builds websocket endpoint from observatory URL
  init() async {
    // Observatory URL is like: http://127.0.0.1:8181/u31D8b3VvmM=/
    // Websocket endpoint for that will be: ws://127.0.0.1:8181/reBbXy32L6g=/ws
    print('init');
    final serverUri = (await dev.Service.getInfo()).serverUri;
    if (serverUri == null) {
      throw Exception("No VM service. Run with --enable-vm-service");
    }
    final wsUri = vmutils.convertToWebSocketUrl(serviceProtocolUrl: serverUri);

    // Get VM service
    _service = await vms.vmServiceConnectUri(wsUri.toString());
  }

  // Reloads all isolates and return whether it was successful or not
  Future<bool> reload() async {
    if (_service == null) {
      throw Exception("Recharge not initilized. Call init() with await.");
    }
    // Reload all isolates
    final vm = await _service.getVM();
    List<IsolateRef> _isolates = vm.isolates;
    final List<bool> results = [];
    for (var i in _isolates) {
      print('reloading isolate: ${i}');
      final res = await _service.reloadSources(i.id, force: true);
      results.add(res.success == true);
      if (res.success) {
        print("Reload success");
      } else {
        print("Reload failed");
        try {
          print(res.json["notices"][0]["message"]);
        } catch (e) {}
      }
    }
    return results.contains(false) ? false : true;
  }
}
