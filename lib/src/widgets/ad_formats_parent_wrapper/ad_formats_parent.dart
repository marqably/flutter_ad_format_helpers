import 'package:flutter/widgets.dart';

enum AdFormatItemType {
  undersitital,
}

/// Defines a single ad item that is tracked by the [AdFormatsParentWrapper]
class AdFormatItem {
  /// A unique string identifier, that we use to identify the ad by in our map
  final String idname;

  /// A [GlobalKey] to the widget that wraps the ad (will be used to get position of the ad on the screen)
  final GlobalKey wrapperKey;

  /// A [GlobalKey] to the widget that directly wraps the final ad element to get the real banner size (can differ from wrapperKey in size, because of the OverflowBox around it)
  final GlobalKey bannerKey;

  /// Whether the ad is currently in view or not
  final bool inView;

  /// Whether the ad has been in view yet during this session (this can be used to show a placeholder until it is in view for the first time or load the ad as soon as it enters the view)
  final bool isLoaded;

  /// What type of ad is this
  final AdFormatItemType type;

  /// The current calculated scroll offset for our effect (this value will be changed to offset i.e. understitials to always stay on the same position by this widget. It will be changed by the scrollListener of the [AdFormatsParentWrapper])
  final double bannerScrollOffset;

  /// The vertical position of this widget inside of the [scrollController]. This is used to match this against the current scrollPosition to get [bannerScrollOffset]
  final double? yPosition;

  /// A method, that will be triggered while scrolling to update the state of the real understital banner widget and then updates the offset just for the affected widget.
  final Function(double offset)? offsetSetter;

  /// A method, that will be triggered if the visibility of the adchanges
  /// [inView]tells you whether the ad is currently in view or not
  /// [isFirstLoad] tells you whether this is the first time the ad is in view or not (this let's you load the ad as soon as it is about to be in view for the first time)
  final Function(
    bool inView,
    bool isFirstLoad,
  )? visibilitySetter;

  /// The size of the banner
  final Size? bannerSize;

  AdFormatItem({
    required this.idname,
    required this.wrapperKey,
    required this.bannerKey,
    required this.inView,
    required this.type,
    required this.bannerScrollOffset,
    required this.offsetSetter,
    this.visibilitySetter,
    this.yPosition,
    this.isLoaded = false,
    this.bannerSize,
  });

  AdFormatItem copyWith({
    String? idname,
    GlobalKey? wrapperKey,
    GlobalKey? bannerKey,
    bool? inView,
    AdFormatItemType? type,
    double? yPosition,
    double? bannerScrollOffset,
    bool? isLoaded,
    Size? bannerSize,
  }) {
    return AdFormatItem(
      idname: idname ?? this.idname,
      wrapperKey: wrapperKey ?? this.wrapperKey,
      bannerKey: bannerKey ?? this.bannerKey,
      inView: inView ?? this.inView,
      type: type ?? this.type,
      yPosition: yPosition ?? this.yPosition,
      bannerScrollOffset: bannerScrollOffset ?? this.bannerScrollOffset,
      offsetSetter: offsetSetter,
      visibilitySetter: visibilitySetter,
      isLoaded: isLoaded ?? this.isLoaded,
      bannerSize: bannerSize ?? this.bannerSize,
    );
  }
}

/// A singleton list of all ad formats we currently have loaded
var adFormatsAdItems = <String, AdFormatItem>{};

/// A singleton listener to the scroll event of the scrollController
bool? adFormatsAdItemsScrollListener;

/// A singleton that keeps the current height of our screenHeight (maybe in the future we need to change this to make sure we can have multiple [AdFormatsParentWrapper]), but for now it should be fine for most cases.
double adFormatsScreenHeight = 0;

/// A singleton that keeps the current offset from top position for this screen widget
double adFormatsScreenOffsetTop = 0;

class AdFormatsParent extends InheritedWidget {
  const AdFormatsParent({
    Key? key,
    required this.context,
    required Widget child,
    required this.scrollController,
    required this.parentWrapperKey,
    this.wrapperSize,
    this.wrapperTopOffset,
  }) : super(
          key: key,
          child: child,
        );

  final ScrollController scrollController;
  final BuildContext context;
  final GlobalKey parentWrapperKey;

  /// The size of the parent wrapper
  final Size? wrapperSize;

  /// The offset of the parent wrapper
  final double? wrapperTopOffset;

