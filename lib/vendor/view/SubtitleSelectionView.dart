import 'package:flutter/material.dart';
import 'package:kamino/ui/elements.dart';

class SubtitleSelectionView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SubtitleSelectionViewState();
}

class SubtitleSelectionViewState extends State<SubtitleSelectionView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TitleText("Subtitles"),
      ),
    );
  }

}