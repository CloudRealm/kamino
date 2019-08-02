import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kamino/vendor/struct/ThemeConfiguration.dart';

class OfficialVendorTheme {

  static final _DarkVendorTheme dark = _DarkVendorTheme();
  //static final _LightVendorTheme light = _LightVendorTheme();
  static final _BlackVendorTheme black = _BlackVendorTheme();

  static final _SockTheme sockTheme = _SockTheme();

}

class _DarkVendorTheme extends ThemeConfiguration {

  static const _primaryColor = const Color(0xFF8147FF);

  _DarkVendorTheme(): super(
    id: "xyz.apollotv.dark",
    name: "Dark Theme",
    author: "Apollo15",
    allowsVariants: true,
    overlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light
    )
  );

  @override
  ThemeData getThemeData({Color primaryColor : _primaryColor}) {
    var _highlightColor = primaryColor.withOpacity(0.1490);

    var _backgroundColor = Color(0xFF26282C);
    var _cardColor = Color(0xFF2F3136);

    return ThemeData(
      fontFamily: 'Futura',
      brightness: Brightness.dark,
      primaryColorBrightness: Brightness.dark,
      primaryColor: primaryColor,
      accentColor: primaryColor,
      highlightColor: _highlightColor,
      backgroundColor: _backgroundColor,
      cursorColor: primaryColor,
      textSelectionHandleColor: primaryColor,
      buttonColor: primaryColor,
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5)
        ),
      ),
      dialogBackgroundColor: _cardColor,
      buttonTheme: ButtonThemeData(
          buttonColor: primaryColor
      ),
      cardColor: _cardColor,
      bottomAppBarColor: _backgroundColor,
      scaffoldBackgroundColor: _cardColor,
      canvasColor: _backgroundColor,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor)),
        hintStyle: TextStyle(
          color: Colors.grey[400]
        )
      )
    );
  }

}

/*
class _LightVendorTheme extends ThemeConfiguration {

  static const _primaryColor = const Color(0xFFA279FB);

  _LightVendorTheme(): super(
    id: "xyz.apollotv.light",
    name: "ApolloTV Official (Light)",
    author: "Apollo15",
    allowsVariants: true,
    overlayStyle: SystemUiOverlayStyle.light.copyWith(
      statusBarBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark
    )
  );

  @override
  ThemeData getThemeData({Color primaryColor : _primaryColor}) {
    var _highlightColor = primaryColor.withOpacity(0.1490);

    var _backgroundColor = Color(0xFFECF0F1);
    var _cardColor = Color(0xFFeff3f4);

    return ThemeData(
      brightness: Brightness.light,
      primaryColorBrightness: Brightness.light,
      accentColorBrightness: Brightness.dark,
      primaryColor: primaryColor,
      accentColor: primaryColor,
      highlightColor: _highlightColor,
      backgroundColor: _backgroundColor,
      cursorColor: primaryColor,
      textSelectionHandleColor: primaryColor,
      buttonColor: primaryColor,
      dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5)
          )
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: primaryColor,
        textTheme: ButtonTextTheme.primary,
      ),
      dialogBackgroundColor: _backgroundColor,
      cardColor: _cardColor,
      bottomAppBarColor: _backgroundColor,
      scaffoldBackgroundColor: _cardColor,
      canvasColor: _backgroundColor,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor)),
        hintStyle: TextStyle(
          color: Colors.grey[400]
        )
      )
    );
  }

}
*/

class _BlackVendorTheme extends ThemeConfiguration {

  static const _primaryColor = const Color(0xFF8147FF);

  _BlackVendorTheme(): super(
    id: "xyz.apollotv.black",
    name: "AMOLED Theme",
    author: "Apollo15",
    allowsVariants: true,
    overlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light
    ),
  );

  @override
  ThemeData getThemeData({Color primaryColor : _primaryColor}) {
    var _highlightColor = primaryColor.withOpacity(0.1490);

    var _backgroundColor = Color(0xFF000000);
    var _cardColor = _backgroundColor;

    return ThemeData(
      fontFamily: 'Futura',
      brightness: Brightness.dark,
      primaryColorBrightness: Brightness.dark,
      primaryColor: primaryColor,
      accentColor: primaryColor,
      highlightColor: _highlightColor,
      backgroundColor: _backgroundColor,
      cursorColor: primaryColor,
      textSelectionHandleColor: primaryColor,
      buttonColor: primaryColor,
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5)
        ),
      ),
      dialogBackgroundColor: _cardColor,
      buttonTheme: ButtonThemeData(
          buttonColor: primaryColor
      ),
      cardColor: _cardColor,
      bottomAppBarColor: _backgroundColor,
      scaffoldBackgroundColor: _cardColor,
      canvasColor: _backgroundColor,
      inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor)),
          hintStyle: TextStyle(
              color: Colors.grey[400]
          )
      )
    );
  }

}


class _SockTheme extends ThemeConfiguration {

  static const _primaryColor = const Color(0xFFFF0000);

  _SockTheme(): super(
    id: "xyz.apollotv.sock",
    name: "Socks Theme",
    author: "NBTX",
    allowsVariants: true,
    overlayStyle: SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.light
    ),
    selectable: false
  );

  @override
  ThemeData getThemeData({Color primaryColor : _primaryColor}) {
    var _highlightColor = primaryColor.withOpacity(0.1490);

    var _backgroundColor = Color(0xFF0000FF);
    var _cardColor = _backgroundColor;

    return _DarkVendorTheme().getThemeData(primaryColor: _primaryColor).copyWith(
        primaryColor: primaryColor,
        accentColor: primaryColor,
        highlightColor: _highlightColor,
        backgroundColor: _backgroundColor,
        cursorColor: primaryColor,
        textSelectionHandleColor: primaryColor,
        buttonColor: primaryColor,
        dialogBackgroundColor: _cardColor,
        buttonTheme: ButtonThemeData(
            buttonColor: primaryColor
        ),
        cardColor: _cardColor,
        bottomAppBarColor: _backgroundColor,
        scaffoldBackgroundColor: _cardColor,
        canvasColor: _backgroundColor,
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderSide: BorderSide(color: _primaryColor)),
            hintStyle: TextStyle(
                color: Colors.grey[400]
            )
        )
    );
  }

}