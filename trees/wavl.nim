## WAVL (Weak AVL) tree implementation.
## https://en.wikipedia.org/wiki/WAVL_tree
##
## WAVL trees use rank differences instead of balance factors.
## Key properties:
## - At most 2 rotations per insert/delete (vs O(log n) for AVL delete)
## - Without deletions, equivalent to AVL trees
## - All WAVL trees are valid red-black trees

type
  Node[K, V] = ref object
    parent {.cursor.}: Node[K, V]
    left: Node[K, V]
    right: Node[K, V]
    key: K
    value: V
    rank: int  # WAVL rank (leaves have rank 0)
    count: int  # size of subtree rooted at this node

  WAVLTree*[K, V] {.byref.} = object
    ## Object representing a WAVL tree
    root: Node[K, V]
    size: int

proc newWAVLTree*[K, V](): WAVLTree[K, V] =
  ## Construct a new WAVL tree.
  discard

proc nodeCount[K, V](node: Node[K, V]): int {.inline.} =
  if node.isNil: 0 else: node.count

proc updateCount[K, V](node: Node[K, V]) {.inline.} =
  if not node.isNil:
    node.count = node.left.nodeCount + 1 + node.right.nodeCount

proc nodeRank[K, V](node: Node[K, V]): int {.inline.} =
  ## Returns -1 for nil (external nodes), else the node's rank.
  if node.isNil: -1 else: node.rank

proc rankDiff[K, V](parent, child: Node[K, V]): int {.inline.} =
  ## Returns the rank difference between parent and child.
  parent.nodeRank - child.nodeRank

proc isLeaf[K, V](node: Node[K, V]): bool {.inline.} =
  node.left.isNil and node.right.isNil

proc min(node: Node): Node =
  result = node
  while not result.left.isNil:
    result = result.left

proc max(node: Node): Node =
  result = node
  while not result.right.isNil:
    result = result.right

proc min*[K, V](tree: WAVLTree[K, V]): (K, V) =
  ## Returns the smallest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  if tree.size == 0:
    raise ValueError.newException "tree is empty"
  let node = min(tree.root)
  result = (node.key, node.value)

proc max*[K, V](tree: WAVLTree[K, V]): (K, V) =
  ## Returns the largest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  if tree.size == 0:
    raise ValueError.newException "tree is empty"
  let node = max(tree.root)
  result = (node.key, node.value)

proc rotateLeft[K, V](tree: var WAVLTree[K, V], node: Node[K, V]) =
  ## Rotates tree left around the given node.
  if node.isNil or node.right.isNil:
    return
  var right = node.right
  # right takes node's position
  right.parent = node.parent
  # right's left subtree becomes node's right subtree
  node.right = right.left
  if not right.left.isNil:
    right.left.parent = node
  # update grandparent's child pointer
  if node.parent.isNil:
    tree.root = right
  elif node.parent.left == node:
    node.parent.left = right
  else:
    node.parent.right = right
  # node becomes right's left child
  right.left = node
  node.parent = right
  # update counts
  updateCount(node)
  updateCount(right)

proc rotateRight[K, V](tree: var WAVLTree[K, V], node: Node[K, V]) =
  ## Rotates tree right around the given node.
  if node.isNil or node.left.isNil:
    return
  var left = node.left
  # left takes node's position
  left.parent = node.parent
  # left's right subtree becomes node's left subtree
  node.left = left.right
  if not left.right.isNil:
    left.right.parent = node
  # update grandparent's child pointer
  if node.parent.isNil:
    tree.root = left
  elif node.parent.right == node:
    node.parent.right = left
  else:
    node.parent.left = left
  # node becomes left's right child
  left.right = node
  node.parent = left
  # update counts
  updateCount(node)
  updateCount(left)

proc findNode[K, V](tree: WAVLTree[K, V], key: K): Node[K, V] =
  ## Finds a node with the given key, or nil if it doesn't exist.
  result = tree.root
  while not result.isNil and result.key != key:
    if key < result.key:
      result = result.left
    else:
      result = result.right