  /// Defines how many times the screenHeight before the banner visibility position, we want to start to load the banner (as a factor of the screen height - i.e: 1.5 means 1.5 times the screen height)
  final double bannerLoadingScreenSizeOffsetTop = 0.5;

  /// Defines how many times the screenHeight after the banner visibility position, we want to keep working with the banner (as a factor of the screen height - i.e: 1.5 means 1.5 times the screen height)
  final double bannerLoadingScreenSizeOffsetBottom = 0.5;

  /// Registers a new ad within this screen, that needs to be tracked and worked with
  void registerAd(AdFormatItem ad) {
    adFormatsAdItems[ad.idname] = ad;

    updateAdPositions();
  }

  /// Returns the ad with the given [idname] or null if not found yet
  AdFormatItem? getAd(String idname) {
    return adFormatsAdItems[idname];
  }

  /// Removes the ad from being trackend and worked with
  void unregisterAd(String adString) {
    // remove an element
    adFormatsAdItems.remove(adString);

    // if we have an initialized listener, but no entries anymore -> dispoes the listener to clean up
    if (adFormatsAdItems.isEmpty && adFormatsAdItemsScrollListener != null) {
      adFormatsAdItemsScrollListener = false;
      disposeScrollListener();
    }
  }

  /// Updates the position and size cache values for a given ad
  AdFormatItem? updateAd(String idname) {
    var adItem = adFormatsAdItems[idname];

    // if not found -> do nothing
    if (adItem == null) {
      return null;
    }

    // otherwise set it
    return adItem.copyWith(
      yPosition: _getAdItemOffsetPosition(idname, adItem),
      bannerSize: _getAdItemBannerSize(idname, adItem),
    );
  }

  /// Go through all ads and make sure our cached positions are up to date
  void updateAdPositions() {
    adFormatsAdItems = adFormatsAdItems.map((wrapperKey, adItem) {
      final newAdItem = updateAd(wrapperKey);

      if (newAdItem != null) {
        return MapEntry(wrapperKey, newAdItem);
      }

      return MapEntry(wrapperKey, adItem);
    })
        // now go through all entries and reset their position to make sure the starting position is correct
        .map((wrapperKey, adItem) {
      final bannerScrollOffset =
          0 - (adItem.yPosition ?? 0) + getWrapperOffsetTop();

      return MapEntry(
          wrapperKey, adItem.copyWith(bannerScrollOffset: bannerScrollOffset));
    });

    // if we got more then 1 element in the list and the adFormatsAdItemsScrollListener is not initialized yet -> do that
    if (adFormatsAdItems.isNotEmpty && adFormatsAdItemsScrollListener == null) {
      initScrollListener();
      adFormatsAdItemsScrollListener = true;
    }
  }

  /// uses the wrapperKey to get the current offset of an adItem on the screen, so we can use it to calculate the position
  double? _getAdItemOffsetPosition(
    String wrapperKey,
    AdFormatItem adItem,
  ) {
    final RenderObject? parentRenderBox =
        parentWrapperKey.currentContext?.findRenderObject();
    final RenderObject? renderBox =
        adItem.wrapperKey.currentContext?.findRenderObject();

    if (renderBox is RenderBox && parentRenderBox is RenderBox) {
      final scrollOffset = scrollController.offset.toDouble();
      final positionRed = renderBox.localToGlobal(Offset.zero);

      final offsetY = positionRed.dy + scrollOffset.toDouble();

      return offsetY;
    }

    return null;
  }

  /// Calculates the height of the banner, so we can use it inside of our widgettree
  Size? _getAdItemBannerSize(
    String wrapperKey,
    AdFormatItem adItem,
  ) {
    final RenderObject? renderBox =
        adItem.bannerKey.currentContext?.findRenderObject();

    if (renderBox is RenderBox && renderBox.hasSize) {
      return renderBox.size;
    }

    return null;
  }

  /// Calculates and sets the height of the banner, so we can use it inside of our widgettree
  // void updateBannerSize(
  //   String idname,
  // ) {
  //   var adItem = adFormatsAdItems[idname];

  //   // if not found -> do nothing
  //   if (adItem == null) {
  //     return;
  //   }

  //   final RenderObject? renderBox =
  //       adItem.bannerKey.currentContext?.findRenderObject();

  //   if (renderBox is RenderBox && renderBox.hasSize) {
  //     // otherwise set it
  //     adFormatsAdItems[idname]!.copyWith(bannerSize: renderBox.size);
  //   }
  // }

