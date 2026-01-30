## Implementation of a Red-Black tree in Nim, based on
## http://staff.ustc.edu.cn/~csli/graduate/algorithms/book6/chap14.htm.
## Recursive iterators aren't allowed in nim, so iterative tree traversals were
## needed, found on wikipedia.
##
## Elements are compared via the `cmp` function, so the `<` and `==` operators
## should be defined for the key type of the tree. Duplicate keys are not
## allowed in the tree.
##
## Red-Black trees are balanced binary search trees with the following worst
## case time complexities for common operations:
## space: O(n)
## insert: O(lg(n))
## remove: O(lg(n))
## find: O(lg(n))
## in-order iteration: O(n)
##
## A sentinel leaf node is used to simplify algorithms without taking up
## too much space.

type
  Color = enum
    red, black
  Node[K, V] = ref object
    parent: Node[K, V]
    left: Node[K, V]
    right: Node[K, V]
    key: K
    value: V
    color: Color
  RedBlackTree*[K, V] = ref object
    ## Object representing a red black tree
    root: Node[K, V]
    leaf: Node[K, V]
    size: int

proc newNode[K, V](tree: RedBlackTree[K, V], parent: Node[K, V], key: K, value: V): Node[K, V] =
  return Node[K, V](parent: parent, left: tree.leaf, right: tree.leaf, key: key, value: value, color: Color.red)

proc newRedBlackTree*[K, V](): RedBlackTree[K, V] =
  ## Construct a new Red-Black binary search tree
  let leaf = Node[K, V](color: Color.black)
  leaf.left = leaf
  leaf.right = leaf
  return RedBlackTree[K, V](leaf: leaf)

proc successor[K, V](tree: RedBlackTree[K, V], node: Node[K, V]): Node[K, V] =
  ## Returns the successor of the given node, or nil if one doesn't exist
  if node.right.isNil:
    return nil
  var curr = node.right
  while not curr.left.isNil:
    curr = curr.left
  return curr

proc rotateLeft[K, V](tree: RedBlackTree[K, V], parent: Node[K, V]) =
  ## Rotates a tree left around the given node
  if parent.isNil:
    return
  var right = parent.right
  parent.right = right.left
  if not right.left.isNil:
    right.left.parent = parent
  right.parent = parent.parent
  if parent.parent.isNil:
    tree.root = right
  elif parent.parent.left == parent:
    parent.parent.left = right
  else:
    parent.parent.right = right
  right.left = parent
  parent.parent = right

proc rotateRight[K, V](tree: RedBlackTree[K, V], parent: Node[K, V]) =
  ## Rotates a tree right around the given node
  if parent.isNil:
    return
  var left = parent.left
  parent.left = left.right
  if not left.right.isNil:
    left.right.parent = parent
  left.parent = parent.parent
  if parent.parent.isNil:
    tree.root = left
  elif parent.parent.right == parent:
    parent.parent.right = left
  else:
    parent.parent.left = left
  left.right = parent
  parent.parent = left

proc findNode[K, V](tree: RedBlackTree[K, V], key: K): Node[K, V] =
  ## Finds a node with the given key, or nil if it doesn't exist
  var curr = tree.root
  while curr != tree.leaf:
    let comp = cmp(key, curr.key)
    if comp == 0:
      return curr
    elif comp < 0:
      curr = curr.left
    else:
      curr = curr.right
  return nil

proc fixInsert[K, V](tree: RedBlackTree[K, V], node: Node[K, V]) =
  ## Rebalances a tree after an insertion
  var curr = node
  while curr != tree.root and curr.parent.color == Color.red:
    if not curr.parent.parent.isNil and curr.parent == curr.parent.parent.left:
      var uncle = curr.parent.parent.right
      if uncle.color == Color.red:
        curr.parent.color = Color.black
        uncle.color = Color.black
        curr.parent.parent.color = Color.red
        curr = curr.parent.parent
      else:
        if curr == curr.parent.right:
          curr = curr.parent
          tree.rotateLeft(curr)
        curr.parent.color = Color.black
        if not curr.parent.parent.isNil:
          curr.parent.parent.color = Color.red
          tree.rotateRight(curr.parent.parent)
    elif not curr.parent.parent.isNil:
      var uncle = curr.parent.parent.left
      if uncle.color == Color.red:
        curr.parent.color = Color.black
        uncle.color = Color.black
        curr.parent.parent.color = Color.red
        curr = curr.parent.parent
      else:
        if curr == curr.parent.left:
          curr = curr.parent
          tree.rotateRight(curr)
        curr.parent.color = Color.black
        if not curr.parent.parent.isNil:
          curr.parent.parent.color = Color.red
          tree.rotateLeft(curr.parent.parent)
  tree.root.color = Color.black

