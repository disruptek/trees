## Implementation of an AVL tree in Nim, based on
## https://en.wikipedia.org/wiki/Splay_tree.
## Recursive iterators aren't allowed in nim, so iterative tree traversals were
## needed, found on wikipedia as well.
##
## Elements are compared via the `cmp` function, so the `<` and `==` operators
## should be defined for the key type of the tree. Duplicate keys are not
## allowed in the tree.
##
## Splay trees are binary search trees that don't apply balance operations
## on each insert/remove, and as such are unbalanced and don't provide a
## O(lg(n)) worst case insert/remove. Instead, splay trees rotate newly added
## and searched for data to the top of the tree so commonly accessed data and
## newly inserted items are very fast to find, as you don't have to go through
## a large part of the tree to find them. Splay tree double rotations are
## slightly different than normal double tree rotations, so data ascends the
## tree quickly, but descends much slower. This is good enough to offer
## amortized lg(n) time for insert, remove and find.

type
  Node[K, V] = ref object
    parent: Node[K, V]
    left: Node[K, V]
    right: Node[K, V]
    key: K
    value: V

  SplayTree*[K, V] = object
    root: Node[K, V]
    size: int

template isRoot(node: Node): untyped =
  node.parent.isNil

proc rotateLeft[K, V](tree: var SplayTree[K, V], node: Node[K, V]) =
  ## Rotates a tree left around the given node.
  if node.isNil:
    return
  var our = move node.right
  # we take the node's parent
  our.parent = move node.parent
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

proc rotateRight[K, V](tree: var SplayTree[K, V], node: Node[K, V]) =
  ## Rotates a tree right around the given node.
  if node.isNil:
    return

  var our = move node.left
  # we take the node's parent
  our.parent = move node.parent
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

proc splay[K, V](tree: var SplayTree[K, V], node: Node[K, V]) =
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
  ## Finds a node with the given key and it's parent, or nil if it doesn't exist.
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

proc find*[K, V](tree: SplayTree[K, V], key: K; value: var V): bool =
  ## Recover the `value` from the `key`; truthy if `value` was modified.
  if tree.size > 0:
    let (parent, child) = tree.findNode(key)
    result = not child.isNil
    if result:
      # Found it
      value = child.value

proc find*[K, V](tree: var SplayTree[K, V], key: K; value: var V): bool =
  ## Recover the `value` from the `key`; truthy if `value` was modified.
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

proc insert*[K, V](tree: var SplayTree[K, V], key: K, value: V): bool {.discardable} =
  if tree.root.isNil:
    assert tree.size == 0
    tree.root = Node[K, V](key: key, value: value)
    tree.size = 1
    return true

  var curr = tree.root
  while not curr.isNil:
    let comp = cmp(key, curr.key)
    if comp == 0:
      # If it's already there, set the data, splay,  and return
      curr.value = value
      tree.splay(curr)
      result = false
      break
    elif comp < 0:
      # Go to the left
      if curr.left.isNil:
        # It's not there, insert and fix tree
        curr.left = Node[K, V](parent: curr, key: key, value: value)
        tree.size += 1
        tree.splay(curr.left)
        result = true
        break
      else:
        curr = curr.left
    else:
      # Go to the right
      if curr.right.isNil:
        # It's not there, insert and fix tree
        curr.right = Node[K, V](parent: curr, key: key, value: value)
        tree.size += 1
        tree.splay(curr.right)
        result = true
        break
      else:
        curr = curr.right

proc successor[K, V](tree: SplayTree[K, V]; node: Node[K, V]): Node[K, V] =
  ## Returns the successor of the given node, or nil if one doesn't exist
  result = node.right
  while not result.isNil and not result.right.isNil:
    result = result.right

proc remove*[K, V](tree: var SplayTree[K, V], key: K): bool {.discardable.} =
  ## Remove a key value pair from the tree. Returns true if something was
  ## removed, false if the key wasn't found, so nothing was removed.
  var (parent, node) = tree.findNode(key)
  # If a node with that data doesn't exist, nothing to do
  if node.isNil:
    return false
  if not parent.isNil:
    tree.splay(parent)

  tree.size -= 1
  if not node.left.isNil and not node.right.isNil:
    # Internal node, the successor's data can be placed here without violating
    # bst properties. Now we need to delete the successor.
    let succ = tree.successor(node)
    node.key = succ.key
    node.value = succ.value
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

  return true

proc len*[K, V](tree: SplayTree[K, V]): int =
  ## Returns the number of items the in tree
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
