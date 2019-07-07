import 'package:kamino/external/ExternalService.dart';

abstract class ContentDatabaseService extends Service {

  ContentDatabaseService(String name, {
    List<ServiceType> types = const [ServiceType.CONTENT_DATABASE],
    bool isPrimaryService
  }) : super(
    name,
    types,
    isPrimaryService: isPrimaryService
  );

}