proc insert*[K, V](tree: RedBlackTree[K, V], key: K, value: V): bool {.discardable.} =
  ## Insert a key value pair into the tree. Returns true if the key didn't
  ## already exist in the tree. If the key already existed, the old value
  ## is updated and false is returned.
  # If the tree root is nil, there are no entries, put it at the root
  if tree.root.isNil:
    tree.root = newNode[K, V](tree, nil, key, value)
    tree.size += 1
    tree.fixInsert(tree.root)
    return true

  # Otherwise find the insertion point
  var curr = tree.root
  while curr != tree.leaf:
    let comp = cmp(key, curr.key)
    if comp == 0:
      # If it's already there, set the data and return
      curr.value = value
      return false
    elif comp < 0:
      # Goes to the left
      if curr.left == tree.leaf:
        # Nothing there, insert here
        curr.left = newNode[K, V](tree, curr, key, value)
        tree.size += 1
        tree.fixInsert(curr.left)
        return true
      curr = curr.left
    else:
      # Goes to the right
      if curr.right == tree.leaf:
        # Nothing there, insert here
        curr.right = newNode[K, V](tree, curr, key, value)
        tree.size += 1
        tree.fixInsert(curr.right)
        return true
      curr = curr.right
  return false

proc find*[K, V](tree: RedBlackTree[K, V], key: K): (V, bool) =
  ## Find the value associated with a given key. Returns the value and true
  ## if the key was found, and a default value and false if not.
  let node = tree.findNode(key)
  if not node.isNil:
    return (node.value, true)
  var default: V
  return (default, false)

proc fixRemove[K, V](tree: RedBlackTree[K, V], node: Node[K, V]) =
  ## Rebalaces a tree after a removal
  var curr = node
  while curr != tree.root and curr.color == Color.black:
    if curr == curr.parent.left:
      var sib = curr.parent.right
      if sib.color == Color.red:
        sib.color = Color.black
        curr.parent.color = Color.red
        tree.rotateLeft(curr.parent)
        sib = curr.parent.right

      if sib.left.color == Color.black and sib.right.color == Color.black:
        sib.color = Color.red
        curr = curr.parent
      else:
        if sib.right.color == Color.black:
          sib.left.color = Color.black
          sib.color = Color.red
          tree.rotateRight(sib)
          sib = curr.parent.right
        sib.color = curr.parent.color
        curr.parent.color = Color.black
        sib.right.color = Color.black
        tree.rotateLeft(curr.parent)
        curr = tree.root
    else:
      var sib = curr.parent.left
      if sib.color == Color.red:
        sib.color = Color.black
        curr.parent.color = Color.red
        tree.rotateRight(curr.parent)
        sib = curr.parent.left

      if sib.right.color == Color.black and sib.left.color == Color.black:
        sib.color = Color.red
        curr = curr.parent
      else:
        if sib.left.color == Color.black:
          sib.right.color = Color.black
          sib.color = Color.red
          tree.rotateLeft(sib)
          sib = curr.parent.left
        sib.color = curr.parent.color
        curr.parent.color = Color.black
        sib.left.color = Color.black
        tree.rotateRight(curr.parent)
        curr = tree.root
  curr.color = Color.black


proc remove*[K, V](tree: RedBlackTree[K, V], key: K): bool {.discardable.} =
  ## Remove a key value pair from the tree. Returns true if something was
  ## removed, false if the key wasn't found, so nothing was removed.
  var node = tree.findNode(key)
  if node.isNil:
    return false

  tree.size -= 1
  # Reduce the problem to removing a node with at most one child
  if node.left != tree.leaf and node.right != tree.leaf:
    # Internal node, the successor's data can be placed here without violating
    # bst properties. Now we need to delete the successor
    let succ = tree.successor(node)
    node.key = succ.key
    node.value = succ.value
    node = succ

  # Get a non leaf child, if there is one and fix pointers
  let child = if node.left != tree.leaf: node.left else: node.right
  child.parent = node.parent
  if node.parent.isNil:
    tree.root = child
  elif node == node.parent.left:
    node.parent.left = child
  else:
    node.parent.right = child
  # We only need to fix the red-black ness of the tree if the removed node
  # was black, as removing a red node doesn't violate the same length
  # black path property
  if node.color == Color.black:
    tree.fixRemove(child)
  return true

proc len*[K, V](tree: RedBlackTree[K, V]): int =
  ## Returns the number of items the in tree
  return tree.size

iterator pairs*[K, V](tree: RedBlackTree[K, V]): (K, V) =
  ## Iterates over the elements of the tree in order.
  var node = tree.root
  var stack: seq[Node[K, V]] = @[]
  while stack.len() != 0 or node != tree.leaf:
    if node != tree.leaf:
      stack.add(node)
      node = node.left
    else:
      node = stack.pop()
      yield (node.key, node.value)
      node = node.right

iterator iterOrder*[K, V](tree: RedBlackTree[K, V]): (K, V) {.deprecated: "use pairs instead".} =
  ## Iterates over the elements of the tree in order.
  ## Deprecated: use `pairs` instead for API consistency.
  for k, v in tree.pairs:
    yield (k, v)
