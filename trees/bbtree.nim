## Bounded Balance tree (weight-balanced tree) implementation.
## https://en.wikipedia.org/wiki/Weight-balanced_tree
##
## References:
## - Adams, "Implementing Sets Efficiently in a Functional Language", CSTR 92-10
## - Straka, "Adams' Trees Revisited", 2011
##
## Copyright (c) 2012-18 Doug Currie. MIT License.

type
    BBTree*[K,V] = ref object   # BBTree is a generic type with keys and values of types K, V
        ## `BBTree` is an opaque immutable type.
        left:  BBTree[K,V]      # left subtree; may be nil
        right: BBTree[K,V]      # right subtree; may be nil
        size:  int              # the size of the (sub-)tree rooted in this node
        key:   K                # the search key; must support the generic ``cmp`` proc
        val:   V                # the data value associated with the key, and stored in a node

const                           # balance criteria
    omega = 3
    alpha = 2

func nodeSize[K,V](n: BBTree[K,V]): int {.inline.} =
    if n.isNil:
        result = 0
    else:
        result = n.size

func len*[K,V](root: BBTree[K,V]): int =
    ## Returns the number of keys in tree at `root`.  O(1)
    result = nodeSize(root)

func newLeaf[K,V](key: K, value: V): BBTree[K,V] =
    # constructor for a leaf node
    result = BBTree[K,V](left: nil, right: nil, size: 1, key: key, val: value)

func newNode[K,V](left: BBTree[K,V], key: K, value: V, right: BBTree[K,V]): BBTree[K,V] =
    # constructor for a new node
    let size = nodeSize(left) + 1 + nodeSize(right)
    result = BBTree[K,V](left: left, right: right, size: size, key: key, val: value)

# Balance operations

func singleL[K,V](left: BBTree[K,V], key: K, value: V, right: BBTree[K,V]): BBTree[K,V] =
    result = newNode(newNode(left, key, value, right.left),
                        right.key,
                        right.val,
                        right.right)

func doubleL[K,V](left: BBTree[K,V], key: K, value: V, right: BBTree[K,V]): BBTree[K,V] =
    let rl = right.left
    result = newNode(newNode(left, key, value, rl.left),
                     rl.key,
                     rl.val,
                     newNode(rl.right, right.key, right.val, right.right))


func singleR[K,V](left: BBTree[K,V], key: K, value: V, right: BBTree[K,V]): BBTree[K,V] =
    result = newNode(left.left,
                     left.key,
                     left.val,
                     newNode(left.right, key, value, right))

func doubleR[K,V](left: BBTree[K,V], key: K, value: V, right: BBTree[K,V]): BBTree[K,V] =
    let lr = left.right
    result = newNode(newNode(left.left, left.key, left.val, lr.left),
                     lr.key,
                     lr.val,
                     newNode(lr.right, key, value, right))

func balance[K,V](left: BBTree[K,V], key: K, value: V, right: BBTree[K,V]): BBTree[K,V] =
    let
        sl = nodeSize(left)
        sr = nodeSize(right)

    if ((sl + sr) <= 1):
        result = newNode(left, key, value, right)
    elif (sr > (omega * sl)):
        if (nodeSize(right.left) < (alpha * nodeSize(right.right))):
            result = singleL(left, key, value, right)
        else:
            result = doubleL(left, key, value, right)
    elif (sl > (omega * sr)):
        if (nodeSize(left.right) < (alpha * nodeSize(left.left))):
            result = singleR(left, key, value, right)
        else:
            result = doubleR(left, key, value, right)
    else:
        result = newNode(left, key, value, right)

# Insert

func insert*[K,V](root: BBTree[K,V], key: K, value: V): BBTree[K,V] =
    ## Returns a new tree with the (`key`, `value`) pair added, or replaced if `key` is already
    ## in the tree `root`. O(log N)
    if root.isNil:
        result = newLeaf(key, value)
    else:
        let dif = cmp(key, root.key);
        if (dif < 0):
            result = balance(insert(root.left, key, value), root.key, root.val, root.right)
        elif (dif > 0):
            result = balance(root.left, root.key, root.val, insert(root.right, key, value))
        else: # key and root.key are equal
            result = newNode(root.left, key, value, root.right)