proc fixInsert[K, V](tree: var WAVLTree[K, V]; node: Node[K, V]) =
  ## Rebalances tree after insertion using WAVL rules.
  var curr = node
  while not curr.parent.isNil:
    let parent = curr.parent
    let leftDiff = rankDiff(parent, parent.left)
    let rightDiff = rankDiff(parent, parent.right)

    # Check if parent is a 0,1 or 1,0 node (valid after promote)
    if (leftDiff == 1 and rightDiff == 1) or
       (leftDiff == 1 and rightDiff == 2) or
       (leftDiff == 2 and rightDiff == 1):
      break  # Tree is balanced

    # Parent is 0,1 or 1,0 - need to promote or rotate
    if leftDiff == 0 and rightDiff == 1:
      # Promote parent
      parent.rank += 1
      curr = parent
    elif leftDiff == 1 and rightDiff == 0:
      # Promote parent
      parent.rank += 1
      curr = parent
    elif leftDiff == 0 and rightDiff == 2:
      # Left child was inserted, check for rotation
      let left = parent.left
      let leftLeftDiff = rankDiff(left, left.left)
      let leftRightDiff = rankDiff(left, left.right)
      if leftLeftDiff == 1 and leftRightDiff == 2:
        # Single right rotation
        tree.rotateRight(parent)
        parent.rank -= 1
      else:
        # Double rotation (left-right)
        tree.rotateLeft(left)
        tree.rotateRight(parent)
        left.rank -= 1
        parent.rank -= 1
        parent.parent.rank += 1
      break
    elif leftDiff == 2 and rightDiff == 0:
      # Right child was inserted, check for rotation
      let right = parent.right
      let rightLeftDiff = rankDiff(right, right.left)
      let rightRightDiff = rankDiff(right, right.right)
      if rightRightDiff == 1 and rightLeftDiff == 2:
        # Single left rotation
        tree.rotateLeft(parent)
        parent.rank -= 1
      else:
        # Double rotation (right-left)
        tree.rotateRight(right)
        tree.rotateLeft(parent)
        right.rank -= 1
        parent.rank -= 1
        parent.parent.rank += 1
      break
    else:
      break

proc insert*[K, V](tree: var WAVLTree[K, V], key: sink K, value: sink V): bool {.discardable.} =
  ## Insert a key/value pair into the tree. Returns true if the key didn't
  ## already exist in the tree. If the key already existed, the old value
  ## is updated and false is returned.
  if tree.root.isNil:
    tree.root = Node[K, V](key: key, value: value, rank: 0, count: 1)
    tree.size = 1
    return true

  var curr = tree.root
  var path: seq[Node[K, V]]
  while not curr.isNil:
    path.add(curr)
    let comp = cmp(key, curr.key)
    if comp == 0:
      curr.value = value
      return false
    elif comp < 0:
      if curr.left.isNil:
        curr.left = Node[K, V](parent: curr, key: key, value: value, rank: 0, count: 1)
        tree.size += 1
        for n in path:
          n.count += 1
        tree.fixInsert(curr.left)
        return true
      curr = curr.left
    else:
      if curr.right.isNil:
        curr.right = Node[K, V](parent: curr, key: key, value: value, rank: 0, count: 1)
        tree.size += 1
        for n in path:
          n.count += 1
        tree.fixInsert(curr.right)
        return true
      curr = curr.right
  return false

proc find*[K, V](tree: WAVLTree[K, V], key: K): (V, bool) =
  ## Find the value associated with a given key. Returns the value and true
  ## if the key was found, and a default value and false if not.
  let node = tree.findNode(key)
  if not node.isNil:
    result = (node.value, true)

proc find*[K, V](tree: WAVLTree[K, V], key: K; value: var V): bool =
  ## Find and copy the value associated with a given `key`. Returns true
  ## if the `key` was found and `value` was overwritten; else, false.
  let node = tree.findNode(key)
  result = not node.isNil
  if result:
    value = node.value

proc contains*[K, V](tree: WAVLTree[K, V]; key: K): bool =
  ## Returns `true` if `key` exists in `tree`.
  not tree.findNode(key).isNil

