## Red-Black tree implementation.
## https://en.wikipedia.org/wiki/Red-black_tree

type
  Color = enum
    red, black
  Node[K, V] = ref object
    parent {.cursor.}: Node[K, V]
    left: Node[K, V]
    right: Node[K, V]
    key: K
    value: V
    color: Color
    count: int  # size of subtree rooted at this node
  RedBlackTree*[K, V] = ref object
    ## Object representing a red black tree
    root: Node[K, V]
    leaf: Node[K, V]
    size: int

proc updateCount[K, V](node: Node[K, V], leaf: Node[K, V]) {.inline.} =
  if not node.isNil and node != leaf:
    let leftCount = if node.left == leaf: 0 else: node.left.count
    let rightCount = if node.right == leaf: 0 else: node.right.count
    node.count = leftCount + 1 + rightCount

proc newNode[K, V](tree: RedBlackTree[K, V], parent: Node[K, V], key: K, value: V): Node[K, V] =
  return Node[K, V](parent: parent, left: tree.leaf, right: tree.leaf, key: key, value: value, color: Color.red, count: 1)

proc newRedBlackTree*[K, V](): RedBlackTree[K, V] =
  ## Construct a new Red-Black binary search tree
  # The sentinel leaf has nil left/right to avoid self-reference cycles with ARC.
  # Nodes' left/right point to tree.leaf, but leaf doesn't point to itself.
  let leaf = Node[K, V](color: Color.black)
  return RedBlackTree[K, V](leaf: leaf)

proc successor[K, V](tree: RedBlackTree[K, V], node: Node[K, V]): Node[K, V] =
  ## Returns the successor of the given node, or nil if one doesn't exist
  if node.right.isNil or node.right == tree.leaf:
    return nil
  var curr = node.right
  while curr.left != tree.leaf:
    curr = curr.left
  return curr

proc rotateLeft[K, V](tree: RedBlackTree[K, V], p: Node[K, V]) =
  ## Rotates a tree left around the given node.
  if p.isNil:
    return
  # Keep explicit owning references to prevent premature deallocation
  let parent = p  # Extra reference to p
  let right = parent.right
  let rightLeft = right.left
  let parentParent = parent.parent
  # right's left subtree becomes parent's right subtree
  parent.right = rightLeft
  if rightLeft != tree.leaf:
    rightLeft.parent = parent
  # right takes parent's position
  right.parent = parentParent
  # update grandparent's child pointer
  if parentParent.isNil:
    tree.root = right
  elif parentParent.left == parent:
    parentParent.left = right
  else:
    parentParent.right = right
  # parent becomes right's left child
  right.left = parent
  parent.parent = right
  # update counts
  updateCount(parent, tree.leaf)
  updateCount(right, tree.leaf)

proc rotateRight[K, V](tree: RedBlackTree[K, V], p: Node[K, V]) =
  ## Rotates a tree right around the given node.
  if p.isNil:
    return
  # Keep explicit owning references to prevent premature deallocation
  let parent = p  # Extra reference to p
  let left = parent.left
  let leftRight = left.right
  let parentParent = parent.parent
  # left's right subtree becomes parent's left subtree
  parent.left = leftRight
  if leftRight != tree.leaf:
    leftRight.parent = parent
  # left takes parent's position
  left.parent = parentParent
  # update grandparent's child pointer
  if parentParent.isNil:
    tree.root = left
  elif parentParent.right == parent:
    parentParent.right = left
  else:
    parentParent.left = left
  # parent becomes left's right child
  left.right = parent
  parent.parent = left
  # update counts
  updateCount(parent, tree.leaf)
  updateCount(left, tree.leaf)

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

proc updateCountsToRoot[K, V](tree: RedBlackTree[K, V], node: Node[K, V]) =
  ## Update counts from node up to root.
  var curr = node
  while not curr.isNil and curr != tree.leaf:
    updateCount(curr, tree.leaf)
    curr = curr.parent

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
  var path: seq[Node[K, V]]
  while curr != tree.leaf:
    path.add(curr)
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
        # Update counts along the path
        for n in path:
          n.count += 1
        tree.fixInsert(curr.left)
        return true
      curr = curr.left
    else:
      # Goes to the right
      if curr.right == tree.leaf:
        # Nothing there, insert here
        curr.right = newNode[K, V](tree, curr, key, value)
        tree.size += 1
        # Update counts along the path
        for n in path:
          n.count += 1
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

proc find*[K, V](tree: RedBlackTree[K, V], key: K; value: var V): bool =
  ## Find and copy the value associated with a given `key`. Returns true
  ## if the `key` was found and `value` was overwritten; else, false.
  let node = tree.findNode(key)
  result = not node.isNil
  if result:
    value = node.value

proc fixRemove[K, V](tree: RedBlackTree[K, V], node: Node[K, V]) =
  ## Rebalances a tree after a removal.
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
  var actualDeleted = node
  if node.left != tree.leaf and node.right != tree.leaf:
    # Internal node, the successor's data can be placed here without violating
    # bst properties. Now we need to delete the successor
    let succ = tree.successor(node)
    node.key = succ.key
    node.value = succ.value
    actualDeleted = succ
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

  # Update counts from deleted node's parent up to root
  tree.updateCountsToRoot(node.parent)

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

iterator keys*[K, V](tree: RedBlackTree[K, V]): K =
  ## Iterates over keys of the tree in order.
  var node = tree.root
  var stack: seq[Node[K, V]] = @[]
  while stack.len() != 0 or node != tree.leaf:
    if node != tree.leaf:
      stack.add(node)
      node = node.left
    else:
      node = stack.pop()
      yield node.key
      node = node.right

