import 'package:kamino/external/ExternalService.dart';

abstract class PremiumHostService extends Service {

  PremiumHostService(String name, {
    List<ServiceType> types = const [ServiceType.PREMIUM_HOST],
    bool isPrimaryService
  }) : super(
    name,
    types,
    isPrimaryService: isPrimaryService
  );

}