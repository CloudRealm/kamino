import 'package:flutter/material.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/vendor/struct/VendorService.dart';
import 'package:meta/meta.dart';

abstract class VendorConfiguration {

  final String name;

  ///
  /// A VendorConfiguration should be used to change the default settings in the
  /// ApolloTV app. Simply create your own class and extend [VendorConfiguration].
  ///
  /// [name] - The name of the vendor. If you are developing this independently,
  ///           use your GitHub name.
  ///
  /// [services] - Any services you wish to register for this vendor. You should
  ///               also use this to provide credentials for any of these
  ///               services.
  ///
  VendorConfiguration({
    @required this.name,
    @required List<Service> services
  }){
    services.forEach(
            (Service service) =>
                ServiceManager.getInstance().registerService(service)
    );
  }

  ///
  /// Returns the name of the Vendor, as provided when the configuration object
  /// was initialized.
  ///
  String getName(){
    return name;
  }

  Future<VendorService> getVendorService();

  dynamic execCommand(String command){
    throw new Exception("Feature not implemented.");
  }

}