  /// Check whether the ad is currently visible on the screen or not
  bool isAdInView(AdFormatItem adItem) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bannerAreaHeight = ((adItem.bannerSize?.height ?? 0) > screenHeight)
        ? (adItem.bannerSize?.height ?? 0)
        : screenHeight;

    // get the current offset
    final scrollOffset = scrollController.offset.toDouble();

    // calculate the current offset (because the banner itself needs to stay at exactly the same position while we scroll)
    final currentOffset = scrollOffset - (adItem.yPosition ?? 0);

    // If the ad is not in view yet -> no way, we can see it
    if ((currentOffset + screenHeight) <
        -(bannerLoadingScreenSizeOffsetTop * screenHeight)) {
      return false;
    }

    // if we already scrolled past the ad -> no way, we can see it
    if ((currentOffset + screenHeight) >
        (bannerAreaHeight +
            (bannerLoadingScreenSizeOffsetBottom * screenHeight))) {
      return false;
    }

    // otherwise it is in view
    return true;
  }

  /// The method called in our scrollListener to update the position of the ads
  /// With every scroll event, we loop through all of our adFormatsAdItems [AdItem]s and if they are in view, we update the position of the banner
  void _listenToAdFormatItems() {
    // get the current offset
    final scrollOffset = scrollController.offset.toDouble();

    // loop through all of the visible undersitital ads
    adFormatsAdItems = adFormatsAdItems.map((wrapperKey, adItem) {
      // update the new scrollOffset
      var newAdItem = adItem.copyWith(
        bannerScrollOffset:
            scrollOffset - (adItem.yPosition ?? 0) + getWrapperOffsetTop(),
      );

      // if the ad is not in view -> skip it
      if (!isAdInView(newAdItem)) {
        // if the ad was in view before, but is not anymore -> trigger the visibilitySetter
        if (adItem.inView) {
          // call the visibilitySetter with both values set to false, because it is not in view and if it changed from inView it must be loaded anyway
          adItem.visibilitySetter?.call(false, false);
        }

        return MapEntry(wrapperKey, adItem.copyWith(inView: false));
      }

      // if the ad is in view, but was not before -> trigger the visibilitySetter
      if (!adItem.inView) {
        // if we have not loaded the ad yet, trigger the visibilitySetter with isFirstLoad set to true
        final isFirstLoad = (!adItem.isLoaded);

        // call the visibilitySetter with both values set to true, because it is in view and if it changed from not inView it must be loaded anyway
        adItem.visibilitySetter?.call(true, isFirstLoad);

        // update the adItem to be inView and loaded
        newAdItem = newAdItem.copyWith(
          inView: true,
          isLoaded: true,
        );
      }

      // calculate the current offset (because the banner itself needs to stay at exactly the same position while we scroll)
      adItem.offsetSetter?.call(newAdItem.bannerScrollOffset);

      newAdItem = newAdItem.copyWith(
        bannerScrollOffset: scrollOffset -
            (_getAdItemOffsetPosition(wrapperKey, adItem) ?? 0) +
            getWrapperOffsetTop(),
      );

      return MapEntry(wrapperKey, newAdItem);
    });
  }

  /// Returns the height of the wrapper to the [AdFormatItem] with the given [wrapperKey]
  double getWrapperHeightForReal() {
    return wrapperSize?.height ?? MediaQuery.of(context).size.height;
  }

  /// Returns the offset of our [AdFormatsParentWrapper] to the top of the screen
  double getWrapperOffsetTop() {
    return wrapperTopOffset ?? 0;
  }

  /// A generic scroll listener, that will listen to the scroll event of a view and then perform the overview animation
  /// on all of the advanced ads that are currently visible
  void initScrollListener() {
    scrollController.addListener(_listenToAdFormatItems);
  }

  /// Removes the scroll listener from the scroll controller to make sure no further trackings are done and we don't have any memory leaks
  void disposeScrollListener() {
    scrollController.removeListener(_listenToAdFormatItems);
  }

  /// We don't want to do any updates on this widget, because we do it with the setter of the [AdItem] directly using [offsetSetter]
  @override
  bool updateShouldNotify(AdFormatsParent oldWidget) {
    return false;
  }

  /// Returns the AdFormatsParentWrapper of the closest parent
  static AdFormatsParent of(BuildContext context) {
    final AdFormatsParent? result =
        context.dependOnInheritedWidgetOfExactType<AdFormatsParent>();

    assert(
      result != null,
      'No AdFormatsParentWrapper found in context. Make sure to wrap your widget somewhere in the tree with AdFormatsParentWrapper.',
    );
    return result!;
  }
}