func add*[K,V](root: var BBTree[K,V], key: K, value: V) =
    ## Mutable wrapper: inserts (`key`, `value`) pair into `root`.
    let immutable = root
    root = insert(immutable, key, value)  # sigmatch the immutable version

# Lookup

func find*[K,V](root: BBTree[K,V], key: K, default: V): V =
    ## Retrieves the value for `key` in the tree `root` iff `key` is in the tree.
    ## Otherwise, `default` is returned. O(log N)
    result = default
    var node = root
    while (not node.isNil):
        let dif = cmp(key, node.key)
        if dif < 0:
            node = node.left
        elif dif > 0:
            node = node.right
        else: # key and node.key are eq
            result = node.val
            node = nil # break

func getNth*[K,V](root: BBTree[K,V], index: int, default: (K, V)): (K, V) =
    ## Get the key,value pair of the 0-based `index` key in the tree `root` when index is
    ## positive and less than the tree length. Or get the tree length plus `index` key in
    ## the tree `root` when the `index` is negative and greater than the negative tree length.
    ## Otherwise, `default` is returned. O(log N)
    result = default
    let treesize = nodeSize(root)
    var uindex = 0
    var node = root
    if (index < treesize) and (index >= (-treesize)):
        if index < 0:
            uindex = treesize + index # when negative, reverse index from end rather than inorder
        else:
            uindex = index # all set
        while (not node.isNil):
            let leftsize = nodeSize(node.left)
            if uindex < leftsize:
                node = node.left
            elif uindex > leftsize:
                uindex -= (leftsize + 1)
                node = node.right
            else: # we are there!
                result = (node.key, node.val)
                node = nil # break
    # else index is out of range; default is returned

func getMin*[K,V](root: BBTree[K,V], default: (K, V)): (K, V) =
    ## Retrieves the key,value pair with the smallest key in the tree `root`
    ## For an empty tree `default` is returned. O(log N)
    var node = root
    if node.isNil:
        result = default
    else:
        while (not node.left.isNil):
            node = node.left;
        result = (node.key, node.val)

func getMax*[K,V](root: BBTree[K,V], default: (K, V)): (K, V) =
    ## Retrieves the key,value pair with the largest key in the tree `root`
    ## For an empty tree `default` is returned. O(log N)
    var node = root
    if node.isNil:
        result = default
    else:
        while (not node.right.isNil):
            node = node.right;
        result = (node.key, node.val)

func getKV[K,V](node: BBTree[K,V], default: (K, V)): (K, V) {.inline.} =
    if node.isNil:
        result = default
    else:
        result = (node.key, node.val)

func getNext*[K,V](root: BBTree[K,V], key: K, default: (K,V)): (K,V) =
    ## Returns the key,value pair with smallest key > `key`.
    ## It is almost inorder successor, but it also works when `key` is not present.
    ## If there is no such successor key in the tree, `default` is returned. O(log N)
    var last_left_from: BBTree[K,V] = nil
    var node = root
    var done = false
    while not done:
        if node.isNil:
            result = getKV(last_left_from, default) # key not found
            done = true
        else:
            let dif = cmp(key, node.key)
            if (dif < 0):
                last_left_from = node
                node = node.left
            elif (dif > 0):
                node = node.right
            else: # key and node.key are eq
                # return value from min node of right subtree, or from last_left_from if none
                if node.right.isNil:
                    result = getKV(last_left_from, default)
                else:
                    result = getMin(node.right, default)
                done = true

func getPrev*[K,V](root: BBTree[K,V], key: K, default: (K,V)): (K,V) =
    ## Returns the key,value pair with largest key < `key`.
    ## It is almost inorder predecessor, but it also works when `key` is not present.
    ## If there is no such predecessor key in the tree, `default` is returned. O(log N)
    var last_right_from: BBTree[K,V] = nil
    var node = root
    var done = false
    while not done:
        if node.isNil:
            result = getKV(last_right_from, default) # key not found
            done = true
        else:
            let dif = cmp(key, node.key)
            if (dif < 0):
                node = node.left
            elif (dif > 0):
                last_right_from = node
                node = node.right
            else: # key and node.key are eq
                # return value from max node of left subtree, or from last_right_from if none
                if node.left.isNil:
                    result = getKV(last_right_from, default)
                else:
                    result = getMax(node.left, default)
                done = true


