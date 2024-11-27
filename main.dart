import 'package:flutter/material.dart';

/// Entrypoint of the application.
void main() {
  runApp(const MyApp());
}

/// [Widget] building the [MaterialApp].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Dock(
            items: const [
              Icons.person,
              Icons.message,
              Icons.call,
              Icons.camera,
              Icons.photo,
            ],
            builder: (icon, scale) {
              return AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 48),
                  height: 48,
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors
                        .primaries[icon.hashCode % Colors.primaries.length],
                  ),
                  child: Center(child: Icon(icon, color: Colors.white)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dock of the reorderable [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    required this.items,
    required this.builder,
  });

  /// Initial [T] items to put in this [Dock].
  final List<T> items;

  /// Builder building the provided [T] item.
  final Widget Function(T, double scale) builder;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// The state for the [Dock] used to manipulate the [_items].
class _DockState<T extends Object> extends State<Dock<T>> {
  late List<T> _items;
  Offset? _draggedPosition;

  int? _draggedIndex;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black12,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _items.asMap().entries.map((entry) {
          final item = entry.value;
          final index = entry.key;
          final scale = _calculateScale(index);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: _calculateMargin(index),
            child: _buildDraggableItem(index, item, scale),
          );
        }).toList(),
      ),
    );
  }

  /// Builds a draggable item with the given index and scale.
  ///
  /// The [DragTarget] allows dropping the item into a new position, while the
  /// [Draggable] widget handles the dragging and animations.
  Widget _buildDraggableItem(int index, T item, double scale) {
    return DragTarget<T>(
      onAccept: (draggedItem) {
        setState(() {
          final oldIndex = _items.indexOf(draggedItem);
          _items.insert(index, draggedItem);
          _items.removeAt(oldIndex);
        });
      },
      onWillAcceptWithDetails: (draggedItem) {
        setState(() {
          _hoveredIndex = index;
        });
        return true;
      },
      onLeave: (_) => setState(() => _hoveredIndex = null),
      builder: (context, candidateData, rejectedData) {
        return MouseRegion(
          onExit: (_) {
            setState(() {
              _hoveredIndex = null;
            });
          },
          onEnter: (_) {
            setState(() {
              _hoveredIndex = index;
            });
          },
          child: Draggable<T>(
            data: item,
            onDragUpdate: (details) {
              setState(() {
                _draggedPosition = details.localPosition;
              });
            },
            onDragStarted: () {
              setState(() {
                _draggedIndex = index;
              });
            },
            onDragCompleted: () => setState(() => _draggedIndex = null),
            onDraggableCanceled: (_, __) =>
                setState(() => _draggedIndex = null),
            feedback: Material(
              color: Colors.transparent,
              child: widget.builder(item, 1.1),
            ),
            childWhenDragging: const SizedBox.shrink(),
            child: widget.builder(item, scale),
          ),
        );
      },
    );
  }

  /// Calculates the scale factor for the item based on its position relative
  /// to the hovered and dragged items.
  double _calculateScale(int index) {
    if (_hoveredIndex == null) return 1.0;
    if (_draggedIndex == index) return 1.0;

    final distance = (index - _hoveredIndex!).abs();

    if (distance == 0) return 1.2;
    if (distance == 1) return 1.07;
    if (distance == 2) return 1.07;

    return 1.0;
  }

  /// Calculates the margin for each item based on its position relative
  /// to the hovered item.
  EdgeInsets _calculateMargin(int index) {
    if (index == _hoveredIndex) {
      return const EdgeInsets.symmetric(horizontal: 30);
    }
    if ((index - _hoveredIndex!).abs() == 1) {
      return const EdgeInsets.symmetric(horizontal: 20);
    }
    if (_hoveredIndex == null || _draggedIndex == null) {
      return const EdgeInsets.symmetric(horizontal: 8);
    }

    return const EdgeInsets.symmetric(horizontal: 8);
  }
}
