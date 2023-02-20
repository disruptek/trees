## Implementation of an AVL tree in Nim, based on
## https://en.wikipedia.org/wiki/AVL_tree.
## Recursive iterators aren't allowed in nim, so iterative tree traversals were
## needed, found on wikipedia as well.
##
## Elements are compared via the `cmp` function, so the `<` and `==` operators
## should be defined for the key type of the tree. Duplicate keys are not
## allowed in the tree.
##
## AVL trees are balanced binary search trees with the following worst case time
## complexities for common operations:
## space: O(n)
## insert: O(lg(n))
## remove: O(lg(n))
## find: O(lg(n))
## in-order iteration: O(n)

type
  Node[K, V] = ref object
    parent {.cursor.}: Node[K, V]
    left: Node[K, V]
    right: Node[K, V]
    key: K
    value: V
    balance: int

  AVLTree*[K, V] = object
    ## Object representing an AVL tree
    root: Node[K, V]
    size: int

template newNode[K, V](parant: Node[K, V]; k: K; v: V): Node[K, V] =
  Node[K, V](parent: parant, key: k, value: v)

proc successor[K, V](tree: AVLTree[K, V], node: Node[K, V]): Node[K, V] =
  ## Returns the successor of the given node, or nil if one doesn't exist.
  if not node.right.isNil:
    result = node.right
    while not result.right.isNil:
      result = result.right

proc rotateLeft[K, V](tree: var AVLTree[K, V], parent: Node[K, V]) =
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

proc rotateRight[K, V](tree: var AVLTree[K, V], parent: Node[K, V]) =
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

proc findNode[K, V](tree: AVLTree[K, V], key: K): Node[K, V] =
  ## Finds a node with the given key, or nil if it doesn't exist.
  result = tree.root
  while not result.isNil:
    let comp = cmp(key, result.key)
    if comp == 0:
      break
    elif comp < 0:
      result = result.left
    else:
      result = result.right

proc fixInsert[K, V](tree: var AVLTree[K, V]; node: Node[K, V]) =
  ## Rebalances a tree after an insertion.
  var curr = node
  var parent = curr.parent
  while not parent.isNil:
    # Worst case scenario we have to go to the root
    if curr == parent.left:
      # Left child, deal with those rotations
      if parent.balance == 1:
        # Old balance factor was 1, and we increased the height of the left
        # subtree, so now it's 2, rebalance needed
        if curr.balance == -1:
          # left right case, reduce to left left case
          tree.rotateLeft(curr)
        # Has to be left left case now
        tree.rotateRight(parent)
        return
      elif parent.balance == -1:
        # Increasing the height of the left subtree balanced this
        parent.balance = 0
        return
      # The old balance has to be 0 at this point, tree could need rebalancing
      # farther up
      parent.balance = 1
    else:
      # Right child, mirror of above case
      if parent.balance == -1:
        # Old balance factor was -1, and we increased the height of the right
        # subtree, so now it's -2, rebalance needed
        if curr.balance == 1:
          # right left case, reduce to right right case
          tree.rotateRight(curr)
        # Has to be right right case now
        tree.rotateLeft(parent)
        return
      elif parent.balance == 1:
        # Increasing the height of the right subtree balanced this
        parent.balance = 0
        return
      # The old balance has to be 0 at this point, tree could need rebalancing
      # farther up
      parent.balance = -1
    curr = parent
    parent = curr.parent

proc insert*[K, V](tree: var AVLTree[K, V], key: K, value: V): bool {.discardable.} =
  ## Insert a key value pair into the tree. Returns true if the key didn't
  ## already exist in the tree. If the key already existed, the old value
  ## is updated and false is returned.
  if tree.root.isNil:
    tree.root = newNode[K, V](nil, key, value)
    tree.size += 1
    return true

  var curr = tree.root
  while not curr.isNil:
    let comp = cmp(key, curr.key)
    if comp == 0:
      # If it's already there, set the data and return
      curr.value = value
      return false
    elif comp < 0:
      # Go to the left
      if curr.left.isNil:
        # It's not there, insert and fix tree
        curr.left = newNode[K, V](curr, key, value)
        tree.size += 1
        tree.fixInsert(curr.left)
        return true
      curr = curr.left
    else:
      # Go to the right
      if curr.right.isNil:
        # It's not there, insert and fix tree
        curr.right = newNode[K, V](curr, key, value)
        tree.size += 1
        tree.fixInsert(curr.right)
        return true
      curr = curr.right
  return false