# Delete

func extractMin[K,V](node: BBTree[K,V]): (K, V, BBTree[K,V]) =
    if node.left.isNil:
        result = (node.key, node.val, node.right)
    else:
        let (mink, minv, nodep) = extractMin(node.left)
        result = (mink, minv, balance(nodep, node.key, node.val, node.right))

func extractMax[K,V](node: BBTree[K,V]): (K, V, BBTree[K,V]) =
    if node.right.isNil:
        result = (node.key, node.val, node.left)
    else:
        let (maxk, maxv, nodep) = extractMax(node.right)
        result = (maxk, maxv, balance(node.left, node.key, node.val, nodep))

func glue[K,V](left: BBTree[K,V], right: BBTree[K,V]): BBTree[K,V] =
    if left.isNil:
        result = right
    elif right.isNil:
        result = left
    elif nodeSize(left) > nodeSize(right):
        let (maxk, maxv, leftp) = extractMax(left)
        result = newNode(leftp, maxk, maxv, right)
    else:
        let (mink, minv, rightp) = extractMin(right)
        result = newNode(left, mink, minv, rightp)

func remove*[K,V](root: BBTree[K,V], key: K): BBTree[K,V] =
    ## Removes `key` from tree `root`. Does nothing if the key does not exist.
    ## O(log N)
    if root.isNil:
        result = root
    else:
        let dif = cmp(key, root.key);
        if (dif < 0):
            result = balance(remove(root.left, key), root.key, root.val, root.right)
        elif (dif > 0):
            result = balance(root.left, root.key, root.val, remove(root.right, key))
        else: # key and root.key are eq
            result = glue(root.left, root.right)

func del*[K,V](root: var BBTree[K,V], key: K) =
    ## Mutable wrapper: removes `key` from `root`.
    let immutable = root
    root = remove(immutable, key)

func delMin*[K,V](root: BBTree[K,V]): BBTree[K,V] =
    ## Delete the minimum element from tree `root`. O(log N)
    if root.isNil:
        result = root
    else:
        let (mink, minv, node) = extractMin(root)
        discard mink
        discard minv
        result = node

func delMax*[K,V](root: BBTree[K,V]): BBTree[K,V] =
    ## Delete the maximum element from tree `root`. O(log N)
    if root.isNil:
        result = root
    else:
        let (maxk, maxv, node) = extractMax(root)
        discard maxk
        discard maxv
        result = node

# Rank

func rank*[K,V](root: BBTree[K,V], key: K, default: int): int =
    ## Retrieves the 0-based index of `key` in the tree `root` iff `key` is in the tree.
    ## Otherwise, `default` is returned. O(log N)
    result = default
    var n = 0
    var node = root
    while (not node.isNil):
        let dif = cmp(key, node.key);
        if (dif < 0):
            node = node.left
        elif (dif > 0):
            n += 1 + nodeSize(node.left)
            node = node.right
        else: # key and node.key are eq
            result = n + nodeSize(node.left)
            node = nil # break

# Iterators

iterator pairs*[K,V](root: BBTree[K,V]): (K,V) =
    ## Iterates over (key, value) pairs in order (smallest to largest).
    var stack: seq[BBTree[K,V]] = @[]
    var curr = root
    while (not curr.isNil) or stack.len > 0:
        while (not curr.isNil):
            add(stack, curr)
            curr = curr.left
        curr = stack.pop()
        yield (curr.key, curr.val)
        curr = curr.right

iterator keys*[K,V](root: BBTree[K,V]): K =
    ## Iterates over keys in order (smallest to largest).
    var stack: seq[BBTree[K,V]] = @[]
    var curr = root
    while (not curr.isNil) or stack.len > 0:
        while (not curr.isNil):
            add(stack, curr)
            curr = curr.left
        curr = stack.pop()
        yield curr.key
        curr = curr.right

iterator values*[K,V](root: BBTree[K,V]): V =
    ## Iterates over values in order (smallest to largest key).
    var stack: seq[BBTree[K,V]] = @[]
    var curr = root
    while (not curr.isNil) or stack.len > 0:
        while (not curr.isNil):
            add(stack, curr)
            curr = curr.left
        curr = stack.pop()
        yield curr.val
        curr = curr.right

