import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_ad_format_helpers/src/widgets/ad_formats_parent_wrapper/ad_formats_parent.dart';

class AdFormatAdSize {
  final double width;
  final double height;

  const AdFormatAdSize({required this.width, required this.height});
}

/// A banner ad that scrolls off with the content in a parallax effect
///
/// It is a bit more complex than the other ads, because it needs to be placed under the article and scroll with the content
class UnderstitialWrapper extends StatefulWidget {
  const UnderstitialWrapper({
    required Key key,
    required this.child,
    this.padding,
    this.adSize,
  }) : super(key: key);

  final Widget Function(VoidCallback updateBannerSize) child;
  final EdgeInsets? padding;
  final AdFormatAdSize? adSize;

  @override
  UnderstitialWrapperState createState() => UnderstitialWrapperState();
}

class UnderstitialWrapperState extends State<UnderstitialWrapper> {
  AdFormatsParent? adFormatsParent;

  GlobalKey elementKey = GlobalKey();
  GlobalKey bannerElementKey = GlobalKey();
  double undersitialOffset = 0;

  Widget? renderChild;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // register advanced adWrapper
      AdFormatsParent.of(context).registerAd(
        AdFormatItem(
          idname: getKeyString(),
          wrapperKey: elementKey,
          bannerKey: bannerElementKey,
          inView: false,
          type: AdFormatItemType.undersitital,
          bannerScrollOffset: undersitialOffset,
          yPosition: 0,
          offsetSetter: (double offset) => setState(() {
            undersitialOffset = offset + (widget.padding?.top ?? 0);
          }),
          visibilitySetter: (inView, isFirstLoad) {
            if (isFirstLoad) {
              setState(() {
                renderChild = widget.child(updateBannerSize);
              });
            }
          },
        ),
      );
    });


    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // calculate the padding sum
    final double paddingSum =
        (widget.padding?.top ?? 0) + (widget.padding?.bottom ?? 0);

    // calculate the height of the banner
    final double wrapperHeight =
        AdFormatsParent.of(context).getWrapperHeightForReal();

    // calculate the available wrapper height without the given padding to make it fit
    final double fillableWrapperHeight = (wrapperHeight - paddingSum);

    // try to get the ad from the list of ads
    final AdFormatItem? adItem =
        AdFormatsParent.of(context).getAd(getKeyString());

    // if the ad is not in view -> return a placeholder
    if (renderChild == null || adItem == null) {
      return Container(
        alignment: Alignment.center,
        height: wrapperHeight,
        constraints: BoxConstraints(
          minHeight: wrapperHeight,
          maxHeight: wrapperHeight,
        ),
        key: elementKey,
        child: Container(
          key: bannerElementKey,
        ),
      );
    }

    // if no ad in the list yet -> return a a placeholder
    if (adItem.inView == false) {
      return Container(
        alignment: Alignment.center,
        height: wrapperHeight,
        key: elementKey,
        constraints: BoxConstraints(
          minHeight: wrapperHeight,
          maxHeight: wrapperHeight,
        ),
        child: Container(
          key: bannerElementKey,
          child: renderChild,
        ),
      );
    }

    // set the dimensions
    final double bannerHeight =
        widget.adSize?.height.toDouble() ?? adItem.bannerSize?.height ?? 0;
    final double bannerWidth =
        widget.adSize?.width.toDouble() ?? adItem.bannerSize?.width ?? 0;

    // if the ad is bigger than our screen, calculate the scale of the banner, in case we need to make it fit into the screen, because it would not fully fit to be fully visible
    final double bannerScale = (fillableWrapperHeight < bannerHeight)
        ? fillableWrapperHeight / bannerHeight
        : 1;

    // calculate the center position (in case the banner is smaller than the screen) - use max to make sure we never have a negative number for bigger ads
    final double centerPositionOffset =
        max((fillableWrapperHeight - bannerHeight) / 2, 0);

    return Container(
      constraints: BoxConstraints(
        minHeight: wrapperHeight,
        maxHeight: wrapperHeight,
      ),
      key: elementKey,
      height: wrapperHeight,
      width: bannerWidth,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: wrapperHeight,
        minHeight: wrapperHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: (undersitialOffset + centerPositionOffset),
              child: SizedBox(
                height: bannerHeight,
                width: bannerWidth,
                child: Transform.scale(
                  alignment: Alignment.topCenter,
                  scale: bannerScale,
                  child: Container(
                    key: bannerElementKey,
                    child: renderChild,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Updates the banner size
  void updateBannerSize() {
    AdFormatsParent.of(context).updateAdPositions();
  }

  /// Allows us to either return the element key or even generate a new one, that
  /// is still unique to this element, by taking the parent key and adding a postfix to it
  String getKeyString([String? postfix]) {
    final parentKeyValue = (widget.key as ValueKey<String>).value;
    return 'undersitial_$parentKeyValue${postfix ?? ''}';
  }

  @override
  void didChangeDependencies() {
    adFormatsParent = AdFormatsParent.of(context);
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    // remove this ad from the list of ads
    adFormatsParent?.unregisterAd(getKeyString());
    super.dispose();
  }
}