iterator values*[K, V](tree: RedBlackTree[K, V]): V =
  ## Iterates over values of the tree in order.
  var node = tree.root
  var stack: seq[Node[K, V]] = @[]
  while stack.len() != 0 or node != tree.leaf:
    if node != tree.leaf:
      stack.add(node)
      node = node.left
    else:
      node = stack.pop()
      yield node.value
      node = node.right

proc contains*[K, V](tree: RedBlackTree[K, V]; key: K): bool =
  ## Returns `true` if `key` exists in `tree`.
  not tree.findNode(key).isNil

proc minNode[K, V](tree: RedBlackTree[K, V]): Node[K, V] =
  result = tree.root
  if result.isNil or result == tree.leaf:
    return nil
  while result.left != tree.leaf:
    result = result.left

proc maxNode[K, V](tree: RedBlackTree[K, V]): Node[K, V] =
  result = tree.root
  if result.isNil or result == tree.leaf:
    return nil
  while result.right != tree.leaf:
    result = result.right

proc min*[K, V](tree: RedBlackTree[K, V]): (K, V) =
  ## Returns the smallest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  let node = tree.minNode
  if node.isNil:
    raise ValueError.newException "tree is empty"
  result = (node.key, node.value)

proc max*[K, V](tree: RedBlackTree[K, V]): (K, V) =
  ## Returns the largest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  let node = tree.maxNode
  if node.isNil:
    raise ValueError.newException "tree is empty"
  result = (node.key, node.value)

proc removeNode[K, V](tree: RedBlackTree[K, V], node: var Node[K, V]) =
  ## Internal: remove a specific node from the tree.
  tree.size -= 1
  var actualNode = node
  if node.left != tree.leaf and node.right != tree.leaf:
    let succ = tree.successor(node)
    node.key = succ.key
    node.value = succ.value
    actualNode = succ
    node = succ

  let child = if node.left != tree.leaf: node.left else: node.right
  child.parent = node.parent
  if node.parent.isNil:
    tree.root = child
  elif node == node.parent.left:
    node.parent.left = child
  else:
    node.parent.right = child

  tree.updateCountsToRoot(node.parent)

  if node.color == Color.black:
    tree.fixRemove(child)

proc popMin*[K, V](tree: RedBlackTree[K, V]): (K, V) {.discardable.} =
  ## Removes and returns the smallest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  var node = tree.minNode
  if node.isNil:
    raise ValueError.newException "tree is empty"
  result = (move node.key, move node.value)
  tree.removeNode(node)

proc popMax*[K, V](tree: RedBlackTree[K, V]): (K, V) {.discardable.} =
  ## Removes and returns the largest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  var node = tree.maxNode
  if node.isNil:
    raise ValueError.newException "tree is empty"
  result = (move node.key, move node.value)
  tree.removeNode(node)

proc `[]=`*[K, V](tree: RedBlackTree[K, V]; key: K; value: V) =
  ## Add `key` and `value` pair to `tree`.
  discard tree.insert(key, value)

proc `[]`*[K, V](tree: RedBlackTree[K, V]; key: K): var V =
  ## Recover value of `key` in `tree`.
  ## Raises KeyError if key is not found.
  let node = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  result = node.value

proc pop*[K, V](tree: RedBlackTree[K, V], key: K): V {.discardable.} =
  ## Remove `key` from `tree` and return its value.
  ## Raises KeyError if key is not found.
  var node = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  result = move node.value
  tree.removeNode(node)

proc selectNode[K, V](tree: RedBlackTree[K, V]; node: Node[K, V]; i: Natural): Node[K, V] =
  ## Returns the `i`'th smallest (0-indexed) child in `node`.
  if node.isNil or node == tree.leaf:
    raise IndexDefect.newException "index out of bounds"
  let leftCount = if node.left == tree.leaf: 0 else: node.left.count
  if i == leftCount:
    node
  elif i < leftCount:
    selectNode(tree, node.left, i)
  else:
    selectNode(tree, node.right, i - leftCount - 1)

proc select*[K, V](tree: RedBlackTree[K, V]; i: int): (K, V) =
  ## Returns the `i`'th smallest (0-indexed) item in `tree`.
  ## Negative indices count from the end (-1 = last).
  ## Raises IndexDefect if index is out of bounds.
  if tree.root.isNil or tree.root == tree.leaf:
    raise IndexDefect.newException "index out of bounds"
  var idx = i
  if idx < 0:
    idx = tree.size + idx
  if idx < 0 or idx >= tree.size:
    raise IndexDefect.newException "index out of bounds"
  let node = selectNode(tree, tree.root, idx)
  result = (node.key, node.value)

proc rankNode[K, V](tree: RedBlackTree[K, V]; root, node: Node[K, V]): Natural =
  ## Returns the 0-indexed position of `node` in `root`.
  var node = node
  let leftCount = if node.left == tree.leaf: 0 else: node.left.count
  result = leftCount
  while node != root:
    if node == node.parent.right:
      let parentLeftCount = if node.parent.left == tree.leaf: 0 else: node.parent.left.count
      result += parentLeftCount + 1
    node = node.parent

proc rank*[K, V](tree: RedBlackTree[K, V]; key: K): Natural =
  ## Returns the 0-indexed position of `key` in `tree`.
  ## Raises KeyError if key is not found.
  if tree.root.isNil or tree.root == tree.leaf:
    raise KeyError.newException "not found"
  let node = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  result = rankNode(tree, tree.root, node)
