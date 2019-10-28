/*
    This is the ApolloVendor configuration file.
    (Location: /lib/vendor/index.dart)
*/

import 'package:kamino/vendor/struct/ThemeConfiguration.dart';
import 'package:kamino/vendor/struct/VendorConfiguration.dart';
import 'package:kamino/vendor/themes/OfficialVendorThemes.dart';
import 'package:kamino/vendor/dist/OfficialVendorConfiguration.dart';

class ApolloVendor {

  static List<VendorConfiguration> getVendorConfigs(){
    return [
      // The main vendor configuration is always list[0].
      // You should change this to your preferred vendor configuration.
      new OfficialVendorConfiguration()

      // The rest are secondary vendor configurations.
      // The priority of the configuration is determined by its position in
      // the list.
    ];
  }

  static List<ThemeConfiguration> getThemeConfigs(){
    return [
      // The main theme configuration is always at index 0.
      // You should change this to your preferred theme configuration.
      OfficialVendorTheme.dark,

      // The rest are secondary theme configurations.
      // They can be chosen by the user.
      //OfficialVendorTheme.light,
      OfficialVendorTheme.black,

      // Easter egg theme.
      OfficialVendorTheme.sockTheme
    ];
  }

}
