import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/main.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/interface/settings/page.dart';

import 'package:flutter_material_color_picker/flutter_material_color_picker.dart';
import 'package:kamino/util/settings.dart';

class AppearanceSettingsPage extends SettingsPage {

  AppearanceSettingsPage(BuildContext context, {bool isPartial = false}) : super(
    title: S.of(context).appearance,
    pageState: AppearenceSettingsPageState(),
    isPartial: isPartial
  );

}


class AppearenceSettingsPageState extends SettingsPageState {

  bool _detailedContentInfoEnabled = false;

  @override
  void initState() {
    (Settings.detailedContentInfoEnabled as Future).then((data){
      setState(() {
        _detailedContentInfoEnabled = data;
      });
    });

    super.initState();
  }

  @override
  Widget buildPage(BuildContext context) {
    KaminoAppState appState = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());

    return ListView(
      physics: widget.isPartial ? NeverScrollableScrollPhysics() : null,
      shrinkWrap: widget.isPartial ? true : false,
      children: <Widget>[
        SubtitleText(S.of(context).theme, padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 5)),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            leading: Icon(Icons.palette),
            title: TitleText(S.of(context).change_theme),
            subtitle: Text(
                "${appState.getActiveThemeMeta().getName()} (${S.of(context).by_x(appState.getActiveThemeMeta().getAuthor())})"
            ),
            onTap: () => showThemeChoice(context, appState),
          ),
        ),

        Material(
          color: widget.isPartial ? Theme.of(context).cardColor : Theme.of(context).backgroundColor,
          child: ListTile(
            title: TitleText(S.of(context).set_primary_color),
            subtitle: Text(
                PrimaryColorChooser.colorToHexString(Theme.of(context).primaryColor).toUpperCase()
            ),
            leading: CircleColor(
              circleSize: 32,
              color: Theme.of(context).primaryColor,
            ),
            onTap: () => setPrimaryColor(context, appState),
          ),
        ),

        SubtitleText(S.of(context).layout, padding: EdgeInsets.symmetric(vertical: 30, horizontal: 15).copyWith(bottom: 0)),

        Container(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              ButtonBar(
                alignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  VerticalIconButton(
                    backgroundColor: _detailedContentInfoEnabled ? Theme.of(context).primaryColor : null,
                    onTap: () async {
                      await (Settings.detailedContentInfoEnabled = true);
                      _detailedContentInfoEnabled = await Settings.detailedContentInfoEnabled;
                      setState(() {});
                    },
                    title: TitleText(S.of(context).card_layout),
                    icon: Icon(Icons.view_agenda),

                  ),
                  VerticalIconButton(
                    backgroundColor: !_detailedContentInfoEnabled ? Theme.of(context).primaryColor : null,
                    onTap: () async {
                      await (Settings.detailedContentInfoEnabled = false);
                      _detailedContentInfoEnabled = await Settings.detailedContentInfoEnabled;
                      setState(() {});
                    },
                    title: TitleText(S.of(context).grid_layout),
                    icon: Icon(Icons.grid_on),
                  )
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}

void setPrimaryColor(BuildContext context, KaminoAppState appState){
  showDialog(
      context: context,
      builder: (BuildContext dialog){
        return PrimaryColorChooser(
            initialColor: Theme.of(context).primaryColor
        );
      }
  );
}

void showThemeChoice(BuildContext context, KaminoAppState appState){
  showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialog){
        int _counter = 0;

        return AlertDialog(
          // Title Row
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  GestureDetector(
                    child: Icon(Icons.palette),
                    onTap: (){
                      _counter++;

                      if(_counter == 5){
                        appState.setActiveTheme("xyz.apollotv.sock");
                        appState.setPrimaryColorOverride(const Color(0xFFFF0000));
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: TitleText(S.of(context).change_theme),
                  )
                ],
              )
            ],
          ),

          // Body
          content: Container(
            width: MediaQuery.of(context).size.width * 0.75,
            child: ListView.builder(
                shrinkWrap: true,
                itemCount: appState.getThemeConfigs().length,
                itemBuilder: (listContext, index){
                  var theme = appState.getThemeConfigs()[index];

                  return ListTile(
                      onTap: (){
                        Navigator.of(context).pop();
                        appState.setActiveTheme(theme.getId());
                      },
                      title: TitleText(theme.getName()),
                      subtitle: Text(theme.getAuthor())
                  );
                }
            ),
          ),
        );
      }
  );
}

/***** COLOR CHOOSER CODE *****/
class PrimaryColorChooser extends StatefulWidget {

  final Color initialColor;

  const PrimaryColorChooser({Key key, @required this.initialColor}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PrimaryColorChooserState(initialColor);

  static String colorToHexString(Color color){
    return "#" + color.red.toRadixString(16).padLeft(2, '0') +
        color.green.toRadixString(16).padLeft(2, '0') +
        color.blue.toRadixString(16).padLeft(2, '0');
  }

}

class _PrimaryColorChooserState extends State<PrimaryColorChooser> {

