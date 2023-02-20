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
    test "avl simple insert":
      var tree: AVLTree[int, char]
      check(tree.insert(5, 'b'))
      check(tree.insert(10, 'c'))
      check(not tree.insert(5, 'd'))
      check(tree.len() == 2)
      check(tree.find(5) == ('d', true))
      check(tree.find(10) == ('c', true))
      check(tree.find(15) == ('\0', false))

    test "avl insert balanced":
      var tree: AVLTree[int, char]
      check(tree.insert(5, 'b'))
      check(tree.insert(1, 'a'))
      check(tree.insert(10, 'c'))
      checkTree(tree)

    test "avl insert right leaning":
      var tree: AVLTree[int, char]
      check(tree.insert(1, 'a'))
      check(tree.insert(5, 'b'))
      check(tree.insert(10, 'c'))
      checkTree(tree)

    test "avl insert right leaning double rotation":
      var tree: AVLTree[int, char]
      check(tree.insert(1, 'a'))
      check(tree.insert(10, 'c'))
      check(tree.insert(5, 'b'))
      checkTree(tree)

    test "avl insert left leaning":
      var tree: AVLTree[int, char]
      check(tree.insert(10, 'c'))
      check(tree.insert(5, 'b'))
      check(tree.insert(1, 'a'))
      checkTree(tree)

    test "avl insert left leaning double rotation":
      var tree: AVLTree[int, char]
      check(tree.insert(10, 'c'))
      check(tree.insert(1, 'a'))
      check(tree.insert(5, 'b'))
      checkTree(tree)

    test "avl inorder":
      var tree: AVLTree[int, char]
      for i in 1..10:
        tree.insert(i, 'a')
      var i = 1
      for key, value in tree.inOrderTraversal():
        check(i == key)
        i += 1
      check(i == 11)

    test "avl remove simple":
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

    test "avl remove rotation":
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

    test "avl remove double rotation":
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

    test "avl remove non leaf":
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

    test "avl remove nonexistant":
      var tree: AVLTree[int, char]
      tree.insert(1, 'a')
      tree.insert(5, 'b')
      check(tree.len() == 2)
      tree.remove(10)
      check(tree.len() == 2)

main()
