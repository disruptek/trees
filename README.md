# trees

[![Test Matrix](https://github.com/disruptek/trees/workflows/CI/badge.svg)](https://github.com/disruptek/trees/actions?query=workflow%3ACI)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/disruptek/trees?style=flat)](https://github.com/disruptek/trees/releases/latest)
![Supported Nim version](https://img.shields.io/badge/nim-2.0.10-informational?style=flat&logo=nim)
[![License](https://img.shields.io/github/license/disruptek/trees?style=flat)](#license)
[![IRC](https://img.shields.io/badge/chat-%23%23disruptek%20on%20libera.chat-brightgreen?style=flat)](https://web.libera.chat/##disruptek)

This is a fork of https://github.com/brianshannan/nim-trees with some
modernization. I merged in https://github.com/dcurrie/nim-bbtree, also.

## Common API

All mutable trees (AVL, RedBlack, Splay, WAVL) share a consistent API:

| Operation | Signature | Description |
|-----------|-----------|-------------|
| `insert` | `(key, value): bool` | Insert or update; returns `true` if new key |
| `find` | `(key): (V, bool)` | Lookup; returns value and found flag |
| `find` | `(key, var V): bool` | Lookup; copies value, returns found flag |
| `remove` | `(key): bool` | Delete; returns `true` if key existed |
| `pop` | `(key): V` | Delete and return value; raises `KeyError` |
| `contains` | `(key): bool` | Membership test |
| `len` | `(): int` | Number of items |
| `min` | `(): (K, V)` | Smallest key/value; raises `ValueError` if empty |
| `max` | `(): (K, V)` | Largest key/value; raises `ValueError` if empty |
| `popMin` | `(): (K, V)` | Remove and return smallest; raises `ValueError` |
| `popMax` | `(): (K, V)` | Remove and return largest; raises `ValueError` |
| `select` | `(i): (K, V)` | Item by 0-indexed rank; raises `IndexDefect` |
| `rank` | `(key): Natural` | 0-indexed position of key; raises `KeyError` |
| `[]` | `(key): var V` | Lookup; raises `KeyError` if not found |
| `[]=` | `(key, value)` | Insert or update |
| `pairs` | iterator | In-order (key, value) pairs |
| `keys` | iterator | In-order keys |
| `values` | iterator | In-order values |

### Rank and Select (Order Statistics)

All trees support order statistics via `rank` and `select`:

- **`select(i)`** returns the `i`th smallest item (0-indexed). Negative indices
  count from the end: `select(-1)` returns the largest item.
- **`rank(key)`** returns the 0-indexed position of `key` in sorted order.

```nim
var tree: AVLTree[int, string]
tree.insert(10, "ten")
tree.insert(5, "five")
tree.insert(15, "fifteen")

echo tree.select(0)   # (5, "five")   - smallest
echo tree.select(1)   # (10, "ten")   - middle
echo tree.select(-1)  # (15, "fifteen") - largest
echo tree.rank(10)    # 1
```

## AVL

AVL trees are strictly balanced binary search trees.

**Virtues:**
- Fastest lookups due to strict balancing (height ≤ 1.44 log₂(n))
- Predictable O(log n) worst-case for all operations
- Best choice for read-heavy workloads

**Drawbacks:**
- More rotations on insert/delete than Red-Black or WAVL
- Slightly slower writes than Red-Black trees

**Complexity:** O(log n) insert, remove, find; O(n) space and iteration.

Algorithm adapted from [Wikipedia](https://en.wikipedia.org/wiki/AVL_tree).

## Red-Black

Red-Black trees are balanced binary search trees with relaxed balancing.

**Virtues:**
- Fewer rotations than AVL on insert/delete
- Good all-around performance for mixed workloads
- Widely used in standard libraries (C++ std::map, Java TreeMap)

**Drawbacks:**
- Slightly slower lookups than AVL (height ≤ 2 log₂(n))
- More complex implementation

**Complexity:** O(log n) insert, remove, find; O(n) space and iteration.

Algorithm adapted from [CLRS](http://staff.ustc.edu.cn/~csli/graduate/algorithms/book6/chap14.htm).

## WAVL

WAVL (Weak AVL) trees use rank differences instead of balance factors.

**Virtues:**
- At most 2 rotations per insert or delete (vs O(log n) for AVL delete)
- Without deletions, equivalent to AVL trees
- All WAVL trees are valid Red-Black trees
- Good balance between AVL strictness and Red-Black flexibility

**Drawbacks:**
- Slightly more complex than AVL or Red-Black
- Less widely known/documented

**Complexity:** O(log n) insert, remove, find; O(n) space and iteration.

Algorithm adapted from [Wikipedia](https://en.wikipedia.org/wiki/WAVL_tree).

## Splay

Splay trees are self-adjusting binary search trees that move accessed nodes
to the root.

**Virtues:**
- Excellent cache locality for repeated access patterns
- Amortized O(log n) without storing balance information
- Recently accessed items are O(1) to access again
- Simpler implementation than balanced trees

**Drawbacks:**
- O(n) worst-case for individual operations
- Mutates tree structure on reads (not thread-safe for concurrent reads)
- Poor performance with uniform random access patterns

**Complexity:** Amortized O(log n) insert, remove, find; O(n) space and iteration.

**Additional API:**
- `peek(key): (V, bool)` - Query without splaying (const operation)

Algorithm adapted from [Wikipedia](https://en.wikipedia.org/wiki/Splay_tree).

## BBTree

BBTrees (Bounded Balance Trees), also known as Weight Balanced Trees or Adams
Trees, are a **persistent** (immutable) data structure.

**Virtues:**
- Persistent/immutable: operations return new trees, old versions preserved
- Thread-safe without locks (immutable)
- Rich set operations (union, intersection, difference)
- O(log n) order statistics (`getNth`, `rank`)
- Functional programming friendly

**Drawbacks:**
- Higher memory allocation (creates new nodes on modification)
- Different API than mutable trees (functions take and return trees)
- No in-place mutation

**Complexity:** O(log n) insert, remove, find, getNth, rank; O(n) space and
iteration; O(m + n) for set operations.

### BBTree API Differences

BBTree uses a functional style where operations return new trees:

| Mutable Trees | BBTree Equivalent |
|---------------|-------------------|
| `tree.insert(k, v)` | `tree = insert(tree, k, v)` |
| `tree.remove(k)` | `tree = remove(tree, k)` |
| `tree.find(k)` | `find(tree, k, default)` |
| `tree.min()` | `getMin(tree, default)` |
| `tree.max()` | `getMax(tree, default)` |
| `tree.popMin()` | `(getMin(tree, d), delMin(tree))` |
| `tree.popMax()` | `(getMax(tree, d), delMax(tree))` |
| `tree.select(i)` | `getNth(tree, i, default)` |
| `tree.rank(k)` | `rank(tree, k, default)` |

### BBTree-Specific Operations

```nim
# Successor/predecessor
getNext(tree, key, default)  # smallest key > key
getPrev(tree, key, default)  # largest key < key

# Set operations
union(tree1, tree2)
intersection(tree1, tree2)
difference(tree1, tree2)
symmetricDifference(tree1, tree2)

# Set predicates
isSubset(tree1, tree2)
isProperSubset(tree1, tree2)
disjoint(tree1, tree2)
setEqual(tree1, tree2)

# Operators
tree1 + tree2   # union
tree1 * tree2   # intersection
tree1 - tree2   # difference
tree1 -+- tree2 # symmetric difference
tree1 < tree2   # proper subset
tree1 <= tree2  # subset
tree1 =?= tree2 # set equality

# Functional operations
map(tree, proc(k, v): T)
fold(tree, proc(k, v, acc): T, init)
toSet(keys)  # create set from array

# Additional iterators
inorder(tree)   # alias for pairs
revorder(tree)  # reverse order
```

### BBTree References

- Adams, *Implementing Sets Efficiently in a Functional Language*, CSTR 92-10
- Straka, *Adams' Trees Revisited*, 2011
- [Weight-balanced trees](https://en.wikipedia.org/wiki/Weight-balanced_tree) on Wikipedia

## Choosing a Tree

| Use Case | Recommended Tree |
|----------|------------------|
| Read-heavy workload | AVL |
| Write-heavy workload | Red-Black |
| Mixed reads/writes | Red-Black or WAVL |
| Repeated access to same keys | Splay |
| Need immutability/persistence | BBTree |
| Set operations (union, etc.) | BBTree |
| Thread-safe reads | BBTree |
| Memory constrained | AVL or Red-Black |

## License

- AVL, Red-Black, Splay, WAVL: Apache-2.0
- BBTree: MIT
