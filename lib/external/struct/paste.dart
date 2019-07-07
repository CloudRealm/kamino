import 'package:kamino/external/ExternalService.dart';

abstract class PasteService extends Service {

  PasteService(String name, {
    List<ServiceType> types = const [ServiceType.PASTE],
    bool isPrimaryService
  }) : super(
    name,
    types,
    isPrimaryService: isPrimaryService
  );

  Future<String> paste(String data, {
    String title,
    String fileFormat
  });

}