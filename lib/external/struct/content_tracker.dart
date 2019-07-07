import 'package:kamino/external/ExternalService.dart';

abstract class ContentTrackerService extends Service {

  ContentTrackerService(String name, {
    List<ServiceType> types = const [ServiceType.CONTENT_TRACKER],
    bool isPrimaryService
  }) : super(
      name,
      types,
      isPrimaryService: isPrimaryService
  );

}