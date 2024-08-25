# trees

[![Test Matrix](https://github.com/disruptek/trees/workflows/CI/badge.svg)](https://github.com/disruptek/trees/actions?query=workflow%3ACI)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/disruptek/trees?style=flat)](https://github.com/disruptek/trees/releases/latest)
![Supported Nim version](https://img.shields.io/badge/nim-2.0.10-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/disruptek/trees?style=flat)](#license)
[![IRC](https://img.shields.io/badge/chat-%23%23disruptek%20on%20libera.chat-brightgreen?style=flat)](https://web.libera.chat/##disruptek)

This is a fork of https://github.com/brianshannan/nim-trees with some
modernization.  I merged in https://github.com/dcurrie/nim-bbtree, also.

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

## BBTree

BBTrees, also known as Weight Balanced Trees, or Adams Trees, are a persistent
data structure with a nice combination of properties:

* Generic (parameterized) key,value map
* Insert (`add`), lookup (`get`), and delete (`del`) in O(log(N)) time
* Key-ordered iterators (`inorder` and `revorder`)
* Lookup by relative position from beginning or end (`getNth`) in O(log(N)) time
* Get the position (`rank`) by key in O(log(N)) time
* Efficient set operations using tree keys
* Map extensions to set operations with optional value merge control for duplicates

By "persistent" we mean that the BBTree always preserves the previous version
of itself when it is modified. As such it is effectively immutable, as the
operations do not (visibly) update the structure in-place, but instead always
yield a new updated structure.

The BBTree data structure resides in heap memory, and is destroyed by the
garbage collector when there are no longer any program references to it. When
insertions or deletions to the tree are made, we attempt to reuse as much of
the old structure as possible.

Because the BBTree is never mutated all library functions that operate on it
are Nim `func` -- no side effects. A BBTree may be shared across threads safely
(though updates in one thread will not be visible in another until the modified
tree is shared once again).

### BBTree Credits

References:

*Implementing Sets Efficiently in a Functional Language*
Stephen Adams
CSTR 92-10
Department of Electronics and Computer Science University of Southampton Southampton S09 5NH

*Adams’ Trees Revisited Correct and Efficient Implementation*
Milan Straka
Department of Applied Mathematics Charles University in Prague, Czech Republic

[Weight-balanced trees](https://en.wikipedia.org/wiki/Weight-balanced_tree) on Wikipedia

## License
Apache-2.0
- RB, Splay, AVL
MIT
- BBTree