iterator inorder*[K,V](root: BBTree[K,V]): (K,V) =
    ## Alias for `pairs`. Inorder traversal of the tree.
    for kv in pairs(root):
        yield kv

iterator revorder*[K,V](root: BBTree[K,V]): (K,V) =
    ## Reverse inorder traversal of the tree (largest to smallest key).
    var stack: seq[BBTree[K,V]] = @[]
    var curr = root
    while (not curr.isNil) or stack.len > 0:
        while (not curr.isNil):
            add(stack, curr)
            curr = curr.right
        curr = stack.pop()
        yield (curr.key, curr.val)
        curr = curr.left

# Fold & Map

proc fold*[K,V,T](root: BBTree[K,V], f: proc (key: K, val: V, base: T): T, base: T): T =
    ## Applies the proc `f` to each value of tree `root` in reverse order (right to left).
    ## Uses the `base` value for the first rightmost operand.
    var stack: seq[BBTree[K,V]] = @[]
    var curr = root
    result = base
    while (not curr.isNil) or stack.len > 0:
        while (not curr.isNil):
            add(stack, curr)
            curr = curr.right
        curr = stack.pop()
        result = f(curr.key, curr.val, result)
        curr = curr.left

func map*[K,V,T](root: BBTree[K,V], f: proc (key: K, val: V): T {.noSideEffect.}): BBTree[K,T] =
    ## Returns a new tree with the keys of tree `root` and values that are the result of
    ## applying `f` to each key and corresponding value. So, for example, to construct a
    ## tree with values replaced by concatenated string of key,value pairs, you could use
    ##
    ## .. code-block::
    ##
    ##     map(root, proc (k: int, v: int): string = $k & ":" & $v)
    if root.isNil:
        result = nil
    else:
        result = newNode(map(root.left, f), root.key, f(root.key, root.val), map(root.right, f))

# Set operations

# This is Adams's concat3
#
func join[K,V](key: K, val: V, left, right: BBTree[K,V]): BBTree[K,V] =
    if left.isNil:
        result = insert(right, key, val)
    elif right.isNil:
        result = insert(left, key, val)
    else:
        let sl = nodeSize(left)
        let sr = nodeSize(right)
        if (omega * sl) < sr:
            result = balance(join(key, val, left, right.left), right.key, right.val, right.right)
        elif (omega * sr) < sl:
            result = balance(left.left, left.key, left.val, join(key, val, left.right, right))
        else:
            result = newNode(left, key, val, right)

# This is Adams's concat
#
func join[K,V](left, right: BBTree[K,V]): BBTree[K,V] =
    if left.isNil:
        result = right
    elif right.isNil:
        result =left
    else:
        let (key, val, rightp) = extractMin(right)
        result = join(key, val, left, rightp)

# This is Adams's split_lt and split_gt combined into one function, along with contains(root, key)
#
func split[K,V](key: K, root: BBTree[K,V]): (BBTree[K,V], bool, BBTree[K,V]) =
    if root.isNil:
        result = (root, false, root)
    else:
        let dif = cmp(key, root.key)
        if dif < 0:
            let (l, b, r) = split(key, root.left)
            result = (l, b, join(root.key, root.val, r, root.right))
        elif dif > 0:
            let (l, b, r) = split(key, root.right)
            result = (join(root.key, root.val, root.left, l), b, r)
        else: # key and node.key are eq
            result = (root.left, true, root.right)

func splitMerge[K,V](key: K, val: V, root: BBTree[K,V], merge: proc (k: K, v1, v2: V): V {.noSideEffect.}):
    (BBTree[K,V], bool, V, BBTree[K,V]) =
    if root.isNil:
        result = (root, false, val, root)
    else:
        let dif = cmp(key, root.key)
        if dif < 0:
            let (l, b, val, r) = splitMerge(key, val, root.left, merge)
            result = (l, b, val, join(root.key, root.val, r, root.right))
        elif dif > 0:
            let (l, b, val, r) = splitMerge(key, val, root.right, merge)
            result = (join(root.key, root.val, root.left, l), b, val, r)
        else: # key and node.key are eq
            result = (root.left, true, merge(key, val, root.val), root.right)

