import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/interface/settings/page.dart';
import 'package:kamino/main.dart';
import 'package:kamino/ui/elements.dart';
import 'package:kamino/ui/loading.dart';
import 'package:transparent_image/transparent_image.dart';

class CreditsSettingsPage extends SettingsPage {

  CreditsSettingsPage(BuildContext context) : super(
      title: S.of(context).credits,
      pageState: CreditsSettingsPageState()
  );
  
}

class CreditsSettingsPageState extends SettingsPageState {

  Map<String, dynamic> _contributors;

  Future<Null> _fetchContributors() async {
    String content = await rootBundle.loadString("assets/contributors.json");
    Map<String, dynamic> contributors = jsonDecode(content);

    setState(() {
      _contributors = contributors;
    });
  }

  @override
  void initState() {
    _fetchContributors();
    super.initState();
  }

  @override
  Widget buildPage(BuildContext context) {
    if(_contributors == null){
      return Center(
        child: ApolloLoadingSpinner(),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      itemCount: _contributors.length + 1,
      itemBuilder: (BuildContext context, int index){
        if(index == 0){
          return Card(
            color: Theme.of(context).cardColor,
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15).copyWith(bottom: 30),
            child: Container(
              padding: EdgeInsets.all(15),
              child: Column(
                children: <Widget>[
                  Image.asset("assets/images/logo.png", height: 48),
                  Container(margin: EdgeInsets.symmetric(vertical: 5)),
                  TitleText(S.of(context).thank_you, fontSize: 22),
                  Container(margin: EdgeInsets.symmetric(vertical: 5)),
                  Text(
                    S.of(context).thank_you_notice,
                    style: TextStyle(
                      color: Colors.grey[400]
                    )
                  )
                ],
              ),
            ),
          );
        }
        index--;

        String role = _contributors.keys.toList()[index];
        List roleMembers = _contributors[role];
        roleMembers
            // Sort alphabetically
            ..sort((a, b) => a['name'].toUpperCase().compareTo(b['name'].toUpperCase()))
            // Sort by color
            ..sort((b, a) => a['color'].compareTo(b['color']));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SubtitleText("$role" + (roleMembers.length != 1 ? " (${roleMembers.length})" : "")),
            ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 10).copyWith(bottom: 20),
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: roleMembers.length,
              itemBuilder: (BuildContext context, int index){
                String name = roleMembers[index]['name'];

                Widget image = FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: roleMembers[index]['image'].replaceAll('size=2048', 'size=64'),
                  width: 48,
                  height: 48,
                );
                Color color = Color(int.parse(roleMembers[index]['color'].substring(1, 7), radix: 16) + 0xFF000000);
                if(name == "NBTX"){
                  image = Image.asset("assets/images/logo.png", height: 48);
                  color = Theme.of(context).primaryColor;
                }
                if(name == "FailBoat"){
                  color = Theme.of(context).backgroundColor == const Color(0xFF000000)
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF000000);
                }

                Function _handleTap(){
                  switch(name){
                    case "FailBoat":
                      return (){
                        (() async {
                          showDialog(context: context, builder: (BuildContext context){
                            return WillPopScope(
                              onWillPop: () async => false,
                              child: AlertDialog(
                                title: TitleText("DARKNESS"),
                              ),
                            );
                          }, barrierDismissible: false);
                          await Future.delayed(Duration(seconds: 3));
                          Navigator.of(context).pop();

                          KaminoAppState application = context.ancestorStateOfType(const TypeMatcher<KaminoAppState>());
                          application.setActiveTheme("xyz.apollotv.black");
                        })();
                      };

                    default:
                      return null;
                  }
                }

                return Container(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    onTap: _handleTap(),
                    leading: ClipRRect(
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(100),
                      child: image,
                    ),
                    title: TitleText(name, textColor: color),
                  ),
                );
              }
            )
          ],
        );
      },
    );
  }

}