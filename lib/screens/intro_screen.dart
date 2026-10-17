import 'package:eafind/const/constant.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/home_bottom_navbar.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:story/story_image.dart';
import 'package:story/story_page_view.dart';

class AppIntro extends StatefulWidget {
  const AppIntro({Key? key}) : super(key: key);

  @override
  State<AppIntro> createState() => _AppIntroState();
}

class _AppIntroState extends State<AppIntro> {
  final introKey = GlobalKey<IntroductionScreenState>();
  late ValueNotifier<IndicatorAnimationCommand> indicatorAnimationController;
  final PageController _webPageController = PageController();
  int _webPage = 0;
  Widget _buildImage(String assetName, [double width = 350]) {
    return Image.asset('assets/images/$assetName', width: width);
  }

  Widget _buildFullscreenImage(String assetName) {
    return Image.asset(
      'assets/images/$assetName',
      fit: BoxFit.cover,
      height: height(context),
      width: width(context),
      alignment: Alignment.center,
      color: Color.fromARGB(204, 0, 0, 0),
      colorBlendMode: BlendMode.multiply,
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    indicatorAnimationController = ValueNotifier<IndicatorAnimationCommand>(
        IndicatorAnimationCommand.resume);
  }

  @override
  void dispose() {
    indicatorAnimationController.dispose();
    _webPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StoryPageView(
            itemBuilder: (context, pageIndex, storyIndex) {
              final story = storyItem[storyIndex];
              return Container(
                color: black,
                width: double.infinity,
                child: Column(
                  children: [
                    Stack(
                      children: [
                        StoryImage(
                          key: ValueKey(story.imageUrl),
                          imageProvider: AssetImage(
                            story.imageUrl,
                          ),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: height(context) / 1.5,
                        ),
                        Positioned(
                          bottom: 30,
                          child: Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Text(
                              story.title,
                              style: TextStyle(
                                fontSize: 26,
                                color: white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15.0),
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 20,
                          ),
                          Column(
                            children: [
                              for (var point in story.points)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 15.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 5,
                                        backgroundColor: white,
                                      ),
                                      const SizedBox(
                                        width: 20,
                                      ),
                                      Expanded(
                                        child: Text(
                                          point,
                                          style: TextStyle(color: white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },

            indicatorAnimationController: indicatorAnimationController,
            // initialStoryIndex: (pageIndex) {
            //   if (pageIndex == 0) {
            //     return 1;
            //   }
            //   return 0;
            // },
            pageLength: 1,
            storyLength: (int pageIndex) {
              return storyItem.length;
            },
            onPageLimitReached: () {
              // goTo(context, const BottomNavHome(), false);
            },
          ),
          Positioned(
            bottom: 0,
            width: width(context),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      goTo(context, const BottomNavHome(), false);
                      // navigateAndReplace(context, page: RoutePaths.signUp);
                    },
                    child: Text(
                      'skip',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: white,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width(context) * .27,
                    child: MaterialButton(
                      onPressed: () {},
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          color: white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finishIntro() => goTo(context, const BottomNavHome(), false);

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final wide = AppBreakpoints.isWide(constraints.maxWidth);
            final panel = _webContentPanel(context);
            final image = _webImagePanel();
            if (!wide) {
              return SafeArea(
                child: Column(
                  children: [
                    SizedBox(height: 260, child: image),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(28),
                        child: panel,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Row(
              children: [
                Expanded(child: image),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: panel,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _webImagePanel() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_webPage),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(storyItem[_webPage].imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(.05), Colors.black.withOpacity(.45)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _webContentPanel(BuildContext context) {
    final story = storyItem[_webPage];
    final isLast = _webPage == storyItem.length - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < storyItem.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                width: i == _webPage ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _webPage ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          story.title,
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 20),
        for (final point in story.points)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(fontSize: 15, color: AppColors.textGrey),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (!isLast)
              TextButton(
                onPressed: _finishIntro,
                child: const Text('Skip', style: TextStyle(color: AppColors.textGrey)),
              ),
            const Spacer(),
            SizedBox(
              width: 160,
              child: MiaButton(
                text: isLast ? 'Get Started' : 'Next',
                onPressed: () {
                  if (isLast) {
                    _finishIntro();
                  } else {
                    setState(() => _webPage += 1);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
