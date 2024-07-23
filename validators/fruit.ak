use aiken/bytearray
use aiken/cbor
use aiken/hash
use aiken/merkle_patricia_forestry.{Branch, Proof} as mpf
use aiken/string
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, ScriptContext, Spend, Transaction,
  TransactionId,
}
use aiken/transaction/credential
use aiken/transaction/value

type Fruit {
  color: ByteArray,
  taste: ByteArray,
  image: ByteArray,
  eaten: Bool,
}

type FruitTrie {
  key: ByteArray,
  value: Fruit,
}

type Datum {
  root: ByteArray,
}

type Redeemer {
  fruit: FruitTrie,
  proof: mpf.Proof,
}

validator {
  fn eat(datum: Datum, redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    // Generate the trie from the root
    let trie = mpf.from_root(datum.root)
    let fruit = redeemer.fruit.value

    // Serialise the fruit
    let fruit_str =
      bytearray.concat("{\"color\":\"", fruit.color)
        |> bytearray.concat("\",\"taste\":\"")
        |> bytearray.concat(fruit.taste)
        |> bytearray.concat("\",\"image\":\"")
        |> bytearray.concat(fruit.image)
        |> bytearray.concat("\",\"eaten\":")
        |> bytearray.concat(
            if fruit.eaten {
              "true"
            } else {
              "false"
            },
          )
        |> bytearray.concat("}")

    // Check if the fruit is included in the trie
    let included = mpf.has(trie, redeemer.fruit.key, fruit_str, redeemer.proof)

    // Eat the fruit
    let consumed_fruit_str =
      bytearray.concat("{\"color\":\"", fruit.color)
        |> bytearray.concat("\",\"taste\":\"")
        |> bytearray.concat(fruit.taste)
        |> bytearray.concat("\",\"image\":\"")
        |> bytearray.concat(fruit.image)
        |> bytearray.concat("\",\"eaten\":")
        |> bytearray.concat("true")
        |> bytearray.concat("}")

    let updated_trie =
      trie
        |> mpf.delete(redeemer.fruit.key, fruit_str, redeemer.proof)
        |> mpf.insert()

    and {
      !fruit.eaten,
      included,
    }
  }
}

test prove_apple() {
  let datum =
    Datum {
      root: #"932a38364af923e6489e9c04f3c1783c8de79506173e38d4d40383a47be36772",
    }

  let apple =
    Fruit { color: "red", taste: "sweet", image: "🍎", eaten: False }

  let apple_key = "apple"

  let apple_trie = FruitTrie { key: apple_key, value: apple }

  let proof: Proof =
    [
      Branch {
        skip: 0,
        neighbors: #"97fbec1b1e3c6cc814853bca569e8cd087beedd69690cdc549d3ffc9cb488545ecdf4dc40626d7d19b59d482e2b25211ad24f6cd63e6d7dd1e96e8858727b353e592572c51fe6e71c88c4c10469cf9dfe4c4f91458b7837f18ba7804595ca1c90000000000000000000000000000000000000000000000000000000000000000",
      },
    ]

  let redeemer = Redeemer { fruit: apple_trie, proof }

  let transaction =
    transaction.placeholder()
      |> fn(tx) { Transaction { ..tx, outputs: [] } }

  let spend_ref: OutputReference =
    OutputReference {
      transaction_id: TransactionId { hash: #"00" },
      output_index: 0,
    }

  let spend_input =
    Input {
      output_reference: spend_ref,
      output: Output {
        address: credential.from_verification_key(#"00000000000001"),
        value: value.from_lovelace(10_000),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  let updated_datum =
    Datum {
      root: #"932a38364af923e6489e9c04f3c1783c8de79506173e38d4d40383a47be36772",
    }

  let updated_utxo =
    Output {
      address: credential.from_verification_key(#"00000000000001"),
      value: value.from_lovelace(30_000),
      datum: InlineDatum(updated_datum),
      reference_script: None,
    }

  let context = ScriptContext { purpose: Spend(spend_ref), transaction }
  eat(datum, redeemer, context)
}
