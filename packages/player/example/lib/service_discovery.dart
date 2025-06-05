import 'dart:convert';

import 'package:mdns_plugin/mdns_plugin.dart';

class ServiceDiscovery {
  ServiceDiscovery(Function(MDNSService)? onFound) {
    _flutterMdnsPlugin = MDNSPlugin(
      DelegateMDNS(
        (MDNSService service) {
          final fn = toUTF8String(service.txt?['fn']);
          if (fn != null) {
            service.map['name'] = fn;
          }
          onFound?.call(service);
        },
      ),
    );
  }
  late MDNSPlugin _flutterMdnsPlugin;
  void startDiscovery() => _flutterMdnsPlugin.startDiscovery(
        '_googlecast._tcp',
        enableUpdating: true,
      );

  void stopDiscovery() => _flutterMdnsPlugin.stopDiscovery();
}

String? toUTF8String(List<int>? bytes) =>
    bytes == null ? null : const Utf8Codec().decode(bytes);

class DelegateMDNS implements MDNSPluginDelegate {
  DelegateMDNS(this.resolved);
  final Function(MDNSService)? resolved;
  @override
  void onDiscoveryStarted() {}
  @override
  void onDiscoveryStopped() {}
  @override
  void onServiceUpdated(MDNSService service) {}
  @override
  void onServiceRemoved(MDNSService service) {}
  @override
  bool onServiceFound(MDNSService service) => true;
  @override
  void onServiceResolved(MDNSService service) {
    resolved?.call(service);
  }
}
