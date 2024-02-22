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

  AVLTree*[K, V] {.byref.} = object
    ## Object representing an AVL tree
    root: Node[K, V]
    size: int

  AVLKeyVal[K, V] = tuple[key: K; val: V]

template newNode[K, V](parant: Node[K, V]; k: K; v: V): Node[K, V] =
  Node[K, V](parent: parant, key: k, value: v)

proc min(node: Node): Node =
  result = node
  while not result.left.isNil:
    result = result.left

proc max(node: Node): Node =
  result = node
  while not result.right.isNil:
    result = result.right

proc max*[K, V](tree: AVLTree[K, V]): AVLKeyVal[K, V] =
  if tree.size == 0:
    raise ValueError.newException "tree is empty"
  else:
    let node = max(tree.root)
    result = (node.key, node.value)

proc min*[K, V](tree: AVLTree[K, V]): AVLKeyVal[K, V] =
  if tree.size == 0:
    raise ValueError.newException "tree is empty"
  else:
    let node = min(tree.root)
    result = (node.key, node.value)

proc succ[K, V](tree: AVLTree[K, V], node: Node[K, V]): Node[K, V] {.used.} =
  ## Returns the successor of the given node, or nil if one doesn't exist.
  if not node.right.isNil:
    result = min(node.right)
  else:
    var node = node
    result = node.parent
    while not result.isNil and node == result.right:
      node = result
      result = result.parent

proc pred[K, V](tree: AVLTree[K, V], node: Node[K, V]): Node[K, V] {.used.} =
  if not node.left.isNil:
    result = max(node.left)
  else:
    var node = node
    result = node.parent
    while not result.isNil and node == result.left:
      node = result
      result = result.parent

proc rotateLeft[K, V](tree: var AVLTree[K, V], parent: Node[K, V]) =
  ## Rotates a tree left around the given node
  if parent.isNil or parent.right.isNil:
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
  if parent.isNil or parent.left.isNil:
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

proc count[K, V](node: Node[K, V]): Natural =
  ## Count the number of nodes in subtree `node`.
  if node.isNil:
    0.Natural
  else:
    1.Natural + node.left.count + node.right.count

proc findNode[K, V](tree: AVLTree[K, V], key: K): Node[K, V] =
  ## Finds a node with the given key, or nil if it doesn't exist.
  result = tree.root
  while not result.isNil and result.key != key:
    if key < result.key:
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
      case parent.balance
      of 1:
        # Old balance factor was 1, and we increased the height of the left
        # subtree, so now it's 2, rebalance needed
        if curr.balance == -1:
          # left right case, reduce to left left case
          tree.rotateLeft(curr)
        # Has to be left left case now
        tree.rotateRight(parent)
        break
      of -1:
        # Increasing the height of the left subtree balanced this
        parent.balance = 0
        break
      else:
        # The old balance has to be 0 at this point, tree could need
        # rebalancing farther up
        parent.balance = 1
    else:
      # Right child, mirror of above case
      case parent.balance
      of -1:
        # Old balance factor was -1, and we increased the height of the right
        # subtree, so now it's -2, rebalance needed
        if curr.balance == 1:
          # right left case, reduce to right right case
          tree.rotateRight(curr)
        # Has to be right right case now
        tree.rotateLeft(parent)
        break
      of 1:
        # Increasing the height of the right subtree balanced this
        parent.balance = 0
        break
      else:
        # The old balance has to be 0 at this point, tree could need
        # rebalancing farther up
        parent.balance = -1
    curr = parent
    parent = curr.parent

proc insert*[K, V](tree: var AVLTree[K, V], key: K, value: V): bool {.discardable.} =
  ## Insert a key/value pair into the tree. Returns true if the key didn't
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
    result = (node.value, true)

proc find*[K, V](tree: AVLTree[K, V], key: K; value: var V): bool =
  ## Find and copy the value associated with a given `key`. Returns true
  ## if the `key` was found and `value` was overwritten; else, false.
  let node = tree.findNode(key)
  result = not node.isNil
  if result:
    value = node.value

proc contains*[K, V](tree: AVLTree[K, V]; key: K): bool =
  ## Returns `true` if `key` exists in `tree`.
  not tree.findNode(key).isNil

proc `[]=`*[K, V](tree: var AVLTree[K, V]; key: K; value: V) =
  ## Add `key` and `value` pair to `tree`.
  discard tree.insert(key, value)

proc `[]`*[K, V](tree: AVLTree[K, V]; key: K): var V =
  ## Recover value of `key` in `tree`.
  let node = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  else:
    result = node.value

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
      case parent.balance
      of 1:
        # Old balance factor was 1, and we decreased the height of the right
        # subtree, so now it's 2, rebalance needed
        let sib = parent.left
        let sibBalance = if sib.isNil: 0 else: sib.balance
        if sibBalance == -1:
          # left right case, reduce to left left case
          tree.rotateLeft(sib)
        # Has to be left left case now
        tree.rotateRight(parent)
        if sibBalance == 0:
          break
      of 0:
        # Decreasing the height of the right subtree balanced this
        parent.balance = 1
        break
      else:
        parent.balance = 0
    else:
      # Left child was removed, mirror of above case
      case parent.balance
      of -1:
        # Old balance factor was -1, and we decreased the height of the left
        # subtree, now now it's -2, rebalance needed
        let sib = parent.right
        let sibBalance = if sib.isNil: 0 else: sib.balance
        if sibBalance == 1:
          # right left case, reduce to right right case
          tree.rotateRight(sib)
        # Has to be right right case now
        tree.rotateLeft(parent)
        if sibBalance == 0:
          # Decreasing the height of the left subtree balanced this
          break
      of 0:
        # Decreasing the height of the left subtree balanced this
        parent.balance = -1
        break
      else:
        parent.balance = 0
    curr = parent
    parent = curr.parent

