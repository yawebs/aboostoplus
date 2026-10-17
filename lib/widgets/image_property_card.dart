import 'package:eafind/theme/app_palette.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/widgets/agent_account_profile.dart';
import 'package:eafind/widgets/reactions_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../const/constant.dart';
import '../models/property_model.dart';
import '../models/user_model.dart';
import '../providers/usermodel_provider.dart';
import '../screens/authscreen/login_screen.dart';
import 'video_display_widget.dart';

class ImagePropertyCard extends StatefulWidget {
  final List<PropertyModel> properties;
  final int index;
  const ImagePropertyCard(
      {Key? key, required this.properties, required this.index})
      : super(key: key);

  @override
  State<ImagePropertyCard> createState() => _ImagePropertyCardState();
}

class _ImagePropertyCardState extends State<ImagePropertyCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.palette.raised,
      elevation: context.palette.raisedElevation,
      shadowColor: Colors.black,
      shape: context.palette.raisedShape,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AgentAccountProfile(
                  property: widget.properties[widget.index],
                ),
                Padding(
                  padding: EdgeInsets.only(left: 15),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          UserModel? activeUser =
                              Provider.of<UsermodelProvider>(context,
                                      listen: false)
                                  .getUserModel();
                          if (activeUser == null) {
                            goTo(context, LoginScreen(fromNav: true), false);
                          } else {
                            showReportModal(
                                widget.properties[widget.index], context);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Icon(
                            Icons.more_vert,
                            size: 18,
                            color: grey,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            widget.properties[widget.index].isHouse != 0
                ? Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 2),
                    child: AutoSizeText(
                      widget.properties[widget.index].description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                : Container(
                    height: 200,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                        color: postColors[
                            widget.properties[widget.index].colorCode],
                        border: Border.all(color: context.palette.paper, width: 1),
                        borderRadius: appRadius(10.0)),
                    child: Center(
                      child: Text(
                        widget.properties[widget.index].description,
                        style: TextStyle(
                            color: getTextColor(
                              widget.properties[widget.index].colorCode,
                            ),
                            fontSize: 16),
                      ),
                    ),
                  ),
            const SizedBox(height: 5),
            Text(
              '₦${NumberFormat().format(widget.properties[widget.index].amount)}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 5),
            widget.properties[widget.index].isVideo == 1
                ? VideoDisplayWidget(property: widget.properties[widget.index])
                : GridView.custom(
                    shrinkWrap: true,
                    primary: false,
                    gridDelegate: SliverQuiltedGridDelegate(
                      crossAxisCount: 4,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      repeatPattern: QuiltedGridRepeatPattern.inverted,
                      pattern: const [
                        QuiltedGridTile(2, 2),
                        QuiltedGridTile(1, 1),
                        QuiltedGridTile(1, 1),
                        QuiltedGridTile(1, 2),
                        QuiltedGridTile(1, 2),
                      ],
                    ),
                    childrenDelegate: SliverChildBuilderDelegate(
                      (context, index2) => Container(
                        child: GestureDetector(
                          onTap: () => viewPhotoDialog(
                              widget.properties[widget.index].images,
                              widget.properties[widget.index],
                              context),
                          child: (widget.properties[widget.index].images
                                          .length >
                                      6 &&
                                  index2 == 5)
                              ? Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CachedNetworkImage(
                                      width: 200,
                                      memCacheWidth: (250 *
                                              MediaQuery.of(context)
                                                  .devicePixelRatio)
                                          .round(),
                                      imageUrl: widget.properties[widget.index]
                                          .images[index2],
                                      fit: BoxFit.cover,
                                      errorWidget:
                                          (context, error, stackTrace) {
                                        return Container(
                                          color: grey,
                                          child: Icon(
                                            Icons.replay,
                                            color: context.palette.accent,
                                          ),
                                        );
                                      },
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: black.withOpacity(0.4),
                                      ),
                                    ),
                                    Center(
                                      child: Text(
                                        '+${widget.properties[widget.index].images.length - index2 - 1}',
                                        style: TextStyle(
                                            color: white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                )
                              : CachedNetworkImage(
                                  width: 200,
                                  memCacheWidth: (250 *
                                          MediaQuery.of(context)
                                              .devicePixelRatio)
                                      .round(),
                                  imageUrl: widget
                                      .properties[widget.index].images[index2],
                                  fit: BoxFit.cover,
                                  errorWidget: (context, error, stackTrace) {
                                    return Container(
                                      color: grey,
                                      child: Icon(
                                        Icons.replay,
                                        color: context.palette.accent,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                      childCount: widget
                                  .properties[widget.index].images.length >
                              6
                          ? 6
                          : widget.properties[widget.index].images.length == 5
                              ? widget.properties[widget.index].images.length -
                                  1
                              : widget.properties[widget.index].images.length,
                    ),
                  ),
            h10(),
            ReactionsWidget(property: widget.properties[widget.index])
          ],
        ),
      ),
    );
  }
}