  bool _isAdvancedMode;
  TextEditingController _hexInput;

  Color _activeColor;
  KaminoAppState appState;

  _PrimaryColorChooserState(Color initialColor){
    _hexInput = new TextEditingController();
    _isAdvancedMode = false;
    _activeColor = initialColor;
  }

  @override
  Widget build(BuildContext context) {
    appState = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());

    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleColor(
                circleSize: 32,
                color: _activeColor,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: TitleText(S.of(context).set_primary_color),
              )
            ],
          )
        ],
      ),
      content: new Container(
        width: MediaQuery.of(context).size.width * 0.75.clamp(0, 720),
        child: NotificationListener<OverscrollIndicatorNotification>(
          onNotification: (notification){
            notification.disallowGlow();
            return false;
          },
          child: ListView(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: <Widget>[
              if(!_isAdvancedMode) Container(
                height: 200,
                child: MaterialColorPicker(
                    onColorChange: (Color color) => setState(() => _activeColor = color),
                    selectedColor: _activeColor,
                    colors: () {
                      // Return list of colors including the current primary color
                      List<ColorSwatch<dynamic>> _anonymousColors = new List();
                      _anonymousColors.addAll(materialColors);

                      // Replace Material Design purple with ApolloTV purple.
                      _anonymousColors.insert(0, ColorSwatch(0xFF8147FF, {500: const Color(0xFF8147FF)}));
                      _anonymousColors.remove(Colors.deepPurple);

                      if(_findMainColor(_activeColor, _anonymousColors) == null) {
                        _anonymousColors.add(
                            ColorSwatch(_activeColor.value, <int, Color>{
                              500: _activeColor
                            }));
                      }
                      return _anonymousColors;
                    }()
                ),
              ),

              if(_isAdvancedMode) Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    textSelectionColor: _activeColor,
                    textSelectionHandleColor: _activeColor,
                    primaryColor: _activeColor,
                    accentColor: _activeColor
                  ),
                  child: TextField(
                    controller: _hexInput,
                    maxLength: 6,
                    maxLengthEnforced: true,
                    cursorColor: _activeColor,
                    decoration: InputDecoration(
                        prefix: Text("#"),
                        labelText: "Hex Color Code",
                        counterText: "",
                        hoverColor: _activeColor,
                        focusColor: _activeColor,
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _activeColor))
                    ),
                    autofocus: true,
                    onChanged: (value){
                      setState(() {
                        if(value.length == 6)
                          _activeColor = Color(int.parse("0xFF" + value));
                      });
                    },
                    inputFormatters: [
                      TextInputFormatter.withFunction((oldValue, newValue){
                        return TextEditingValue(
                          text: newValue.text?.toUpperCase(),
                          selection: newValue.selection,
                        );
                      }),
                      WhitelistingTextInputFormatter(RegExp('[0-9A-F]'))
                    ],
                  ),
                ),
              ),

              new Container(
                  child: new Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      new FlatButton(
                          onPressed: () {
                            _hexInput.text = PrimaryColorChooser.colorToHexString(_activeColor)
                                .toUpperCase().replaceFirst("#", "");

                            setState(() => _isAdvancedMode = !_isAdvancedMode);
                          },
                          child: Text(
                            _isAdvancedMode ? S.of(context).chooser : S.of(context).hex,
                            style: TextStyle(color: _activeColor),
                          )
                      ),

                      new RaisedButton(
                        color: _activeColor,
                        onPressed: (){
                          appState.setPrimaryColorOverride(_activeColor);
                          Navigator.of(context).pop();
                        },
                        child: Text(S.of(context).done)
                      )
                    ],
                  )
              )
            ],
          )
        ),
      ),
    );
  }

  /* UTILS */
  ColorSwatch _findMainColor(Color shadeColor, List<ColorSwatch> colorSet) {
    for (final mainColor in colorSet)
      if (_isShadeOfMain(mainColor, shadeColor)) return mainColor;

    return null;
  }

  bool _isShadeOfMain(ColorSwatch mainColor, Color shadeColor) {
    List<Color> shades = _getMaterialColorShades(mainColor);

    for (var shade in shades) if (shade == shadeColor) return true;

    return false;
  }

  List<Color> _getMaterialColorShades(ColorSwatch color) {
    List<Color> colors = [];
    if (color[50] != null) colors.add(color[50]);
    if (color[100] != null) colors.add(color[100]);
    if (color[200] != null) colors.add(color[200]);
    if (color[300] != null) colors.add(color[300]);
    if (color[400] != null) colors.add(color[400]);
    if (color[500] != null) colors.add(color[500]);
    if (color[600] != null) colors.add(color[600]);
    if (color[700] != null) colors.add(color[700]);
    if (color[800] != null) colors.add(color[800]);
    if (color[900] != null) colors.add(color[900]);

    return colors;
  }

}