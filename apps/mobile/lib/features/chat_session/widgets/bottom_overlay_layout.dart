import 'package:flutter/material.dart';

class BottomOverlayLayout extends StatefulWidget {
  final Widget Function(double overlayHeight) contentBuilder;
  final Widget? overlay;
  final Widget? topOverlay;
  final Widget Function(double overlayHeight)? floatingButtonBuilder;
  final ScrollController? scrollController;

  const BottomOverlayLayout({
    super.key,
    required this.contentBuilder,
    this.overlay,
    this.topOverlay,
    this.floatingButtonBuilder,
    this.scrollController,
  });

  @override
  State<BottomOverlayLayout> createState() => _BottomOverlayLayoutState();
}

class _BottomOverlayLayoutState extends State<BottomOverlayLayout> {
  final GlobalKey _overlayKey = GlobalKey();
  double _overlayHeight = 0;
  double _prevKeyboardInset = 0;

  void _syncOverlayHeight() {
    if (!mounted) return;
    final box = _overlayKey.currentContext?.findRenderObject() as RenderBox?;
    final nextHeight = box?.size.height ?? 0;
    if ((_overlayHeight - nextHeight).abs() <= 0.5) return;
    setState(() => _overlayHeight = nextHeight);
  }

  @override
  void didUpdateWidget(covariant BottomOverlayLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset overlay height when overlay disappears
    if (widget.overlay == null && oldWidget.overlay != null) {
      _overlayHeight = 0;
    }
    // Schedule height sync when overlay appears or changes
    if (widget.overlay != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncOverlayHeight());
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    // Adjust scroll position when keyboard height changes.
    // Moved here from useKeyboardScrollAdjustment to avoid creating a
    // MediaQuery dependency on _ChatScreenBody (which would rebuild the
    // entire Scaffold + AppBar on every keyboard animation frame).
    final delta = keyboardInset - _prevKeyboardInset;
    _prevKeyboardInset = keyboardInset;
    if (delta != 0 && widget.scrollController?.hasClients == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = widget.scrollController;
        if (c == null || !c.hasClients) return;
        final pos = c.position;
        final target = (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
        c.jumpTo(target);
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final visibleHeight = (constraints.maxHeight - keyboardInset).clamp(
          0.0,
          constraints.maxHeight,
        );
        final bottomObstruction = _overlayHeight + keyboardInset;

        // Clamp so the padding never exceeds the Stack height
        // (e.g. when keyboard + overlay > available height).
        final clampedObstruction = bottomObstruction.clamp(
          0.0,
          constraints.maxHeight,
        );

        return Stack(
          children: [
            // Clip chat content above the overlay so messages don't
            // scroll behind it.
            Padding(
              padding: EdgeInsets.only(bottom: clampedObstruction),
              child: widget.contentBuilder(bottomObstruction),
            ),
            if (widget.topOverlay != null) widget.topOverlay!,
            if (widget.floatingButtonBuilder != null)
              widget.floatingButtonBuilder!(bottomObstruction),
            if (widget.overlay != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: keyboardInset),
                  child: SizedBox(
                    width: double.infinity,
                    height: visibleHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        // Defer unfocus to the next frame so EditableText's
                        // setState + rebuild doesn't compete with the scroll
                        // gesture's first frame for the frame budget.
                        onVerticalDragStart: (_) {
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) {
                              if (context.mounted) {
                                FocusScope.of(context).unfocus();
                              }
                            },
                          );
                        },
                        child:
                            NotificationListener<SizeChangedLayoutNotification>(
                              onNotification: (_) {
                                WidgetsBinding.instance.addPostFrameCallback(
                                  (_) => _syncOverlayHeight(),
                                );
                                return false;
                              },
                              child: SizeChangedLayoutNotifier(
                                child: ClipRect(
                                  child: ConstrainedBox(
                                    key: _overlayKey,
                                    constraints: BoxConstraints(
                                      maxHeight: visibleHeight,
                                    ),
                                    child: widget.overlay,
                                  ),
                                ),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
