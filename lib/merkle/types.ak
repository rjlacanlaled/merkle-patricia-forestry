use aiken/merkle_patricia_forestry.{Proof}

pub type Fruit {
  color: ByteArray,
  taste: ByteArray,
  image: ByteArray,
  eaten: Bool,
}

pub type FruitTrie {
  key: ByteArray,
  value: Fruit,
}

pub type Datum {
  root: ByteArray,
}

pub type Redeemer {
  fruit: FruitTrie,
  proof: Proof,
}
