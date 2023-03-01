import pkg/balls

include pkg/trees/avl

proc main =
  proc checkTree(tree: AVLTree[int, char]) =
    check(tree.len() == 3)
    check(tree.find(10) == ('c', true))
    check(tree.find(5) == ('b', true))
    check(tree.find(1) == ('a', true))
    check(tree.find(2) == ('\0', false))

    check(tree.root.key == 5)
    check(tree.root.right.key == 10)
    check(tree.root.left.key == 1)

  suite "avl tree":
    test "simple insert":
      var tree: AVLTree[int, char]
      check(tree.insert(5, 'b'))
      check(tree.insert(10, 'c'))
      check(not tree.insert(5, 'd'))
      check(tree.len() == 2)
      check(tree.find(5) == ('d', true))
      check(tree.find(10) == ('c', true))
      check(tree.find(15) == ('\0', false))

    test "insert balanced":
      var tree: AVLTree[int, char]
      check(tree.insert(5, 'b'))
      check(tree.insert(1, 'a'))
      check(tree.insert(10, 'c'))
      checkTree(tree)

    test "insert right leaning":
      var tree: AVLTree[int, char]
      check(tree.insert(1, 'a'))
      check(tree.insert(5, 'b'))
      check(tree.insert(10, 'c'))
      checkTree(tree)

    test "insert right leaning double rotation":
      var tree: AVLTree[int, char]
      check(tree.insert(1, 'a'))
      check(tree.insert(10, 'c'))
      check(tree.insert(5, 'b'))
      checkTree(tree)

    test "insert left leaning":
      var tree: AVLTree[int, char]
      check(tree.insert(10, 'c'))
      check(tree.insert(5, 'b'))
      check(tree.insert(1, 'a'))
      checkTree(tree)

    test "insert left leaning double rotation":
      var tree: AVLTree[int, char]
      check(tree.insert(10, 'c'))
      check(tree.insert(1, 'a'))
      check(tree.insert(5, 'b'))
      checkTree(tree)

    test "in-order traversal":
      var tree: AVLTree[int, char]
      for i in 1..10:
        tree.insert(i, chr(ord('a') + i))
      var i = 1
      for key, value in tree.pairs():
        check(i == key)
        i += 1
      check(i == 11)
      i = 1
      for key in tree.keys():
        check(i == key)
        i += 1
      check(i == 11)
      i = 1
      for value in tree.values():
        check(i == ord(value) - ord('a'))
        i += 1
      check(i == 11)

    test "remove simple":
      var tree: AVLTree[int, char]
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

    test "remove rotation":
      var tree: AVLTree[int, char]
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

    test "remove double rotation":
      var tree: AVLTree[int, char]
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

    test "remove non-leaf":
      var tree: AVLTree[int, char]
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

    test "remove non-existent":
      var tree: AVLTree[int, char]
      tree.insert(1, 'a')
      tree.insert(5, 'b')
      check(tree.len() == 2)
      tree.remove(10)
      check(tree.len() == 2)

    test "natural api":
      var tree: AVLTree[int, char]
      check(tree.insert(1, 'a'))
      check(tree.insert(5, 'b'))
      check(tree.insert(10, 'c'))
      tree[1] = 'a'
      tree[5] = 'b'
      tree[5] = 'd'
      check tree[1] == 'a'
      check tree[10] == 'c'
      check tree.pop(1) == 'a'
      tree.pop(10)
      check tree[5] == 'd'

    test "select, rank":
      var tree: AVLTree[int, char]
      check tree.insert(5, 'b')
      check tree.select(1).key == 5
      check tree.insert(10, 'c')
      check tree.select(1).key == 5
      check tree.select(2).key == 10
      check tree.insert(1, 'a')
      check tree.select(1).val == 'a'
      check tree.select(1).key == 1
      check tree.select(2).key == 5
      check tree.select(3).key == 10
      check tree.select(3).val == 'c'
      check 1 == tree.rank(tree.select(1).key)
      check 2 == tree.rank(tree.select(2).key)
      check 3 == tree.rank(tree.select(3).key)

main()
