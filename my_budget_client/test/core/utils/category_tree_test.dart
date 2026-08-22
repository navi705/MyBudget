// What a category screen is allowed to lose: nothing.
//
// `parent_id` points at a row that may be deleted, filtered out, still on a
// later page, or - after two devices reparent in opposite directions - at a row
// that points back. The old rule ("top level means parentId == null") answered
// all four cases by drawing neither the category nor its parent, which took an
// editable row off the screen and left its money in the totals.
//
// So the property pinned here is total: every entry handed in comes back out
// exactly once, as a root or under exactly one visible parent, no matter how
// broken the links are. The loop tests also pin *which* row is promoted,
// because two devices that cut the same loop in different places would draw
// two different trees from one database.
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/category_tree.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';

CategoryWithTotal cat(String id, {String? parent}) => CategoryWithTotal(
  category: Category(
    id: id,
    name: id,
    type: CategoryType.expense,
    parentId: parent,
  ),
  total: 0,
);

List<String> ids(List<CategoryWithTotal> entries) =>
    entries.map((e) => e.category.id!).toList();

/// Everything the tree contains, root or nested, walked depth first.
List<String> reachable(CategoryTree tree) {
  final seen = <String>[];
  void visit(CategoryWithTotal entry) {
    final id = entry.category.id!;
    // A second visit means the walk is looping - the one thing the tree exists
    // to make impossible.
    expect(seen, isNot(contains(id)), reason: 'visited $id twice');
    seen.add(id);
    tree.childrenOf(id).forEach(visit);
  }

  tree.roots.forEach(visit);
  return seen;
}

