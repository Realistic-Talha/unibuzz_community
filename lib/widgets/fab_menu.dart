import 'package:flutter/material.dart';
import 'package:unibuzz_community/screens/events/create_event_screen.dart';
import 'package:unibuzz_community/screens/lost_found/report_item_screen.dart';

class FabMenu extends StatefulWidget {
  const FabMenu({super.key});

  @override
  State<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<FabMenu> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _showLostFoundDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lost & Found'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Report Lost Item'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportItemScreen(isLost: true),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.find_in_page),
              title: const Text('Report Found Item'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ReportItemScreen(isLost: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFabMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required int index,
  }) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(index * 0.1, 0.6 + index * 0.1, curve: Curves.easeOut),
      ),
    );

    return ScaleTransition(
      scale: animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _toggleMenu(); // Close menu after selection
                  onPressed();
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label),
                      const SizedBox(width: 8),
                      Icon(icon, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isOpen) ...[
            _buildFabMenuItem(
              icon: Icons.post_add,
              label: 'Create Post',
              onPressed: () => Navigator.pushNamed(context, '/create-post'),
              index: 0,
            ),
            _buildFabMenuItem(
              icon: Icons.event,
              label: 'Create Event',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CreateEventScreen()),
              ),
              index: 1,
            ),
            _buildFabMenuItem(
              icon: Icons.search,
              label: 'Lost & Found',  // Updated label
              onPressed: () => _showLostFoundDialog(context),  // Updated onPressed
              index: 2,
            ),
          ],
          Material(
            type: MaterialType.transparency,
            child: FloatingActionButton(
              heroTag: null, // Add this line to disable Hero animation
              onPressed: _toggleMenu,
              child: AnimatedIcon(
                icon: AnimatedIcons.menu_close,
                progress: _controller,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
