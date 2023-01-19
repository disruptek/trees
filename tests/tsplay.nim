#import std/unittest

import pkg/balls

include pkg/trees/splay

proc main =
  suite "splay tree":
    test "splay initialization":
      var tree: SplayTree[int, char]
      check tree.size == 0

    test "splay insert":
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

    test "splay find":
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

    test "splay remove":
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

    test "splay iteration":
      var tree: SplayTree[int, char]
      for i in 1..10:
        tree.insert(i, 'a')
      var i = 1
      for key, value in tree.pairs:
        check i == key
        inc i
      check i == 11

main()
