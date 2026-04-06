class RemoteConfigService {
  static final RemoteConfigService _instance =
      RemoteConfigService._internal();

  factory RemoteConfigService() => _instance;

  RemoteConfigService._internal();

  Map<String, dynamic> _config = {};

  void setConfig(Map<String, dynamic> config) {
    _config = config;
  }

  Map<String, dynamic> get config => _config;
}