proc `[]=`*[K, V](tree: var WAVLTree[K, V]; key: K; value: V) =
  ## Add `key` and `value` pair to `tree`.
  discard tree.insert(key, value)

proc `[]`*[K, V](tree: WAVLTree[K, V]; key: K): var V =
  ## Recover value of `key` in `tree`.
  ## Raises KeyError if key is not found.
  let node = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  result = node.value

proc updateCountsToRoot[K, V](node: Node[K, V]) =
  ## Update counts from node up to root.
  var curr = node
  while not curr.isNil:
    updateCount(curr)
    curr = curr.parent

proc fixRemove[K, V](tree: var WAVLTree[K, V], node: Node[K, V]) =
  ## Rebalances tree after removal using WAVL rules.
  if node.isNil:
    return
  var curr = node
  while not curr.parent.isNil:
    let parent = curr.parent
    let leftDiff = rankDiff(parent, parent.left)
    let rightDiff = rankDiff(parent, parent.right)

    # Check if we need to fix (3-child or 2,2-leaf)
    if leftDiff <= 2 and rightDiff <= 2:
      # Check for 2,2-leaf case
      if parent.isLeaf and parent.rank > 0:
        parent.rank = 0
        curr = parent
        continue
      break

    if leftDiff == 3:
      # Left child was deleted or demoted
      let sib = parent.right
      if sib.isNil:
        # Shouldn't happen in valid WAVL; demote and continue
        parent.rank -= 1
        curr = parent
        continue
      let sibLeftDiff = rankDiff(sib, sib.left)
      let sibRightDiff = rankDiff(sib, sib.right)

      if sibLeftDiff == 2 and sibRightDiff == 2:
        # Demote both parent and sibling
        parent.rank -= 1
        sib.rank -= 1
        curr = parent
      elif sibRightDiff == 1:
        # Single rotation left
        tree.rotateLeft(parent)
        sib.rank += 1
        parent.rank -= 1
        if sibLeftDiff == 1:
          parent.rank -= 1
        break
      elif sibLeftDiff == 1 and not sib.left.isNil:
        # Double rotation (right-left)
        let sibLeft = sib.left
        tree.rotateRight(sib)
        tree.rotateLeft(parent)
        sibLeft.rank += 2
        sib.rank -= 1
        parent.rank -= 2
        break
      else:
        # Fallback: demote and continue
        parent.rank -= 1
        if sib.rank > 0:
          sib.rank -= 1
        curr = parent
    elif rightDiff == 3:
      # Right child was deleted or demoted
      let sib = parent.left
      if sib.isNil:
        # Shouldn't happen in valid WAVL; demote and continue
        parent.rank -= 1
        curr = parent
        continue
      let sibLeftDiff = rankDiff(sib, sib.left)
      let sibRightDiff = rankDiff(sib, sib.right)

      if sibLeftDiff == 2 and sibRightDiff == 2:
        # Demote both parent and sibling
        parent.rank -= 1
        sib.rank -= 1
        curr = parent
      elif sibLeftDiff == 1:
        # Single rotation right
        tree.rotateRight(parent)
        sib.rank += 1
        parent.rank -= 1
        if sibRightDiff == 1:
          parent.rank -= 1
        break
      elif sibRightDiff == 1 and not sib.right.isNil:
        # Double rotation (left-right)
        let sibRight = sib.right
        tree.rotateLeft(sib)
        tree.rotateRight(parent)
        sibRight.rank += 2
        sib.rank -= 1
        parent.rank -= 2
        break
      else:
        # Fallback: demote and continue
        parent.rank -= 1
        if sib.rank > 0:
          sib.rank -= 1
        curr = parent
    else:
      break

proc successor[K, V](tree: WAVLTree[K, V], node: Node[K, V]): Node[K, V] =
  ## Returns the successor of the given node, or nil if one doesn't exist.
  if not node.right.isNil:
    result = min(node.right)
  else:
    var node = node
    result = node.parent
    while not result.isNil and node == result.right:
      node = result
      result = result.parent