void main() {
  group('CategoryTree', () {
    test('nests children under the parent they name', () {
      final tree = CategoryTree.of([
        cat('home'),
        cat('rent', parent: 'home'),
        cat('food'),
      ]);

      expect(ids(tree.roots), ['home', 'food']);
      expect(ids(tree.childrenOf('home')), ['rent']);
      expect(tree.childrenOf('rent'), isEmpty);
    });

    test('keeps the order it was given', () {
      // The list arrives sorted by the filter bar of the screen. Rebuilding the
      // tree must not quietly re-sort it.
      final tree = CategoryTree.of([
        cat('c'),
        cat('a'),
        cat('b'),
        cat('a2', parent: 'a'),
        cat('a1', parent: 'a'),
      ]);

      expect(ids(tree.roots), ['c', 'a', 'b']);
      expect(ids(tree.childrenOf('a')), ['a2', 'a1']);
    });

    test('a child whose parent was deleted is drawn at the top level', () {
      // Deleting a category soft-deletes that row alone, so its children are
      // left naming an id no query returns. This is the common case: it needs
      // no sync and no second device.
      final tree = CategoryTree.of([cat('rent', parent: 'home'), cat('food')]);

      expect(ids(tree.roots), ['rent', 'food']);
      expect(reachable(tree), ['rent', 'food']);
    });

    test('a parent hidden by the type filter does not hide its child', () {
      // Nothing makes a child share the type of its parent, and the filter is
      // applied to a flat list before the tree is built.
      final tree = CategoryTree.of([cat('salary', parent: 'home')]);

      expect(ids(tree.roots), ['salary']);
    });

    test('a category that parents itself is a root, not its own child', () {
      final tree = CategoryTree.of([cat('loop', parent: 'loop'), cat('food')]);

      expect(ids(tree.roots), ['loop', 'food']);
      expect(tree.childrenOf('loop'), isEmpty);
      expect(reachable(tree), ['loop', 'food']);
    });

    test('a two-category loop is cut at the lower id', () {
      // The merge case: one device put b under a, the other put a under b, and
      // both updates are valid on their own. Every device has to cut it in the
      // same place or the fleet disagrees about the tree for good.
      final tree = CategoryTree.of([
        cat('b', parent: 'a'),
        cat('a', parent: 'b'),
      ]);

      expect(ids(tree.roots), ['a']);
      expect(ids(tree.childrenOf('a')), ['b']);
      expect(reachable(tree), ['a', 'b']);
    });

    test('the cut does not depend on the order the rows arrive in', () {
      final forwards = CategoryTree.of([
        cat('b', parent: 'c'),
        cat('c', parent: 'a'),
        cat('a', parent: 'b'),
      ]);
      final backwards = CategoryTree.of([
        cat('a', parent: 'b'),
        cat('c', parent: 'a'),
        cat('b', parent: 'c'),
      ]);

      expect(ids(forwards.roots), ['a']);
      expect(ids(backwards.roots), ['a']);
      expect(reachable(forwards).toSet(), {'a', 'b', 'c'});
      expect(reachable(backwards).toSet(), {'a', 'b', 'c'});
    });

    test('a tail hanging off a loop is drawn under the cut loop', () {
      // `tail` is not in the loop, so promoting it too would flatten the tree
      // further than the damage warrants.
      final tree = CategoryTree.of([
        cat('b', parent: 'a'),
        cat('a', parent: 'b'),
        cat('tail', parent: 'b'),
      ]);

      expect(ids(tree.roots), ['a']);
      expect(ids(tree.childrenOf('b')), ['tail']);
      expect(reachable(tree), ['a', 'b', 'tail']);
    });

    test('two independent loops are cut independently', () {
      final tree = CategoryTree.of([
        cat('b', parent: 'a'),
        cat('a', parent: 'b'),
        cat('z', parent: 'y'),
        cat('y', parent: 'z'),
      ]);

      expect(ids(tree.roots), ['a', 'y']);
      expect(reachable(tree).toSet(), {'a', 'b', 'y', 'z'});
    });

    test('a long chain survives whichever end it is walked from', () {
      // The walk settles ids it has already proven reach a root; a bug there
      // would drop the middle of a deep chain.
      final entries = [
        cat('n0'),
        for (var i = 1; i < 60; i++) cat('n$i', parent: 'n${i - 1}'),
      ];

      final tree = CategoryTree.of(entries.reversed.toList());

      expect(ids(tree.roots), ['n0']);
      expect(reachable(tree).length, 60);
    });

    test('every entry appears exactly once however broken the links are', () {
      final entries = [
        cat('root'),
        cat('kid', parent: 'root'),
        cat('orphan', parent: 'gone'),
        cat('self', parent: 'self'),
        cat('l1', parent: 'l2'),
        cat('l2', parent: 'l1'),
        cat('under_loop', parent: 'l2'),
      ];

      final tree = CategoryTree.of(entries);

      expect(reachable(tree).toSet(), ids(entries).toSet());
      expect(reachable(tree).length, entries.length);
    });

    test('an unsaved category with no id is a root', () {
      // Category.id is nullable, and a row without one cannot be the child of
      // anything - but it must not fall out of the list either.
      final tree = CategoryTree.of([
        CategoryWithTotal(
          category: Category(name: 'draft', type: CategoryType.expense),
          total: 0,
        ),
      ]);

      expect(tree.roots.length, 1);
      expect(tree.roots.single.category.name, 'draft');
    });

    test('an empty list has no roots and no children', () {
      final tree = CategoryTree.of(const []);

      expect(tree.roots, isEmpty);
      expect(tree.childrenOf('anything'), isEmpty);
    });
  });

  group('categorySubtreeIds', () {
    List<Category> plain(List<CategoryWithTotal> entries) =>
        entries.map((e) => e.category).toList();

    test('is the category itself when nothing hangs off it', () {
      expect(categorySubtreeIds('a', plain([cat('a'), cat('b')])), {'a'});
    });

    test('reaches children, grandchildren and no further', () {
      final categories = plain([
        cat('home'),
        cat('rent', parent: 'home'),
        cat('deposit', parent: 'rent'),
        cat('food'),
        cat('bread', parent: 'food'),
      ]);

      expect(categorySubtreeIds('home', categories), {
        'home',
        'rent',
        'deposit',
      });
      expect(categorySubtreeIds('rent', categories), {'rent', 'deposit'});
    });

    test('terminates on a list that already contains a loop', () {
      // The picker is opened on databases that already merged a loop, so this
      // walk has to survive one rather than assume the tree is sound.
      final categories = plain([
        cat('a', parent: 'b'),
        cat('b', parent: 'a'),
        cat('tail', parent: 'b'),
      ]);

      expect(categorySubtreeIds('a', categories), {'a', 'b', 'tail'});
    });

    test('a category that parents itself is its own whole subtree', () {
      expect(categorySubtreeIds('self', plain([cat('self', parent: 'self')])), {
        'self',
      });
    });

    test('an id that is not in the list is still excluded from itself', () {
      expect(categorySubtreeIds('ghost', plain([cat('a')])), {'ghost'});
    });
  });
}
