import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ad_format_helpers/src/widgets/ad_formats_parent_wrapper/ad_formats_parent.dart';

class AdFormatsParentWrapper extends StatefulWidget {
  const AdFormatsParentWrapper({
    Key? key,
    required this.child,
    required this.scrollController,
  }) : super(key: key);

  final Widget child;
  final ScrollController scrollController;

  @override
  // ignore: library_private_types_in_public_api
  _AdFormatsParentWrapperState createState() => _AdFormatsParentWrapperState();
}

class _AdFormatsParentWrapperState extends State<AdFormatsParentWrapper> {
  final GlobalKey parentWrapperKey = GlobalKey();

  Size? wrapperSize;
  double? wrapperTopOffset;

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);

    // if the wrapper size is not set, return a container with a key
    if (wrapperSize == null) {
      return Container(
        key: parentWrapperKey,
      );
    }

    return Container(
      key: parentWrapperKey,
      child: AdFormatsParent(
        scrollController: widget.scrollController,
        context: context,
        parentWrapperKey: parentWrapperKey,
        wrapperSize: wrapperSize,
        wrapperTopOffset: wrapperTopOffset,
        child: widget.child,
      ),
    );
  }

  void postFrameCallback(_) {
    var context = parentWrapperKey.currentContext;
    if (context == null) return;

    // set the wrapper size
    var newWrapperSize = (context.findRenderObject() as RenderBox?)?.size;

    // set the wrapper top offset
    var newWrapperTopOffset =
        context.findRenderObject()?.getTransformTo(null).getTranslation().y;

    if (wrapperSize == newWrapperSize &&
        wrapperTopOffset == newWrapperTopOffset) {
      return;
    }

    setState(() {
      wrapperSize = newWrapperSize;
      wrapperTopOffset = newWrapperTopOffset;
    });
  }
}
