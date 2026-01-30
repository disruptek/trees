import std/algorithm
import std/random

import pkg/balls

include pkg/trees/splay

proc main =
  proc checkTree(tree: SplayTree[int, char]) =
    check(tree.len() == 3)
    var found: char
    check(tree.find(10, found) and found == 'c')
    check(tree.find(5, found) and found == 'b')
    check(tree.find(1, found) and found == 'a')
    check(not tree.find(2, found))

  proc checkOrder(tree: SplayTree[int, int]; x: seq[int]) =
    var a: seq[int]
    for k, v in tree.pairs:
      a.add k
    var b = x
    sort b
    if a != b:
      checkpoint " tree: ", a
      checkpoint "order: ", b
      fail"tree is out-of-order"

  suite "splay tree":
    test "splay initialization":
      var tree: SplayTree[int, char]
      check tree.size == 0

    test "splay simple insert":
      var tree: SplayTree[int, char]
      check(tree.insert(5, 'b'))
      check(tree.insert(10, 'c'))
      check(not tree.insert(5, 'd'))
      check(tree.len() == 2)
      var found: char
      check(tree.find(5, found) and found == 'd')
      check(tree.find(10, found) and found == 'c')
      check(not tree.find(15, found))

    test "splay insert balanced":
      var tree: SplayTree[int, char]
      check(tree.insert(5, 'b'))
      check(tree.insert(1, 'a'))
      check(tree.insert(10, 'c'))
      checkTree(tree)

    test "splay insert right leaning":
      var tree: SplayTree[int, char]
      check(tree.insert(1, 'a'))
      check(tree.insert(5, 'b'))
      check(tree.insert(10, 'c'))
      checkTree(tree)

    test "splay insert right leaning double rotation":
      var tree: SplayTree[int, char]
      check(tree.insert(1, 'a'))
      check(tree.insert(10, 'c'))
      check(tree.insert(5, 'b'))
      checkTree(tree)

    test "splay insert left leaning":
      var tree: SplayTree[int, char]
      check(tree.insert(10, 'c'))
      check(tree.insert(5, 'b'))
      check(tree.insert(1, 'a'))
      checkTree(tree)

    test "splay insert left leaning double rotation":
      var tree: SplayTree[int, char]
      check(tree.insert(10, 'c'))
      check(tree.insert(1, 'a'))
      check(tree.insert(5, 'b'))
      checkTree(tree)

    test "splay insert and splay behavior":
      var tree: SplayTree[int, char]
      check tree.insert(1, 'a')
      check tree.insert(10, 'c')
      check tree.root.key == 10 and tree.root.value == 'c'
      check tree.root.left.key == 1 and tree.root.left.value == 'a'
      check tree.insert(5, 'b')
      check tree.root.key == 5 and tree.root.value == 'b'
      check tree.root.left.key == 1 and tree.root.left.value == 'a'
      check tree.root.right.key == 10 and tree.root.right.value == 'c'
      check not tree.insert(1, 'd')
      check tree.root.key == 1 and tree.root.value == 'd'
      check tree.len == 3

    test "splay find and splay behavior":
      var tree: SplayTree[int, char]
      check tree.insert(1, 'a')
      check tree.insert(10, 'c')
      check tree.insert(5, 'b')
      check tree.insert(20, 'e')
      var found: char
      check tree.find(5, found) and found == 'b'
      check tree.root.key == 5 and tree.root.value == 'b'
      check tree.find(20, found) and found == 'e'
      check tree.root.key == 20 and tree.root.value == 'e'
      check tree.find(1, found) and found == 'a'
      check tree.root.key == 1 and tree.root.value == 'a'
      check tree.find(10, found) and found == 'c'
      check tree.root.key == 10 and tree.root.value == 'c'
      check not tree.find(7, found) and found == 'c'
      check tree.root.key == 5 and tree.root.value == 'b'
      check tree.len == 4

    test "splay in-order traversal":
      var tree: SplayTree[int, char]
      for i in 1..10:
        tree.insert(i, chr(ord('a') + i))
      var i = 1
      for key, value in tree.pairs():
        check(i == key)
        i += 1
      check(i == 11)

    test "splay remove simple":
      var tree: SplayTree[int, char]
      tree.insert(10, 'a')
      tree.insert(15, 'b')
      tree.insert(20, 'c')

      tree.remove(20)
      check(tree.len() == 2)
      var found: char
      check(tree.find(10, found) and found == 'a')
      check(tree.find(15, found) and found == 'b')
      check(not tree.find(20, found))

      tree.remove(15)
      check(tree.len() == 1)
      check(tree.find(10, found) and found == 'a')
      check(not tree.find(15, found))
      check(not tree.find(20, found))

      tree.remove(10)
      check(tree.len() == 0)
      check(not tree.find(10, found))
      check(not tree.find(15, found))
      check(not tree.find(20, found))

    test "splay remove rotation":
      var tree: SplayTree[int, char]
      tree.insert(1, 'a')
      tree.insert(5, 'b')
      tree.insert(10, 'c')
      tree.insert(15, 'd')
      tree.insert(20, 'e')

      tree.remove(1)
      check(tree.len() == 4)
      var found: char
      check(not tree.find(1, found))
      check(tree.find(5, found) and found == 'b')
      check(tree.find(10, found) and found == 'c')
      check(tree.find(15, found) and found == 'd')
      check(tree.find(20, found) and found == 'e')

    test "splay remove double rotation":
      var tree: SplayTree[int, char]
      tree.insert(5, 'b')
      tree.insert(1, 'a')
      tree.insert(10, 'c')
      tree.insert(15, 'd')

      tree.remove(1)
      check(tree.len() == 3)
      var found: char
      check(not tree.find(1, found))
      check(tree.find(5, found) and found == 'b')
      check(tree.find(10, found) and found == 'c')
      check(tree.find(15, found) and found == 'd')

    test "splay remove non-leaf (successor bug regression)":
      # This test specifically checks the successor bug fix
      # When removing an internal node with two children, the successor
      # (minimum of right subtree) should be used, not the maximum
      var tree: SplayTree[int, char]
      tree.insert(1, 'a')
      tree.insert(2, 'b')
      tree.insert(3, 'c')
      tree.insert(4, 'd')
      tree.insert(5, 'e')

      # Remove 3 which has both left (1,2) and right (4,5) subtrees
      # Successor of 3 is 4 (minimum of right subtree), not 5
      tree.remove(3)
      check(tree.len() == 4)
      var found: char
      check(tree.find(1, found) and found == 'a')
      check(tree.find(2, found) and found == 'b')
      check(not tree.find(3, found))
      check(tree.find(4, found) and found == 'd')
      check(tree.find(5, found) and found == 'e')

      # Verify tree is still in order after removal
      var lastKey = low(int)
      for k, v in tree.pairs:
        check k > lastKey
        lastKey = k

    test "splay remove internal node":
      var tree: SplayTree[int, char]
      check tree.insert(1, 'a')
      check tree.insert(5, 'b')
      check tree.insert(15, 'd')
      check tree.insert(10, 'c')
      check tree.remove(10)
      check tree.root.key == 15 and tree.root.value == 'd'
      check tree.len == 3
      check tree.insert(-5, 'z')
      check tree.remove(1)
      check tree.root.key == 15 and tree.root.value == 'd'
      check tree.len == 3
      var found: char
      check tree.find(-5, found) and found == 'z'
      check tree.find(5, found) and found == 'b'
      check tree.find(15, found) and found == 'd'

    test "splay remove non-existent":
      var tree: SplayTree[int, char]
      tree.insert(1, 'a')
      tree.insert(5, 'b')
      check(tree.len() == 2)
      check(not tree.remove(10))
      check(tree.len() == 2)

    test "splay stress in-order":
      var tree: SplayTree[int, int]
      var rng = initRand(0x12345678)
      const N = 1_000
      var x = newSeqOfCap[int](N)
      for i in 0..<N:
        x.add i
      var y = x
      shuffle(rng, x)
      for i, n in x.pairs:
        check tree.insert(n, i)
        checkOrder(tree, x[0..i])
      reverse y
      var keys: seq[int]
      for k, v in tree.pairs:
        keys.add k
      reverse keys
      while keys.len > 0:
        let k = pop keys
        discard pop y
        check tree.remove k
        checkOrder(tree, y)

    test "splay stress out-of-order":
      var tree: SplayTree[int, int]
      var rng = initRand(0x87654321)
      const N = 1_000
      var x = newSeqOfCap[int](N)
      for i in 0..<N:
        x.add i
      shuffle(rng, x)
      for i, n in x.pairs:
        check tree.insert(n, i)
      shuffle(rng, x)
      while x.len > 0:
        check tree.remove(pop x)
        checkOrder(tree, x)
      check tree.len == 0

main()
