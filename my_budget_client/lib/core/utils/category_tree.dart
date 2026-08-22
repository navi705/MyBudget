import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';

/// The parent/child shape of a list of categories, made safe to draw.
///
/// `parent_id` is a plain nullable column with nothing keeping it pointed at a
/// row the screen can see, and three ordinary things break that:
///
///  * Deleting a parent soft-deletes the parent alone. Its children keep the id
///    of a row no query returns any more.
///  * The type filter and the page-at-a-time load both hand the screen a subset
///    of the table, so a child can be in hand while its parent is not.
///  * Two devices can each reparent legally - "put Rent under Home" here, "put
///    Home under Rent" there - and the merge produces a loop neither device
///    made. Nothing in the sync protocol can reject it: it arrives as two
///    single-row updates that are each perfectly valid.
///
/// The screens used to call a category top-level when `parentId == null`, so in
/// every one of those cases the row hung under a parent nobody drew and simply
/// vanished - off the list, off the grid, out of reach of the context menu that
/// could have repaired it - while its money went on counting in every total.
/// The loop was worse than invisible: the list nests a child inside its parent,
/// so a loop that did stay on screen would have nested for as long as the user
/// kept expanding.
///
/// Here a category is a root when nothing visible parents it, and a loop is cut
/// at its lowest id - a rule that needs no coordination, so two devices holding
/// the same loop still draw the same tree.
class CategoryTree {
  const CategoryTree._(this.roots, this._childrenById, this._byId);

  /// Builds the tree of [categories], which is whatever the screen can
  /// currently see: already filtered, already sorted, possibly a partial page.
  ///
  /// Order is preserved. Every entry comes out exactly once, as a root or as
  /// the child of exactly one visible parent.
  factory CategoryTree.of(List<CategoryWithTotal> categories) {
    final byId = <String, CategoryWithTotal>{};
    for (final entry in categories) {
      final id = entry.category.id;
      if (id != null) byId[id] = entry;
    }

    /// The id each loop is cut at. Its own parent link is ignored, which is
    /// what turns the loop into a tree hanging off it.
    final cutPoints = <String>{};
    // Ids already known to reach a root, so a long chain is not re-walked from
    // every one of its members.
    final settled = <String>{};

    for (final entry in categories) {
      final start = entry.category.id;
      if (start == null || settled.contains(start)) continue;

      final path = <String>[];
      final onPath = <String>{};
      String? cursor = start;
      while (cursor != null && !settled.contains(cursor)) {
        if (!onPath.add(cursor)) {
          // Walked into a loop. Its members are the tail of the path from the
          // repeat onwards; the lowest id of those is where it gets cut.
          final loop = path.sublist(path.indexOf(cursor));
          cutPoints.add(loop.reduce((a, b) => a.compareTo(b) <= 0 ? a : b));
          break;
        }
        path.add(cursor);
        if (cutPoints.contains(cursor)) break;
        final parentId = byId[cursor]!.category.parentId;
        cursor = parentId != null && byId.containsKey(parentId)
            ? parentId
            : null;
      }
      settled.addAll(path);
    }

    final roots = <CategoryWithTotal>[];
    final childrenById = <String, List<CategoryWithTotal>>{};
    for (final entry in categories) {
      final id = entry.category.id;
      final parentId = entry.category.parentId;
      final hasVisibleParent =
          id != null &&
          parentId != null &&
          byId.containsKey(parentId) &&
          !cutPoints.contains(id);
      if (hasVisibleParent) {
        (childrenById[parentId] ??= <CategoryWithTotal>[]).add(entry);
      } else {
        roots.add(entry);
      }
    }

    return CategoryTree._(
      List<CategoryWithTotal>.unmodifiable(roots),
      childrenById,
      byId,
    );
  }

  /// The categories to draw at the top level, in the order they arrived.
  final List<CategoryWithTotal> roots;

  final Map<String, List<CategoryWithTotal>> _childrenById;

  final Map<String, CategoryWithTotal> _byId;

  /// The entry for [categoryId], or null when nothing visible carries that id.
  CategoryWithTotal? entryOf(String categoryId) => _byId[categoryId];

  /// The categories nested directly under [categoryId], in the order they
  /// arrived. Never contains [categoryId] itself, and following it can never
  /// come back to a category already passed.
  List<CategoryWithTotal> childrenOf(String categoryId) =>
      _childrenById[categoryId] ?? const <CategoryWithTotal>[];
}

/// [categoryId] and everything under it, however deep.
///
/// This is the set a category may not be reparented into: picking any of them
/// makes a loop, and picking itself makes the shortest one. [CategoryTree]
/// draws such a loop safely, but only by cutting it somewhere the user did not
/// choose, so the picker keeps them out of the list in the first place.
///
/// Loop-safe on the way in as well: the categories handed to it may already
/// contain one, and walking it must still terminate.
Set<String> categorySubtreeIds(String categoryId, List<Category> categories) {
  final childrenById = <String, List<String>>{};
  for (final category in categories) {
    final id = category.id;
    final parentId = category.parentId;
    if (id == null || parentId == null) continue;
    (childrenById[parentId] ??= <String>[]).add(id);
  }

  final subtree = <String>{categoryId};
  final pending = <String>[categoryId];
  while (pending.isNotEmpty) {
    for (final childId
        in childrenById[pending.removeLast()] ?? const <String>[]) {
      if (subtree.add(childId)) pending.add(childId);
    }
  }
  return subtree;
}