func union*[K,V](tree1, tree2: BBTree[K,V]): BBTree[K,V] =
    ## Returns the union of the sets represented by the keys in `tree1` and `tree2`.
    ## When viewed as maps, returns the key,value pairs that appear in either tree; if
    ## a key appears in both trees, the value for that key is selected from `tree1`, so
    ## this function is asymmetrical for maps. If you need more control over how the
    ## values are selected for duplicate keys, see `unionMerge`. O(M + N) but if the minimum
    ## key of one tree is greater than the maximum key of the other tree then O(log M)
    ## where M is the size of the larger tree.
    if tree1.isNil:
        result = tree2
    elif tree2.isNil:
        result = tree1
    else:
        let (l, b, r) = split(tree1.key, tree2)
        discard b
        result = join(tree1.key, tree1.val, union(tree1.left, l), union(tree1.right, r))

func unionMerge*[K,V](tree1, tree2: BBTree[K,V], merge: proc (k: K, v1, v2: V): V {.noSideEffect.}): BBTree[K,V] =
    ## Returns the union of the sets represented by the keys in `tree1` and `tree2`.
    ## When viewed as maps, returns the key,value pairs that appear in either tree; if
    ## a key appears in both trees, the value for that key is the result of the supplied
    ## `merge` function, which is passed the common key, and the values from `tree1` and
    ## `tree2` respectively.  O(M + N) but if the minimum
    ## key of one tree is greater than the maximum key of the other tree then O(log M)
    ## where M is the size of the larger tree.
    if tree1.isNil:
        result = tree2
    elif tree2.isNil:
        result = tree1
    else:
        let (l, b, v, r) = splitMerge(tree1.key, tree1.val, tree2, merge)
        discard b
        result = join(tree1.key, v, unionMerge(tree1.left, l, merge), unionMerge(tree1.right, r, merge))

func difference*[K,V](tree1, tree2: BBTree[K,V]): BBTree[K,V] =
    ## Returns the asymmetric set difference between `tree1` and `tree2`. In other words,
    ## returns the keys that are in `tree1`, but not in `tree2`.  O(M + N)
    if tree1.isNil or tree2.isNil:
        result = tree1
    else:
        let (l, b, r) = split(tree2.key, tree1)
        discard b
        result = join(difference(l, tree2.left), difference(r, tree2.right))

func symmetricDifference*[K,V](tree1, tree2: BBTree[K,V]): BBTree[K,V] =
    ## Returns the symmetric set difference between `tree1` and `tree2`. In other words,
    ## returns the keys that are in `tree1`, but not in `tree2`, union the keys that are in
    ## `tree2` but not in `tree1`.  O(M + N)
    if tree1.isNil:
        result = tree2
    elif tree2.isNil:
        result = tree1
    else:
        let (l, b, r) = split(tree2.key, tree1)
        if b:
            result = join(symmetricDifference(l, tree2.left), symmetricDifference(r, tree2.right))
        else:
            result = join(tree2.key, tree2.val, symmetricDifference(l, tree2.left), symmetricDifference(r, tree2.right))

func contains*[K,V](root: BBTree[K,V], key: K): bool =
    ## Returns `true` if the `key` is in the tree `root`
    ## otherwise `false`. O(log N)
    result = false
    var node = root
    while (not node.isNil):
        let dif = cmp(key, node.key)
        if dif < 0:
            node = node.left
        elif dif > 0:
            node = node.right
        else: # key and node.key are eq
            result = true
            node = nil # break

func intersection*[K,V](tree1, tree2: BBTree[K,V]): BBTree[K,V] =
    ## Returns the set intersection of `tree1` and `tree2`. In other words, returns the keys
    ## that are in both trees.
    ## When viewed as maps, returns the key,value pairs for keys that appear in both trees;
    ## the value each key is selected from `tree1`, so
    ## this function is asymmetrical for maps. If you need more control over how the
    ## values are selected for duplicate keys, see `uintersectionMerge`. O(M + N)
    if tree1.isNil:
        result = tree1
    elif tree2.isNil:
        result = tree2
    else:
        let (l, b, r) = split(tree1.key, tree2)
        if b:
            result = join(tree1.key, tree1.val, intersection(tree1.left, l), intersection(tree1.right, r))
        else:
            result = join(intersection(tree1.left, l), intersection(tree1.right, r))

