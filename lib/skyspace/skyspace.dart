import 'package:flutter/material.dart';
import 'package:kamino/skyspace/pages/SkyspaceHomePage.dart';
import 'package:kamino/skyspace/tv_remote.dart';
import 'package:kamino/skyspace/widgets/FocusableButton.dart';
import 'package:kamino/ui/loading.dart';

class KaminoSkyspace extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => KaminoSkyspaceState();

}

class KaminoSkyspaceState extends State<KaminoSkyspace> with SingleTickerProviderStateMixin {

  Animation<double> animation;
  AnimationController controller;

  int _currentPage;
  double _sidebarOffset;

  @override
  void initState() {
    _currentPage = 0;
    _sidebarOffset = 68;

    controller = AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this
    );

    super.initState();
  }

  @override
  void dispose(){
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkyspaceRemoteWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFF141517),

        body: Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Material(
              color: const Color(0xFF1C2024),
              elevation: 4,

              child: Builder(builder: (BuildContext context){
                return Container(
                  width: 60,
                  child: Stack(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(
                          top: _sidebarOffset
                        ),
                        height: 48,
                        width: 3,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadiusDirectional.only(
                            topEnd: Radius.circular(10),
                            bottomEnd: Radius.circular(10),
                          )
                        ),
                      ),

                      Column(
                        mainAxisSize: MainAxisSize.max,
                        children: <Widget>[

                          Container(
                              margin: EdgeInsets.all(10),
                              child: Image.asset(
                                "assets/images/logo.png",
                                width: 48,
                              )
                          ),

                          Container(
                            margin: EdgeInsets.symmetric(vertical: 16),
                            child: FocusableButton(
                                builder: (BuildContext context, bool hasFocus){
                                  return Icon(
                                    Icons.home,
                                    size: 28,
                                    color: hasFocus ? Theme.of(context).primaryColor : Colors.white,
                                  );
                                },
                                onPress: (){
                                  setState(() {
                                    setPage(0);
                                  });
                                }
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 16),
                            child: FocusableButton(
                                builder: (BuildContext context, bool hasFocus){
                                  return Icon(
                                    Icons.local_movies,
                                    size: 28,
                                    color: hasFocus ? Theme.of(context).primaryColor : Colors.white,
                                  );
                                },
                                onPress: (){
                                  setState(() {
                                    setPage(1);
                                  });
                                }
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 16),
                            child: FocusableButton(
                                builder: (BuildContext context, bool hasFocus){
                                  return Icon(
                                    Icons.live_tv,
                                    size: 28,
                                    color: hasFocus ? Theme.of(context).primaryColor : Colors.white,
                                  );
                                },
                                onPress: (){
                                  setState(() {
                                    setPage(2);
                                  });
                                }
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 16),
                            child: FocusableButton(
                                builder: (BuildContext context, bool hasFocus){
                                  return Icon(
                                    Icons.favorite,
                                    size: 28,
                                    color: hasFocus ? Theme.of(context).primaryColor : Colors.white,
                                  );
                                },
                                onPress: (){
                                  setState(() {
                                    setPage(3);
                                  });
                                }
                            ),
                          ),

                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(16).copyWith(bottom: 24),
                              alignment: Alignment.bottomCenter,
                              child: FocusableButton(
                                  builder: (BuildContext context, bool hasFocus){
                                    return Icon(
                                      Icons.settings,
                                      size: 28,
                                      color: hasFocus ? Theme.of(context).primaryColor : Colors.white,
                                    );
                                  },
                                  onPress: (){
                                    setState(() {
                                      setPage(4);
                                    });
                                  }
                              ),
                            ),
                          ),

                        ],
                      )
                    ],
                  ));
              })
            ),

            Expanded(
              child: Container(
                child: renderCurrentPage(),
              ),
            )
          ]
        )
      )
    );
  }

  void setPage(int page){
    setState(() {
      _currentPage = page;
    });

    double newOffset = 68 + (_currentPage.toDouble() * 60);
    if(_currentPage == 4){
      newOffset = MediaQuery.of(context).size.height - 64;
    }

    // Curves.animation = yes
    animation = Tween<double>(begin: _sidebarOffset, end: newOffset).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut
    ))
      ..addListener((){
        setState(() {
          _sidebarOffset = animation.value;
        });
      });

    controller.reset();
    controller.forward();
  }

  Widget renderCurrentPage(){
    switch(_currentPage) {
      case 0:
        return SkyspaceHomePage();
        break;

      default:
        return Container(child: Center(
          child: ApolloLoadingSpinner(),
        ));
    }
  }

}