proc find*[K, V](tree: AVLTree[K, V], key: K): (V, bool) =
  ## Find the value associated with a given key. Returns the value and true
  ## if the key was found, and a default value and false if not.
  let node = tree.findNode(key)
  if not node.isNil:
    return (node.value, true)
  var default: V
  return (default, false)

proc fixRemove[K, V](tree: var AVLTree[K, V], node: Node[K, V]) =
  ## Rebalaces a tree after a removal
  if node.isNil:
    return
  var curr = node
  var parent = node.parent
  while not parent.isNil:
    # Worst case scenario we have to go to the root
    if curr == parent.right:
      # Right child was removed, deal with those rotations
      if parent.balance == 1:
        # Old balance factor was 1, and we decreased the height of the right
        # subtree, so now it's 2, rebalance needed
        let sib = parent.left
        let sibBalance = if not sib.isNil: sib.balance else: 0
        if sibBalance == -1:
          # left right case, reduce to left left case
          tree.rotateLeft(sib)
        # Has to be left left case now
        tree.rotateRight(parent)
        if sibBalance == 0:
          return
      elif parent.balance == 0:
        # Decreasing the height of the right subtree balanced this
        parent.balance = 1
        return
      parent.balance = 0
    else:
      # Left child was removed, mirror of above case
      if parent.balance == -1:
        # Old balance factor was -1, and we decreased the height of the left
        # subtree, now now it's -2, rebalance needed
        let sib = parent.right
        let sibBalance = if not sib.isNil: sib.balance else: 0
        if sibBalance == 1:
          # right left case, reduce to right right case
          tree.rotateRight(sib)
        # Has to be right right case now
        tree.rotateLeft(parent)
        if sibBalance == 0:
          # Decreasing the height of the left subtree balanced this
          return
      elif parent.balance == 0:
        # Decreasing the height of the left subtree balanced this
        parent.balance = -1
        return
      parent.balance = 0
    curr = parent
    parent = curr.parent

proc remove*[K, V](tree: var AVLTree[K, V], key: K): bool {.discardable.} =
  ## Remove a key value pair from the tree. Returns true if something was
  ## removed, false if the key wasn't found, so nothing was removed.
  var node = tree.findNode(key)
  # If a node with that data doesn't exist, nothing to do
  if node.isNil:
    return false

  tree.size -= 1
  if not node.left.isNil and not node.right.isNil:
    # Internal node; the successor's data can be placed here without violating
    # BST properties. Now we need to delete the successor
    let succ = tree.successor(node)
    node.key = succ.key
    node.value = succ.value
    node = succ

  # Now the node we are trying to delete has at most one child
  let child = if not node.left.isNil: node.left else: node.right
  if not child.isNil:
    # Set parent if it exists
    child.parent = node.parent
  if node.parent.isNil:
    # Node was the root, reset it
    tree.root = child
  # If the parent exists, we need to set the child appropriately
  elif node == node.parent.left:
    node.parent.left = child
  else:
    node.parent.right = child
  tree.fixRemove(child)
  result = true

proc len*[K, V](tree: AVLTree[K, V]): int =
  ## Returns the number of items in the tree.
  tree.size

iterator inOrderTraversal*[K, V](tree: AVLTree[K, V]): (K, V) =
  ## Iterates over the elements of the tree in-order.
  var node = tree.root
  var stack: seq[Node[K, V]]
  while stack.len > 0 or not node.isNil:
    if node.isNil:
      node = stack.pop()
      yield (node.key, node.value)
      node = node.right
    else:
      stack.add(node)
      node = node.left
