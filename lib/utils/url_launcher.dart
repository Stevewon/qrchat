// 조건부 export: 웹이면 url_launcher_web.dart, 아니면 url_launcher_stub.dart
export 'url_launcher_stub.dart'
    if (dart.library.html) 'url_launcher_web.dart';
