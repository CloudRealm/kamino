/*
   EDMovies - ApolloTV fictional vendor configuration.
*/

import 'package:kamino/external/api/realdebrid.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/external/api/trakt.dart';
import 'package:kamino/vendor/services/ClawsVendorService.dart';
import 'package:kamino/vendor/struct/VendorConfiguration.dart';
import 'package:kamino/vendor/struct/VendorService.dart';

class EDMoviesVendorConfiguration extends VendorConfiguration {

  EDMoviesVendorConfiguration() : super(
      /// The name of the vendor. If you are developing this independently,
      /// use your GitHub name.
      name: "EDMovies",

      services: [
        TMDB(TMDBIdentity(key: "")),
        Trakt(TraktIdentity(
          id: "",
          secret: ""
        )),

        RealDebrid(RealDebridIdentity(
          // See https://api.real-debrid.com/#api_authentication
          // ('Authentication for applications' header)
          clientId: "X245A4XAIBGVM"
        ))
      ]
  );

  @override
  Future<VendorService> getVendorService() async {
    /// If you are using Claws, this is a [ClawsVendorService],
    /// including the port, protocol and trailing slash.
    /// For example: https://claws.edmovies.com/
    return ClawsVendorService(
        server: "http://localhost:3000/",

        // This is the key you set on the server.
        // It should be 32 characters long.
        clawsKey: "",

        // This option allows you to enable the manually select
        // sources option.
        allowSourceSelection: true
    );
  }

}
