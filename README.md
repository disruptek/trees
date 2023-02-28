# trees

[![Test Matrix](https://github.com/disruptek/trees/workflows/CI/badge.svg)](https://github.com/disruptek/trees/actions?query=workflow%3ACI)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/disruptek/trees?style=flat)](https://github.com/disruptek/trees/releases/latest)
![Minimum supported Nim version](https://img.shields.io/badge/nim-1.9.1-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/disruptek/trees?style=flat)](#license)
[![IRC](https://img.shields.io/badge/chat-%23%23disruptek%20on%20libera.chat-brightgreen?style=flat)](https://web.libera.chat/##disruptek)

This is a fork of https://github.com/brianshannan/nim-trees with some
modernization.

## AVL

AVL trees are balanced binary search trees with the following worst time
complexities for common operations:
- space: O(n)
- insert: O(lg(n))
- remove: O(lg(n))
- find: O(lg(n))
- in-order iteration: O(n)

These worst-case complexities are better than a hashtable, and binary search
trees can offer better performance if the size of the data is not known in
advance, as trees don't have to rehash all entries for a resize. Trees can also
be useful in systems where operations must be guaranteed to complete quickly,
an operation requiring a table resize could take too long.

AVL trees are more rigidly balanced than Red-Black trees, and are generally
more performant in read heavy applications. That being said, there isn't a huge
performance difference between the trees.

Algorithms adapted from Wikipedia; see https://en.wikipedia.org/wiki/AVL_tree.

## Red-Black

Red-Black trees are balanced binary search trees with the following worst-case
time complexities for common operations:
- space: O(n)
- insert: O(lg(n))
- remove: O(lg(n))
- find: O(lg(n))
- in-order iteration: O(n)

Red-Black trees are very similar to AVL trees, except are less rigidly
balanced.

Algorithms adapted from
http://staff.ustc.edu.cn/~csli/graduate/algorithms/book6/chap14.htm.

## Splay

Splay trees are binary search trees that don't apply balance operations on each
insert/remove, and as such are unbalanced and don't provide a O(lg(n)) worst
case insert/remove. Instead, splay trees rotate newly added and searched for
data to the top of the tree so commonly accessed data and newly inserted items
are very fast to find, as you don't have to go through a large part of the tree
to find them. Splay tree double rotations are slightly different than normal
double tree rotations, so data ascends the tree quickly, but descends much
slower. This is good enough to offer amortized lg(n) time for insert, remove
and find.

Algorithm's adapted from wikipedia, see https://en.wikipedia.org/wiki/Splay_tree

## License
Apache-2.0
