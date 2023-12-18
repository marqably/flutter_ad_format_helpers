import 'package:flutter/material.dart';

import 'package:flutter_ad_format_helpers/flutter_ad_format_helpers.dart';
import 'package:flutter_ad_format_helpers_example/widgets/demo_banner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: const AdFormatHelpersDemo(),
      ),
    );
  }
}

ScrollController _scrollController = ScrollController(
  initialScrollOffset: 0.0,
  keepScrollOffset: true,
);

class AdFormatHelpersDemo extends StatelessWidget {
  const AdFormatHelpersDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return AdFormatsParentWrapper(
      key: const Key('parent_wrapper'),
      scrollController: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            const SizedBox(
              height: 500,
            ),

            // second ad
            Container(
              width: double.infinity,
              color: Colors.grey,
              child: UnderstitialWrapper(
                key: const Key('ad_0'),
                adSize: const AdSize(width: 300, height: 1000),
                child: (updateBannerSize) => DemoBanner(
                  loadBanner: updateBannerSize,
                  width: 300,
                  height: 1000,
                  color: Colors.yellow,
                ),
              ),
            ),

            const SizedBox(
              height: 500,
            ),

            // first ad
            Container(
              width: double.infinity,
              color: Colors.grey,
              child: UnderstitialWrapper(
                key: const Key('ad_1'),
                // adSize: const AdSize(width: 300, height: 250),
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: (updateBannerSize) => DemoBanner(
                  loadBanner: updateBannerSize,
                  width: 300,
                  height: 250,
                  color: Colors.red,
                ),
              ),
            ),

            const SizedBox(
              height: 500,
            ),

            // second ad
            Container(
              height: 1000,
              width: double.infinity,
              color: Colors.grey,
              child: UnderstitialWrapper(
                key: const Key('ad_2'),
                // adSize: const AdSize(width: 300, height: 1000),
                child: (updateBannerSize) => DemoBanner(
                  loadBanner: updateBannerSize,
                  width: 300,
                  height: 1000,
                  color: Colors.yellow,
                ),
              ),
            ),

            const SizedBox(
              height: 500,
            ),

            // third ad
            Container(
              height: 1000,
              width: double.infinity,
              color: Colors.grey,
              child: UnderstitialWrapper(
                key: const Key('ad_3'),
                // adSize: const AdSize(width: 300, height: 1000),
                child: (updateBannerSize) => DemoBanner(
                  loadBanner: updateBannerSize,
                  width: 300,
                  height: 1000,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
