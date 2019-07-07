#!/bin/bash
TMDB_KEY="$1"
TRAKT_ID="$2"
TRAKT_SECRET="$3"
CLAWS_URL_BETA="$4"
CLAWS_KEY_BETA="$5"
VENDOR_NAME="$6"
TRAVIS_BUILD_NUMBER="$7"

cat <<____HERE
/*
   Travis-CI - ApolloTV automated vendor configuration.
*/

import 'package:kamino/external/api/paste.dart';
import 'package:kamino/external/api/realdebrid.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/external/api/trakt.dart';
import 'package:kamino/vendor/services/ClawsVendorService.dart';
import 'package:kamino/vendor/struct/VendorConfiguration.dart';
import 'package:kamino/vendor/struct/VendorService.dart';

class OfficialVendorConfiguration extends VendorConfiguration {

  OfficialVendorConfiguration() : super(
      /// The name of the vendor. If you are developing this independently,
      /// use your GitHub name.
      name: "`echo $VENDOR_NAME` (#`echo $TRAVIS_BUILD_NUMBER`)",

      services: [
        TMDB(TMDBIdentity(
          key: "`echo $TMDB_KEY`"
        )),

        Trakt(TraktIdentity(
          id: "`echo $TRAKT_ID`",
          secret: "`echo $TRAKT_SECRET`"
        )),

        RealDebrid(RealDebridIdentity(
          // See https://api.real-debrid.com/#api_authentication
          // ('Authentication for applications' header)
          clientId: "X245A4XAIBGVM"
        )),

        PasteEE(PasteEEIdentity(
          token: "`echo $PASTE_TOKEN`"
        ))
      ]
  );

  @override
  Future<VendorService> getVendorService() async {
      return ClawsVendorService(
          server: "`echo $CLAWS_URL_BETA`",
          clawsKey: "`echo $CLAWS_KEY_BETA`",
          isOfficial: true,
          allowSourceSelection: true
      );
  }

}
____HERE
