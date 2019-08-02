import 'package:flutter/material.dart';
import 'package:kamino/external/ExternalService.dart';
import 'package:kamino/external/api/tmdb.dart';
import 'package:kamino/generated/i18n.dart';
import 'package:kamino/models/content/content.dart';
import 'package:kamino/models/list.dart';
import 'package:kamino/partials/carousel_card.dart';
import 'package:kamino/skyspace/widgets/SkyspaceCarousel.dart';
import 'package:kamino/ui/elements.dart';
import 'package:shimmer/shimmer.dart';

class SkyspaceHomePage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => SkyspaceHomePageState();

}

class SkyspaceHomePageState extends State<SkyspaceHomePage> {

  List<ContentModel> _topPicksList;

  @override
  void initState() {
    Service.get<TMDB>().getList(context, 105604, loadFully: false, useCache: true).then((list){
      if(mounted) setState(() => _topPicksList = list.content);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
            child: SkyspaceCarousel(
                enlargeFirstItem: true,
                height: 160,
                length: 3,
                items: _topPicksList != null ? List.generate(_topPicksList.length, (int index){
                  return Builder(builder: (BuildContext context){
                    var content = _topPicksList[index];

                    return Container(
                      child: CarouselCard(content),
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      padding: EdgeInsets.symmetric(vertical: 10),
                    );
                  });
                }) : List.generate(3, (int index){
                  return Container(
                    child: Material(
                      type: MaterialType.card,
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      borderRadius: BorderRadius.circular(8),
                      child: Shimmer.fromColors(
                        baseColor: const Color(0x8F000000),
                        highlightColor: const Color(0x4F000000),
                        child: Container(color: const Color(0x8F000000)),
                      ),
                    ),
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  );
                })
            ),
          )
        ],
      ),
    );
  }

  static Widget getUnderConstructionWidget(BuildContext context){
    return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(const IconData(0xe90F, fontFamily: 'apollotv-icons'), size: 72),
            Container(
                margin: EdgeInsets.only(top: 20),
                child: TitleText(
                    S.of(context).houston_stand_by,
                    textColor: Colors.white,
                    fontSize: 20
                )
            ),
            Container(
              margin: EdgeInsets.only(top: 10),
              child: Text(S.of(context).apollo_skyspace_is_still_under_development + "\n" + S.of(context).we_will_announce_it_on_our_social_pages_when_its),
            ),
          ],
        )
    );
  }

}