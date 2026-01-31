## Splay tree implementation.
## https://en.wikipedia.org/wiki/Splay_tree

type
  Node[K, V] = ref object
    parent {.cursor.}: Node[K, V]
    left: Node[K, V]
    right: Node[K, V]
    key: K
    value: V
    count: int  # size of subtree rooted at this node

  SplayTree*[K, V] = object
    root: Node[K, V]
    size: int

proc newSplayTree*[K, V](): SplayTree[K, V] =
  ## Construct a new Splay tree.
  discard

proc nodeCount[K, V](node: Node[K, V]): int {.inline.} =
  if node.isNil: 0 else: node.count

proc updateCount[K, V](node: Node[K, V]) {.inline.} =
  if not node.isNil:
    node.count = node.left.nodeCount + 1 + node.right.nodeCount

template isRoot(node: Node): untyped =
  node.parent.isNil

proc rotateLeft[K, V](tree: var SplayTree[K, V], node: Node[K, V]) =
  ## Rotates a tree left around the given node.
  if node.isNil:
    return
  var our = move node.right
  # we take the node's parent
  our.parent = node.parent
  # our left node becomes node's right branch
  node.right = move our.left
  if not node.right.isNil:
    # fixup parent of right branch of node
    node.right.parent = node
  # we become the node's parent
  node.parent = our
  # put the node in our left position
  our.left = node
  # update anything above us
  if our.isRoot:
    # we're the root; update the tree
    tree.root = our
  elif our.parent.left == our.left:
    # we replace node on our parent's left
    our.parent.left = our
  else:
    # we replace node on our parent's right
    our.parent.right = our
  # update counts
  updateCount(node)
  updateCount(our)

proc rotateRight[K, V](tree: var SplayTree[K, V], node: Node[K, V]) =
  ## Rotates a tree right around the given node.
  if node.isNil:
    return
  var our = move node.left
  # we take the node's parent
  our.parent = node.parent
  # our right node becomes node's left branch
  node.left = move our.right
  if not node.left.isNil:
    # fixup parent of left branch of node
    node.left.parent = node
  # we become the node's parent
  node.parent = our
  # put the node in our right position
  our.right = node
  # update anything above us
  if our.isRoot:
    # we're the root; update the tree
    tree.root = our
  elif our.parent.right == our.right:
    # we replace node on our parent's right
    our.parent.right = our
  else:
    # we replace node on our parent's left
    our.parent.left = our
  # update counts
  updateCount(node)
  updateCount(our)

proc splay[K, V](tree: var SplayTree[K, V], node: Node[K, V]) =
  ## Move `node` to the root via rotations (splaying).
  while not node.isRoot:
    # While it's not the root, keep going
    if node.parent.isRoot:
      # One level away from root
      if node == node.parent.left:
        tree.rotateRight(node.parent)
      else:
        tree.rotateLeft(node.parent)
    # zig-zig cases. Doing these this way provides a much better tree structure
    # than simple single rotations performed independently in a loop
    elif node == node.parent.left and node.parent == node.parent.parent.left:
      tree.rotateRight(node.parent.parent)
      tree.rotateRight(node.parent)
    elif node == node.parent.right and node.parent == node.parent.parent.right:
      tree.rotateLeft(node.parent.parent)
      tree.rotateLeft(node.parent)
    # zig-zag cases
    elif node == node.parent.right and node.parent == node.parent.parent.left:
      tree.rotateLeft(node.parent)
      tree.rotateRight(node.parent)
    else:
      tree.rotateRight(node.parent)
      tree.rotateLeft(node.parent)

proc findNode[K, V](tree: SplayTree[K, V], key: K): (Node[K, V], Node[K, V]) =
  ## Finds a node with the given key and its parent, or nil if it doesn't exist.
  var parent: Node[K, V]
  var curr = tree.root
  block found:
    while not curr.isNil:
      let comp = cmp(key, curr.key)
      if comp == 0:
        result = (parent, curr)
        break found
      elif comp < 0:
        parent = curr
        curr = curr.left
      else:
        parent = curr
        curr = curr.right
    result = (parent, nil)

