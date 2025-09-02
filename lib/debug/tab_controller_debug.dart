// Test widget to debug TabController index behavior
// This is for debugging purposes only - not part of the main application

import 'package:flutter/material.dart';

class TabControllerDebugWidget extends StatefulWidget {
  const TabControllerDebugWidget({super.key});

  @override
  State<TabControllerDebugWidget> createState() =>
      _TabControllerDebugWidgetState();
}

class _TabControllerDebugWidgetState extends State<TabControllerDebugWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tab Debug'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tab 0'),
            Tab(text: 'Tab 1'),
            Tab(text: 'Tab 2'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(child: Text('Tab 0 Content\nIndex: ${_tabController.index}')),
          Center(child: Text('Tab 1 Content\nIndex: ${_tabController.index}')),
          Center(child: Text('Tab 2 Content\nIndex: ${_tabController.index}')),
        ],
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current Index: ${_tabController.index}'),
                Text('Length: ${_tabController.length}'),
                Text(
                  'Is Last Tab: ${_tabController.index == (_tabController.length - 1)}',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    print('Current tab index: ${_tabController.index}');
                    print('Tab length: ${_tabController.length}');
                    print(
                      'Is last tab: ${_tabController.index == (_tabController.length - 1)}',
                    );
                  },
                  child: Text(
                    (_tabController.index == (_tabController.length - 1))
                        ? 'Submit Application'
                        : 'Next',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
