enum ServiceType {
  CONTENT_DATABASE, CONTENT_TRACKER,
  SUBTITLES,

  /// Services that cache or host content and serve
  /// them with unrestricted bandwidth.
  PREMIUM_HOST,

  /// Service that can post data that is sent to it.
  /// e.g. Pastebin, Hastebin, paste.ee
  PASTE
}

class ServiceManager {

  static ServiceManager _instance;
  static ServiceManager getInstance(){
    if(_instance == null) _instance = new ServiceManager();
    return _instance;
  }

  Map<ServiceType, List<Service>> _services;
  ServiceManager(){
    _services = new Map();
  }

  void registerService(Service service){
    print("Registering external service: " + service.name);
    service.types.forEach((ServiceType type){
      if(_services[type] == null) _services[type] = new List();
      if( service.isPrimaryService && _services[type].where((s) => s.isPrimaryService).isNotEmpty ){
        throw new Exception("Multiple services of type " + type.toString() + " have been declared primary services.");
      }

      _services[type].add(service);
    });
  }

  void unregisterService(Service service){
    service.types.forEach((ServiceType type){
      _services[type].remove(service);
    });
  }

}

class Service {

  final String name;
  final List<ServiceType> types;
  final bool _isPrimaryService;

  bool get isPrimaryService => _isPrimaryService ?? false;

  Service(this.name, this.types, {
    isPrimaryService = false
  }) : _isPrimaryService = isPrimaryService;

  @override
  bool operator ==(other) {
    return this.name == other.name;
  }

  @override
  int get hashCode => int.parse(
      this.name.split("").map((String char) => char.codeUnitAt(0)).join("")
  );

  static List<Service> ofType(ServiceType type){
    return ServiceManager.getInstance()._services[type];
  }

  ///
  /// Fetches the primary [Service] of a given type.
  /// Returns the first [Service] if there is no explicit primary service.
  /// If [onlyExplicit] is set, this returns null if no explicit primary service is set.
  ///
  /// To mark a service as the explicit primary service, use [Service.isPrimaryService].
  ///
  /// Examples of a primary service include TMDB for [ServiceType.CONTENT_DATABASE].
  ///
  static T primaryOfType<T>(ServiceType type, { bool onlyExplicit = false }){
    return ServiceManager.getInstance()._services[type]
        .firstWhere(
            (Service service) => service.isPrimaryService,
            orElse: () => null
    ) as T;
  }

  static T get<T>(){
    return getAll().firstWhere(
        (Service service) => service.runtimeType == T,
        orElse: () => null
    ) as T;
  }

  static List<Service> getAll(){
    return ServiceManager.getInstance()._services.values
        .expand((List<Service> services) => services).toList();
  }

}