proc peek*[K, V](tree: SplayTree[K, V], key: K): (V, bool) =
  ## Query without splaying. Returns (value, true) if found, (default, false) otherwise.
  if tree.size > 0:
    let (parent, child) = tree.findNode(key)
    if not child.isNil:
      return (child.value, true)
  var default: V
  result = (default, false)

proc find*[K, V](tree: SplayTree[K, V], key: K; value: var V): bool =
  ## Recover the `value` from the `key`; truthy if `value` was modified.
  ## Does not splay (const tree).
  if tree.size > 0:
    let (parent, child) = tree.findNode(key)
    result = not child.isNil
    if result:
      # Found it
      value = child.value

proc find*[K, V](tree: var SplayTree[K, V], key: K; value: var V): bool =
  ## Recover the `value` from the `key`; truthy if `value` was modified.
  ## Splays the accessed node to the root.
  if tree.size > 0:
    let (parent, child) = tree.findNode(key)
    result = not child.isNil
    if result:
      # Found it, splay it
      tree.splay(child)
      value = child.value
    elif not parent.isNil:
      # Didn't find the key, splay the last node we found
      tree.splay(parent)

proc find*[K, V](tree: var SplayTree[K, V], key: K): (V, bool) =
  ## Find the value associated with a given key. Returns the value and true
  ## if the key was found, and a default value and false if not.
  ## Splays the accessed node to the root.
  var value: V
  if tree.find(key, value):
    result = (value, true)

proc updateCountsToRoot[K, V](node: Node[K, V]) =
  ## Update counts from node up to root.
  var curr = node
  while not curr.isNil:
    updateCount(curr)
    curr = curr.parent

proc insert*[K, V](tree: var SplayTree[K, V], key: K, value: V): bool {.discardable} =
  if tree.root.isNil:
    assert tree.size == 0
    tree.root = Node[K, V](key: key, value: value, count: 1)
    tree.size = 1
    return true

  var curr = tree.root
  var path: seq[Node[K, V]]
  while not curr.isNil:
    path.add(curr)
    let comp = cmp(key, curr.key)
    if comp == 0:
      # If it's already there, set the data, splay, and return
      curr.value = value
      tree.splay(curr)
      result = false
      break
    elif comp < 0:
      # Go to the left
      if curr.left.isNil:
        # It's not there, insert and fix tree
        curr.left = Node[K, V](parent: curr, key: key, value: value, count: 1)
        tree.size += 1
        # Update counts along the path
        for n in path:
          n.count += 1
        tree.splay(curr.left)
        result = true
        break
      else:
        curr = curr.left
    else:
      # Go to the right
      if curr.right.isNil:
        # It's not there, insert and fix tree
        curr.right = Node[K, V](parent: curr, key: key, value: value, count: 1)
        tree.size += 1
        # Update counts along the path
        for n in path:
          n.count += 1
        tree.splay(curr.right)
        result = true
        break
      else:
        curr = curr.right

proc successor[K, V](tree: SplayTree[K, V]; node: Node[K, V]): Node[K, V] =
  ## Returns the successor of the given node, or nil if one doesn't exist
  result = node.right
  while not result.isNil and not result.left.isNil:
    result = result.left

proc removeNode[K, V](tree: var SplayTree[K, V], node: var Node[K, V]) =
  ## Internal: remove a specific node from the tree.
  tree.size -= 1
  var actualNode = node
  if not node.left.isNil and not node.right.isNil:
    # Internal node, the successor's data can be placed here without violating
    # bst properties. Now we need to delete the successor.
    let succ = tree.successor(node)
    node.key = succ.key
    node.value = succ.value
    actualNode = succ
    node = succ

  # Now the node we are trying to delete has at most one child
  let child =
    if not node.left.isNil:
      node.left
    else:
      node.right
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

  # Update counts from deleted node's parent up to root
  updateCountsToRoot(node.parent)

proc remove*[K, V](tree: var SplayTree[K, V], key: K): bool {.discardable.} =
  ## Remove a key value pair from the tree. Returns true if something was
  ## removed, false if the key wasn't found, so nothing was removed.
  var (parent, node) = tree.findNode(key)
  # If a node with that data doesn't exist, nothing to do
  if node.isNil:
    return false
  if not parent.isNil:
    tree.splay(parent)

  tree.removeNode(node)
  return true

