import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:story_view/story_view.dart';

class ViewStoryScreen extends StatefulWidget {
  final List images;
  const ViewStoryScreen({Key? key, required this.images}) : super(key: key);

  @override
  State<ViewStoryScreen> createState() => _ViewStoryScreenState();
}

class _ViewStoryScreenState extends State<ViewStoryScreen> {
  final controller = StoryController();
  List<StoryItem> storyItems = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    storyItems = widget.images
        .map(
            (e) => StoryItem(StoryImage.url(e), duration: Duration(seconds: 3)))
        .toList();

    //  [
    //   StoryItem.text(title: 'Duplex Apartment', backgroundColor: primaryColor),
    //   StoryItem.pageProviderImage(
    //       const AssetImage(
    //         'assets/images/h1.jpg',
    //       ),
    //       caption: 'Front View'),
    //   StoryItem.pageProviderImage(
    //       const AssetImage(
    //         'assets/images/h2.jpg',
    //       ),
    //       caption: 'Palour'),
    //   StoryItem.pageProviderImage(
    //       const AssetImage(
    //         'assets/images/h1.jpg',
    //       ),
    //       caption: 'Kitchen'),
    // ];
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _storyView(),
        ],
      ),
    );
  }

  // A full-bleed vertical story stretched across a wide desktop browser
  // looks wrong, so it's centered in a phone-proportioned column instead
  // (the common web treatment for story viewers).
  Widget _buildWeb(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: _storyView(),
        ),
      ),
    );
  }

  Widget _storyView() {
    return StoryView(
      storyItems: storyItems,
      controller: controller,
      onComplete: () {
        Navigator.of(context).pop();
      },
      onVerticalSwipeComplete: (v) {
        if (v == Direction.down) {
          Navigator.pop(context);
        }
      },
      onStoryShow: (storyItem, index) {
        int pos = storyItems.indexOf(storyItem);

        // the reason for doing setState only after the first
        // position is becuase by the first iteration, the layout
        // hasn't been laid yet, thus raising some exception
        // (each child need to be laid exactly once)
      },
    );
  }
}
