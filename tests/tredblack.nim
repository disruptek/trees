import std/algorithm
import std/random
import std/sequtils

import pkg/balls

import pkg/trees/redblack

proc main =
  proc checkTree(tree: RedBlackTree[int, char]) =
    check(tree.len() == 3)
    check(tree.find(10) == ('c', true))
    check(tree.find(5) == ('b', true))
    check(tree.find(1) == ('a', true))
    check(tree.find(2) == ('\0', false))

  proc checkOrder(tree: RedBlackTree[int, int]; x: seq[int]) =
    let a = toSeq tree.keys
    var b = x
    sort b
    if a != b:
      checkpoint " tree: ", a
      checkpoint "order: ", b
      fail"tree is out-of-order"

  suite "red black tree":
    test "red black initialization":
      check(newRedBlackTree[int, char]() != nil)

    test "red black simple insert":
      let tree = newRedBlackTree[int, char]()
      check(tree.insert(5, 'b'))
      check(tree.insert(10, 'c'))
      check(not tree.insert(5, 'd'))
      check(tree.len() == 2)
      check(tree.find(5) == ('d', true))
      check(tree.find(10) == ('c', true))
      check(tree.find(15) == ('\0', false))

    test "red black insert balanced":
      let tree = newRedBlackTree[int, char]()
      check(tree.insert(5, 'b'))
      check(tree.insert(1, 'a'))
      check(tree.insert(10, 'c'))
      checkTree(tree)

    test "red black insert right leaning":
      let tree = newRedBlackTree[int, char]()
      check(tree.insert(1, 'a'))
      check(tree.insert(5, 'b'))
      check(tree.insert(10, 'c'))
      checkTree(tree)

    test "red black insert right leaning double rotation":
      let tree = newRedBlackTree[int, char]()
      check(tree.insert(1, 'a'))
      check(tree.insert(10, 'c'))
      check(tree.insert(5, 'b'))
      checkTree(tree)

    test "red black insert left leaning":
      let tree = newRedBlackTree[int, char]()
      check(tree.insert(10, 'c'))
      check(tree.insert(5, 'b'))
      check(tree.insert(1, 'a'))
      checkTree(tree)

    test "red black insert left leaning double rotation":
      let tree = newRedBlackTree[int, char]()
      check(tree.insert(10, 'c'))
      check(tree.insert(1, 'a'))
      check(tree.insert(5, 'b'))
      checkTree(tree)

    test "red black inorder":
      let tree = newRedBlackTree[int, char]()
      for i in 1..10:
        tree.insert(i, 'a')
      var i = 1
      for key, value in tree.pairs():
        check(i == key)
        i += 1
      check(i == 11)

    test "red black remove simple":
      let tree = newRedBlackTree[int, char]()
      tree.insert(10, 'a')
      tree.insert(15, 'b')
      tree.insert(20, 'c')

      tree.remove(20)
      check(tree.len() == 2)
      check(tree.find(10) == ('a', true))
      check(tree.find(15) == ('b', true))
      check(tree.find(20) == ('\0', false))

      tree.remove(15)
      check(tree.len() == 1)
      check(tree.find(10) == ('a', true))
      check(tree.find(15) == ('\0', false))
      check(tree.find(20) == ('\0', false))

      tree.remove(10)
      check(tree.len() == 0)
      check(tree.find(10) == ('\0', false))
      check(tree.find(15) == ('\0', false))
      check(tree.find(20) == ('\0', false))

    test "red black remove rotation":
      let tree = newRedBlackTree[int, char]()
      tree.insert(1, 'a')
      tree.insert(5, 'b')
      tree.insert(10, 'c')
      tree.insert(15, 'd')
      tree.insert(20, 'e')

      tree.remove(1)
      check(tree.len() == 4)
      check(tree.find(1) == ('\0', false))
      check(tree.find(5) == ('b', true))
      check(tree.find(10) == ('c', true))
      check(tree.find(15) == ('d', true))
      check(tree.find(20) == ('e', true))

    test "red black remove double rotation":
      let tree = newRedBlackTree[int, char]()
      tree.insert(5, 'b')
      tree.insert(1, 'a')
      tree.insert(10, 'c')
      tree.insert(15, 'd')

      tree.remove(1)
      check(tree.len() == 3)
      check(tree.find(1) == ('\0', false))
      check(tree.find(5) == ('b', true))
      check(tree.find(10) == ('c', true))
      check(tree.find(15) == ('d', true))

    test "red black remove non leaf":
      let tree = newRedBlackTree[int, char]()
      tree.insert(5, 'b')
      tree.insert(1, 'a')
      tree.insert(10, 'c')
      tree.insert(15, 'd')

      tree.remove(10)
      check(tree.len() == 3)
      check(tree.find(1) == ('a', true))
      check(tree.find(5) == ('b', true))
      check(tree.find(10) == ('\0', false))
      check(tree.find(15) == ('d', true))

    test "red black remove nonexistant":
      let tree = newRedBlackTree[int, char]()
      tree.insert(1, 'a')
      tree.insert(5, 'b')
      check(tree.len() == 2)
      tree.remove(10)
      check(tree.len() == 2)

    test "red black contains":
      let tree = newRedBlackTree[int, char]()
      tree.insert(1, 'a')
      tree.insert(5, 'b')
      check tree.contains(1)
      check tree.contains(5)
      check not tree.contains(10)

    test "red black find with var":
      let tree = newRedBlackTree[int, char]()
      tree.insert(1, 'a')
      tree.insert(5, 'b')
      var value: char
      check tree.find(1, value) and value == 'a'
      check tree.find(5, value) and value == 'b'
      check not tree.find(10, value)

    test "red black min max":
      let tree = newRedBlackTree[int, char]()
      tree.insert(5, 'b')
      tree.insert(1, 'a')
      tree.insert(10, 'c')
      check tree.min() == (1, 'a')
      check tree.max() == (10, 'c')

    test "red black popMin popMax":
      let tree = newRedBlackTree[int, char]()
      tree.insert(5, 'b')
      tree.insert(6, 'f')
      tree.insert(10, 'c')
      tree.insert(1, 'a')
      tree.insert(8, 'd')
      tree.insert(7, 'e')
      check tree.popMin() == (1, 'a')
      check tree.popMin() == (5, 'b')
      check tree.popMax() == (10, 'c')
      check tree.popMax() == (8, 'd')

    test "red black array access":
      let tree = newRedBlackTree[int, char]()
      tree[1] = 'a'
      tree[5] = 'b'
      tree[5] = 'd'
      check tree[1] == 'a'
      check tree[5] == 'd'
      check tree.pop(1) == 'a'
      tree.pop(5)
      check tree.len() == 0

    test "red black select rank (0-based)":
      let tree = newRedBlackTree[int, char]()
      tree.insert(5, 'b')
      check tree.select(0)[0] == 5
      tree.insert(10, 'c')
      check tree.select(0)[0] == 5
      check tree.select(1)[0] == 10
      tree.insert(1, 'a')
      check tree.select(0)[1] == 'a'
      check tree.select(0)[0] == 1
      check tree.select(1)[0] == 5
      check tree.select(2)[0] == 10
      check tree.select(-1)[0] == 10
      check tree.select(-2)[0] == 5
      check 0 == tree.rank(tree.select(0)[0])
      check 1 == tree.rank(tree.select(1)[0])
      check 2 == tree.rank(tree.select(2)[0])

    test "red black iterators":
      let tree = newRedBlackTree[int, char]()
      for i in 1..10:
        tree.insert(i, chr(ord('a') + i))
      var i = 1
      for key in tree.keys():
        check(i == key)
        i += 1
      check(i == 11)
      i = 1
      for value in tree.values():
        check(i == ord(value) - ord('a'))
        i += 1
      check(i == 11)

    test "red black stress":
      let tree = newRedBlackTree[int, int]()
      var rng = initRand(0x12345678)
      const N = 1_000
      var x = newSeqOfCap[int](N)
      for i in 0..<N:
        x.add i
      shuffle(rng, x)
      for i, n in x.pairs:
        check tree.insert(n, i)
        checkOrder(tree, x[0..i])
      shuffle(rng, x)
      while x.len > 0:
        check tree.remove(pop x)
        checkOrder(tree, x)
      check tree.len == 0

main()
