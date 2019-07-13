/*
   This file contains project API keys.
   DO NOT, under any circumstances, commit this file.
*/

import 'package:kamino/util/settings.dart';
import 'package:kamino/vendor/services/ClawsVendorService.dart';
import 'package:kamino/vendor/struct/VendorConfiguration.dart';
import 'package:kamino/vendor/struct/VendorService.dart';

class ShimVendorConfiguration extends VendorConfiguration {

  ShimVendorConfiguration() : super(
    name: "UserCustomizableShimVendor",
    services: []
  );

  @override
  Future<VendorService> getVendorService() async {
    return ClawsVendorService(
      server: await Settings.serverURLOverride,
      clawsKey: await Settings.serverKeyOverride,
      isOfficial: false,
      allowSourceSelection: true
    );
  }

}