proc len*[K, V](tree: SplayTree[K, V]): int =
  ## Returns the number of items in the tree.
  tree.size

iterator pairs*[K, V](tree: SplayTree[K, V]): (K, V) =
  ## Iterates over the elements of the tree in order.
  var node = tree.root
  var stack: seq[Node[K, V]]
  while stack.len > 0 or not node.isNil:
    if node.isNil:
      node = pop stack
      yield (node.key, node.value)
      node = node.right
    else:
      stack.add node
      node = node.left

iterator keys*[K, V](tree: SplayTree[K, V]): K =
  ## Iterates over keys of the tree in order.
  var node = tree.root
  var stack: seq[Node[K, V]]
  while stack.len > 0 or not node.isNil:
    if node.isNil:
      node = pop stack
      yield node.key
      node = node.right
    else:
      stack.add node
      node = node.left

iterator values*[K, V](tree: SplayTree[K, V]): V =
  ## Iterates over values of the tree in order.
  var node = tree.root
  var stack: seq[Node[K, V]]
  while stack.len > 0 or not node.isNil:
    if node.isNil:
      node = pop stack
      yield node.value
      node = node.right
    else:
      stack.add node
      node = node.left

proc contains*[K, V](tree: SplayTree[K, V]; key: K): bool =
  ## Returns `true` if `key` exists in `tree`.
  let (_, child) = tree.findNode(key)
  not child.isNil

proc minNode[K, V](tree: SplayTree[K, V]): Node[K, V] =
  result = tree.root
  if result.isNil:
    return nil
  while not result.left.isNil:
    result = result.left

proc maxNode[K, V](tree: SplayTree[K, V]): Node[K, V] =
  result = tree.root
  if result.isNil:
    return nil
  while not result.right.isNil:
    result = result.right

proc min*[K, V](tree: SplayTree[K, V]): (K, V) =
  ## Returns the smallest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  let node = tree.minNode
  if node.isNil:
    raise ValueError.newException "tree is empty"
  result = (node.key, node.value)

proc max*[K, V](tree: SplayTree[K, V]): (K, V) =
  ## Returns the largest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  let node = tree.maxNode
  if node.isNil:
    raise ValueError.newException "tree is empty"
  result = (node.key, node.value)

proc popMin*[K, V](tree: var SplayTree[K, V]): (K, V) {.discardable.} =
  ## Removes and returns the smallest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  var node = tree.minNode
  if node.isNil:
    raise ValueError.newException "tree is empty"
  result = (move node.key, move node.value)
  tree.removeNode(node)

proc popMax*[K, V](tree: var SplayTree[K, V]): (K, V) {.discardable.} =
  ## Removes and returns the largest key/value pair in the tree.
  ## Raises ValueError if the tree is empty.
  var node = tree.maxNode
  if node.isNil:
    raise ValueError.newException "tree is empty"
  result = (move node.key, move node.value)
  tree.removeNode(node)

proc `[]=`*[K, V](tree: var SplayTree[K, V]; key: K; value: V) =
  ## Add `key` and `value` pair to `tree`.
  discard tree.insert(key, value)

proc `[]`*[K, V](tree: var SplayTree[K, V]; key: K): var V =
  ## Recover value of `key` in `tree`. Splays on access.
  ## Raises KeyError if key is not found.
  let (_, node) = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  tree.splay(node)
  result = node.value

proc pop*[K, V](tree: var SplayTree[K, V], key: K): V {.discardable.} =
  ## Remove `key` from `tree` and return its value.
  ## Raises KeyError if key is not found.
  var (parent, node) = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  result = move node.value
  if not parent.isNil:
    tree.splay(parent)
  tree.removeNode(node)

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

proc select*[K, V](tree: SplayTree[K, V]; i: int): (K, V) =
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

proc rank*[K, V](tree: SplayTree[K, V]; key: K): Natural =
  ## Returns the 0-indexed position of `key` in `tree`.
  ## Raises KeyError if key is not found.
  if tree.root.isNil:
    raise KeyError.newException "not found"
  let (_, node) = tree.findNode(key)
  if node.isNil:
    raise KeyError.newException "not found"
  result = rankNode(tree.root, node)
