import 'package:flutter/material.dart';
import 'package:kamino/ui/loading.dart';

class SkyspaceCarousel extends StatefulWidget {

  final List<Widget> items;
  final bool enlargeFirstItem;
  final int length;
  final double height;
  final double spacing;
  final BorderRadius itemRadius;

  SkyspaceCarousel({
    @required this.height,
    @required this.items,
    @required this.length,
    this.enlargeFirstItem = false,
    this.spacing = 10,
    this.itemRadius = const BorderRadius.all(Radius.circular(5))
  });

  @override
  State<StatefulWidget> createState() => SkyspaceCarouselState();

}

class SkyspaceCarouselState extends State<SkyspaceCarousel> {

  static const int GROWTH_SCALE_FACTOR = 20;

  @override
  void initState() {
    if(widget.enlargeFirstItem && widget.items.length % 2 == 0){
      throw new Exception("There's no middle item.");
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints){
      double layoutWidth = constraints.widthConstraints().maxWidth;
      double biggerCard = 0;

      if(widget.enlargeFirstItem) {
        biggerCard = (layoutWidth / widget.length)
            .floorToDouble() + GROWTH_SCALE_FACTOR;

        layoutWidth -= biggerCard;
      }

      return Container(child: Row(
          children: List.generate(widget.length, (int index){
            bool shouldEnlarge = index == 0 && widget.enlargeFirstItem;

            double width = (layoutWidth / (widget.length - 1)).floorToDouble();

            return Container(
              decoration: BoxDecoration(
                color: const Color(0x24FFFFFF),
                borderRadius: widget.itemRadius
              ),
              height: shouldEnlarge ? widget.height + GROWTH_SCALE_FACTOR : widget.height,
              width: (shouldEnlarge ? biggerCard : width) - (widget.spacing * 2),
              margin: EdgeInsets.symmetric(horizontal: widget.spacing),
              child: Center(
                child: ApolloLoadingSpinner(),
              )
            );
          })
      ));
    });
  }

}