func intersectionMerge*[K,V](tree1, tree2: BBTree[K,V], merge: proc (k: K, v1, v2: V): V {.noSideEffect.}): BBTree[K,V] =
    ## Returns the set intersection of `tree1` and `tree2`. In other words, returns the keys
    ## that are in both trees.
    ## When viewed as maps, returns the key,value pairs for keys that appear in both trees;
    ## the value for each key is the result of the supplied
    ## `merge` function, which is passed the common key, and the values from `tree1` and
    ## `tree2` respectively.  O(M + N)
    if tree1.isNil:
        result = tree1
    elif tree2.isNil:
        result = tree2
    else:
        let (l, b, v, r) = splitMerge(tree1.key, tree2, merge)
        if b:
            result = join(tree1.key, v, intersectionMerge(tree1.left, l, merge), intersectionMerge(tree1.right, r, merge))
        else:
            result = join(intersectionMerge(tree1.left, l, merge), intersectionMerge(tree1.right, r, merge))

func isSubset*[K,U,V](tree1: BBTree[K,U], tree2: BBTree[K,V]): bool =
    ## Returns true iff the keys in `tree1` form a subset of the keys in `tree2`. In other words,
    ## if all the keys that are in `tree1` are also in `tree2`. O(N) where N is `len(tree1)`
    ## Use `isProperSubset` instead to determins that there are keys in `tree2` that are not in `tree1`.
    if tree1.isNil:
        result = true
    elif len(tree1) > len(tree2):
        result = false
    else:
        # tree2 is not nil or else the above length test would have been true
        let dif = cmp(tree1.key, tree2.key)
        if dif < 0:
            result = isSubset(tree1.left, tree2.left) and
                     tree2.contains(tree1.key) and
                     isSubset(tree1.right, tree2)
        elif dif > 0:
            result = isSubset(tree1.right, tree2.right) and
                     tree2.contains(tree1.key) and
                     isSubset(tree1.left, tree2)
        else: # tree1.key and tree2.key are eq
            result = isSubset(tree1.left, tree2.left) and isSubset(tree1.right, tree2.right)

func disjoint*[K,V](tree1, tree2: BBTree[K,V]): bool =
    ## Returns true iff `tree1` and `tree2` have no keys in common. O(N) where N is
    ## `len(tree1)`
    result = true # default
    if (not tree1.isNil) and (not tree2.isNil):
        let dif = cmp(tree1.key, tree2.key)
        if dif < 0:
            if not disjoint(tree1.left, tree2.left): return false
            if tree2.contains(tree1.key): return false
            return disjoint(tree1.right, tree2)
        elif dif > 0:
            if not disjoint(tree1.right, tree2.right): return false
            if tree2.contains(tree1.key): return false
            return disjoint(tree1.left, tree2)
        else: # tree1.key and tree2.key are eq
            return false

func isProperSubset*[K,U,V](tree1: BBTree[K,U], tree2: BBTree[K,V]): bool =
    ## Returns true iff the keys in `tree1` form a proper subset of the keys in `tree2`.
    ## In other words, if all the keys that are in `tree1` are also in `tree2`, but there are
    ## keys in `tree2` that are not in `tree1`.  O(N) where N is `len(tree1)`
    result = isSubset(tree1, tree2) and len(tree1) < len(tree2)

func setEqual*[K,U,V](tree1: BBTree[K,U], tree2: BBTree[K,V]): bool =
    ## Returns true if both `tree1` and `tree2` have the same keys.
    result = len(tree1) == len(tree2) and isSubset(tree1, tree2)

func `+`*[K,V](s1, s2: BBTree[K,V]): BBTree[K,V] {.inline.} =
    ## Alias for `union(s1, s2) <#union,BBTree[K,V],BBTree[K,V]>`_.
    result = union(s1, s2)

func `*`*[K,V](s1, s2: BBTree[K,V]): BBTree[K,V] {.inline.} =
    ## Alias for `intersection(s1, s2) <#intersection,BBTree[K,V],BBTree[K,V]>`_.
    result = intersection(s1, s2)

func `-`*[K,V](s1, s2: BBTree[K,V]): BBTree[K,V] {.inline.} =
    ## Alias for `difference(s1, s2) <#difference,BBTree[K,V],BBTree[K,V]>`_.
    result = difference(s1, s2)