proc remove(tree: var AVLTree; node: var Node) =
  ## Remove `node` from `tree`.
  tree.size -= 1
  if not node.left.isNil and not node.right.isNil:
    # Internal node; the successor's data can be placed here without violating
    # BST properties. Now we need to delete the successor
    let next = tree.succ(node)
    node.key = next.key
    node.value = next.value
    node = next

  # Now the node we are trying to delete has at most one child
  let child = if node.left.isNil: node.right else: node.left
  if not node.left.isNil:
    assert node.right.isNil
  if not node.right.isNil:
    assert node.left.isNil
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

proc remove*[K, V](tree: var AVLTree[K, V], key: K): bool {.discardable.} =
  ## Remove a key/value pair from the tree. Returns true if something was
  ## removed, false if the key wasn't found, so nothing was removed.
  var node = tree.findNode(key)
  # If a node with that data doesn't exist, nothing to do
  result = not node.isNil
  if result:
    remove(tree, node)

proc del*[K, V](tree: var AVLTree[K, V], key: K) =
  discard remove(tree, key)

proc pop*[K, V](tree: var AVLTree[K, V], key: K): V {.discardable.} =
  ## Remove `key` from `tree` and return its value.
  var node = tree.findNode(key)
  # If a node with that data doesn't exist, nothing to do
  if node.isNil:
    raise KeyError.newException "not found"
  else:
    result = move node.value
    remove(tree, node)

proc len*[K, V](tree: AVLTree[K, V]): int =
  ## Returns the number of items in the tree.
  tree.size

iterator pairs*[K, V](tree: AVLTree[K, V]): tuple[key: K; val: V] =
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

iterator keys*[K, V](tree: AVLTree[K, V]): K =
  ## Iterates over the elements of the tree in-order.
  var node = tree.root
  var stack: seq[Node[K, V]]
  while stack.len > 0 or not node.isNil:
    if node.isNil:
      node = stack.pop()
      yield node.key
      node = node.right
    else:
      stack.add(node)
      node = node.left

iterator values*[K, V](tree: AVLTree[K, V]): V =
  ## Iterates over the elements of the tree in-order.
  var node = tree.root
  var stack: seq[Node[K, V]]
  while stack.len > 0 or not node.isNil:
    if node.isNil:
      node = stack.pop()
      yield node.value
      node = node.right
    else:
      stack.add(node)
      node = node.left

proc select[K, V](node: Node[K, V]; i: Positive): Node[K, V] =
  ## Returns the `i`'th smallest (one-indexed) child in `node`.
  if node.isNil:
    raise IndexDefect.newException "bogus tree"
  else:
    let r = node.left.count + 1
    if i == r:
      node
    elif i < r:
      select(node.left, i)
    else:
      select(node.right, i - r)

proc select*[K, V](tree: AVLTree[K, V]; i: Positive): AVLKeyVal[K, V] =
  ## Returns the `i`'th smallest (one-indexed) item in `tree`.
  if tree.root.isNil:
    raise ValueError.newException "tree is empty"
  elif tree.size < i:
    raise IndexDefect.newException "bogus index"
  else:
    var node = select(tree.root, i)
    result = (node.key, node.value)

proc rank[K, V](root: Node[K, V]; node: Node[K, V]): Positive =
  ## Returns the position of `node` (one-indexed) in `root`.
  var node = node
  result = node.left.count + 1
  while node != root:
    if node == node.parent.right:
      result += node.parent.left.count + 1
    node = node.parent

proc rank[K, V](tree: AVLTree[K, V]; node: Node[K, V]): Positive =
  ## Returns the position of `node` (one-indexed) in `tree`.
  if tree.root.isNil:
    raise ValueError.newException "tree is empty"
  elif node.isNil:
    raise ValueError.newException "node is nil"
  else:
    result = rank(tree.root, node)

proc rank*[K, V](tree: AVLTree[K, V]; key: K): Positive =
  ## Returns the position of `node` (one-indexed) in `tree`.
  if tree.root.isNil:
    raise ValueError.newException "tree is empty"
  else:
    var node = tree.findNode(key)
    if node.isNil:
      raise KeyError.newException "not found"
    else:
      result = rank(tree.root, node)

proc popMin*[K, V](tree: var AVLTree[K, V]): AVLKeyVal[K, V] {.discardable.} =
  ## Removes and returns the smallest key/value pair in `tree`.
  if tree.root.isNil or tree.size == 0:
    raise ValueError.newException "tree is empty"
  else:
    var node = min(tree.root)
    result.key = move node.key
    result.val = move node.value
    remove(tree, node)

proc popMax*[K, V](tree: var AVLTree[K, V]): AVLKeyVal[K, V] {.discardable.} =
  ## Removes and returns the largest key/value pair in `tree`.
  if tree.root.isNil or tree.size == 0:
    raise ValueError.newException "tree is empty"
  else:
    var node = max(tree.root)
    result.key = move node.key
    result.val = move node.value
    remove(tree, node)