proc removeNode[K, V](tree: var WAVLTree[K, V], node: var Node[K, V]) =
  ## Internal: remove a specific node from the tree.
  tree.size -= 1
  if not node.left.isNil and not node.right.isNil:
    let next = tree.successor(node)
    node.key = next.key
    node.value = next.value
    node = next

  let child = if node.left.isNil: node.right else: node.left
  if not child.isNil:
    child.parent = node.parent

  var fixFrom = node.parent
  if node.parent.isNil:
    tree.root = child
  elif node == node.parent.left:
    node.parent.left = child
  else:
    node.parent.right = child

  updateCountsToRoot(fixFrom)
  if not fixFrom.isNil:
    tree.fixRemove(if child.isNil: fixFrom else: child)

proc remove*[K, V](tree: var WAVLTree[K, V], key: K): bool {.discardable.} =
  ## Remove a key/value pair from the tree. Returns true if something was
  ## removed, false if the key wasn't found.
  var node = tree.findNode(key)
  result = not node.isNil
  if result:
    tree.removeNode(node)

proc pop*[K, V](tree: var WAVLTree[K, V], key: K): V {.discardable.} =
  ## Remove `key` from `tree` and return its value.
  ## Raises KeyError if key is not found.
  var node = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  result = move node.value
  tree.removeNode(node)

proc len*[K, V](tree: WAVLTree[K, V]): int =
  ## Returns the number of items in the tree.
  tree.size

iterator pairs*[K, V](tree: WAVLTree[K, V]): (K, V) =
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

iterator keys*[K, V](tree: WAVLTree[K, V]): K =
  ## Iterates over the keys of the tree in-order.
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

iterator values*[K, V](tree: WAVLTree[K, V]): V =
  ## Iterates over the values of the tree in-order.
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

proc selectNode[K, V](node: Node[K, V]; i: Natural): Node[K, V] =
  ## Returns the `i`'th smallest (0-indexed) child in `node`.
  if node.isNil:
    raise IndexDefect.newException "index out of bounds"
  let leftCount = node.left.nodeCount
  if i == leftCount:
    node
  elif i < leftCount:
    selectNode(node.left, i)
  else:
    selectNode(node.right, i - leftCount - 1)

proc select*[K, V](tree: WAVLTree[K, V]; i: int): (K, V) =
  ## Returns the `i`'th smallest (0-indexed) item in `tree`.
  ## Negative indices count from the end (-1 = last).
  ## Raises IndexDefect if index is out of bounds.
  if tree.root.isNil:
    raise IndexDefect.newException "index out of bounds"
  var idx = i
  if idx < 0:
    idx = tree.size + idx
  if idx < 0 or idx >= tree.size:
    raise IndexDefect.newException "index out of bounds"
  let node = selectNode(tree.root, idx)
  result = (node.key, node.value)

proc rankNode[K, V](root, node: Node[K, V]): Natural =
  ## Returns the 0-indexed position of `node` in `root`.
  var node = node
  result = node.left.nodeCount
  while node != root:
    if node == node.parent.right:
      result += node.parent.left.nodeCount + 1
    node = node.parent

proc rank*[K, V](tree: WAVLTree[K, V]; key: K): Natural =
  ## Returns the 0-indexed position of `key` in `tree`.
  ## Raises KeyError if key is not found.
  if tree.root.isNil:
    raise KeyError.newException "not found"
  let node = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  result = rankNode(tree.root, node)

proc popMin*[K, V](tree: var WAVLTree[K, V]): (K, V) {.discardable.} =
  ## Removes and returns the smallest key/value pair in `tree`.
  ## Raises ValueError if the tree is empty.
  if tree.root.isNil or tree.size == 0:
    raise ValueError.newException "tree is empty"
  var node = min(tree.root)
  result = (move node.key, move node.value)
  tree.removeNode(node)

proc popMax*[K, V](tree: var WAVLTree[K, V]): (K, V) {.discardable.} =
  ## Removes and returns the largest key/value pair in `tree`.
  ## Raises ValueError if the tree is empty.
  if tree.root.isNil or tree.size == 0:
    raise ValueError.newException "tree is empty"
  var node = max(tree.root)
  result = (move node.key, move node.value)
  tree.removeNode(node)