# A -+- B  ==  (A - B) + (B - A)  ==  (A + B) - (A * B)

func `-+-`*[K,V](s1, s2: BBTree[K,V]): BBTree[K,V] {.inline.} =
    ## Alias for `symmetricDifference(s1, s2) <#symmetricDifference,BBTree[K,V],BBTree[K,V]>`_.
    result = symmetricDifference(s1, s2)

func `<`*[K,U,V](s1: BBTree[K,U], s2: BBTree[K,V]): bool {.inline.} =
    ## Alias for `isProperSubset(s1, s2) <#isProperSubset,BBTree[K,U],BBTree[K,V]>`_.
    ## Returns true if the keys in `s1` form a strict or proper subset of the keys in `s2`.
    ##
    ## A strict or proper subset `s1` has all of its keys in `s2` but `s2` has
    ## more elements than `s1`.
    result = isProperSubset(s1, s2)

func `<=`*[K,U,V](s1: BBTree[K,U], s2: BBTree[K,V]): bool {.inline.} =
    ## Alias for `isSubset(s1, s2) <#isSubset,BBTree[K,U],BBTree[K,V]>`_.
    ## Returns true if `s1` is subset of `s2`.
    ##
    ## A subset `s1` has all of its members in `ts2` and `s2` doesn't necessarily
    ## have more members than `s1`. That is, `s1` can be equal to `s2`.
    result = isSubset(s1, s2)

#[
#  `==` seems like an extreme assertion when values are not being considered...
#  but this would be consistent with Nim's set API. Punt for now; use =?= instead.
#
func `==`*[K,U,V](s1: BBTree[K,U], s2: BBTree[K,V]): bool {.inline.} =
    ## Returns true if both `s1` and `s2` have the same keys and set size.
    result = setEqual(s1, s2)
]#
func `=?=`*[K,U,V](s1: BBTree[K,U], s2: BBTree[K,V]): bool {.inline.} =
    ## Alias for `setEqual(s1, s2) <#setEqual,BBTree[K,U],BBTree[K,V]>`_.
    ## Returns true if both `s1` and `s2` have the same keys and set size.
    result = setEqual(s1, s2)

# Convenience functions

func toSet*[K](keys: openArray[K]): BBTree[K,bool] =
  ## Creates a BBTree set that contains the given `keys` with value `true`.
  ##
  ## Example:
  ##
  ## .. code-block::
  ##   var numbers : BBTree[int,bool] = toSet([1, 2, 3, 4, 5])
  ##   assert numbers.contains(2)
  ##   assert numbers.contains(4)
  result = nil
  for key in items(keys): result = insert(result, key, true)

# Unit test helpers

func countKeys*[K,V](root: BBTree[K,V]): int =
    ## Used for unit testing only; normally use `len` to get the number of keys.
    var node = root
    result = 0
    while (not node.isNil):
        result += countKeys(node.left)
        result += 1
        node = node.right

func balanced[K,V](node: BBTree[K,V]): int = # returns size in nodes or -1 for error
    if node.isNil:
        return 0
    let
        sl = nodeSize(node.left)
        sr = nodeSize(node.right)
        sz = nodeSize(node)
    if sz != (sl + 1 + sr):
        return -1
    if (sl + sr) <= 1:
        discard
    elif sr > (omega * sl):
        return -1
    elif sl > (omega * sr):
        return -1
    let
        slb = balanced(node.left)
        srb = balanced(node.right)
    if (slb < 0) or (sl != slb):
        return -1
    if (srb < 0) or (sr != srb):
        return -1
    return sz

func isBalanced*[K,V](root: BBTree[K,V]): bool =
    ## Used for unit testing only; returns `true` if the tree is balanced, which should always
    ## be the case.
    let size = balanced(root)
    if root.isNil:
        return (size == 0)
    return (size > 0) and (size == nodeSize(root))

# Sanity check

when isMainModule:

    proc test1() =
        var
            tre0 : BBTree[string,int] = nil
            tre1 = insert(tre0, "hello", 1)
            tre2 = insert(tre1, "world", 1)
        for str,num in pairs(tre2):
            stdout.writeLine(str)
    test1()
    echo "done"
