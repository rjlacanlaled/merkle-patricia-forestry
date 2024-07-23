use aiken/merkle_patricia_forestry.{MerklePatriciaForestry, Proof}

/// **fails** when | the [Proof](#Proof) is invalid
/// ---            | ---
/// **fails** when | there's no element in the trie at the given key
/// ---            | ---
///
/// Update an element in the trie with a a new value. This requires a [Proof](#Proof)
/// of the old element, to ensure its in the list, and a [Proof](#Proof) of the new
/// element, to re-add it.
///
/// Can be thought of as a delete, followed by an insert, but is able to do it with one fewer
/// membership checks
pub fn update(
  self: MerklePatriciaForestry,
  key: ByteArray,
  proof: Proof,
  old_value: ByteArray,
  new_value: ByteArray,
) {
  expect including(key, old_value, proof) == self.root
  // If we were doing a delete followed by an insert, we'd end up checking the `excluding` again here
  MerklePatriciaForestry { root: including(key, new_value, proof) }
}
