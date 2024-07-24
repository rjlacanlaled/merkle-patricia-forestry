use aiken/bytearray
use aiken/list
use aiken/merkle_patricia_forestry.{Branch, Proof} as mpf
use aiken/transaction.{
  InlineDatum, Input, Output, OutputReference, ScriptContext, Spend, Transaction,
  TransactionId,
}
use aiken/transaction/credential.{ScriptCredential}
use aiken/transaction/value
use merkle/types.{Datum, Fruit, FruitTrie, Redeemer}
use merkle/utils

validator {
  fn eat(datum: Datum, redeemer: Redeemer, ctx: ScriptContext) -> Bool {
    let ScriptContext { transaction, purpose } = ctx
    expect Spend(self) = purpose

    // Get the output sent back to the validator
    expect Some(self_input) = transaction.inputs |> transaction.find_input(self)
    expect ScriptCredential(script_hash) =
      self_input.output.address.payment_credential
    expect Some(self_output) =
      transaction.outputs
        |> transaction.find_script_outputs(script_hash)
        |> list.head()

    // Generate the trie from the root
    let trie = mpf.from_root(datum.root)
    let fruit = redeemer.fruit.value

    // Serialise the fruit
    let fruit_value =
      bytearray.concat("{\"color\":\"", fruit.color)
        |> bytearray.concat("\",\"taste\":\"")
        |> bytearray.concat(fruit.taste)
        |> bytearray.concat("\",\"image\":\"")
        |> bytearray.concat(fruit.image)
        |> bytearray.concat("\",\"eaten\":")
        |> bytearray.concat("false")
        |> bytearray.concat("}")

    // Check if the fruit is included in the trie
    let included =
      mpf.has(trie, redeemer.fruit.key, fruit_value, redeemer.proof)

    // Eat the fruit
    let consumed_fruit_value =
      bytearray.concat("{\"color\":\"", fruit.color)
        |> bytearray.concat("\",\"taste\":\"")
        |> bytearray.concat(fruit.taste)
        |> bytearray.concat("\",\"image\":\"")
        |> bytearray.concat(fruit.image)
        |> bytearray.concat("\",\"eaten\":")
        |> bytearray.concat("true")
        |> bytearray.concat("}")

    // Update the trie
    // delete old entry -> provide proof 
    // insert new entry -> updated entry proof (needs effort)
    // updated root hash 
    let updated_trie =
      trie
        |> mpf.update(
            redeemer.fruit.key,
            redeemer.proof,
            fruit_value,
            consumed_fruit_value,
          )

    expect InlineDatum(self_output_datum) = self_output.datum
    let Datum { root } = utils.to_datum(self_output_datum)
    let returned_trie = mpf.from_root(root)

    // Compare the updated trie onchain with the trie on the updated
    // output datum
    let correct_updated_trie = updated_trie == returned_trie

    and {
      !fruit.eaten,
      included,
      correct_updated_trie,
    }
  }
}

test update_apple_correct_root_hash() {
  let script_credential =
    credential.from_script(
      #"ea0698aec4a23c10e935c03e6fc30ab9e51a8171fe03d8ccde7db3a7",
    )
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

  let updated_datum =
    Datum {
      root: #"8a8edb3b092018ca45b5bf427e1d24a1badca87808c9959581d1255cc0fc5e03",
    }

  let spend_ref: OutputReference =
    OutputReference {
      transaction_id: TransactionId { hash: #"00" },
      output_index: 0,
    }

  let updated_utxo =
    Output {
      address: script_credential,
      value: value.from_lovelace(30_000),
      datum: InlineDatum(updated_datum),
      reference_script: None,
    }

  let spend_input =
    Input {
      output_reference: spend_ref,
      output: Output {
        address: script_credential,
        value: value.from_lovelace(10_000),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  let transaction =
    transaction.placeholder()
      |> fn(tx) {
          Transaction { ..tx, outputs: [updated_utxo], inputs: [spend_input] }
        }

  let context = ScriptContext { purpose: Spend(spend_ref), transaction }
  eat(datum, redeemer, context)
}

test update_apple_incorrect_root_hash() fail {
  let script_credential =
    credential.from_script(
      #"ea0698aec4a23c10e935c03e6fc30ab9e51a8171fe03d8ccde7db3a7",
    )
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

  let updated_datum =
    Datum {
      root: #"7a8edb3b092018ca45b5bf427e1d24a1badca87808c9959581d1255cc0fc5e03",
    }

  let spend_ref: OutputReference =
    OutputReference {
      transaction_id: TransactionId { hash: #"00" },
      output_index: 0,
    }

  let updated_utxo =
    Output {
      address: script_credential,
      value: value.from_lovelace(30_000),
      datum: InlineDatum(updated_datum),
      reference_script: None,
    }

  let spend_input =
    Input {
      output_reference: spend_ref,
      output: Output {
        address: script_credential,
        value: value.from_lovelace(10_000),
        datum: InlineDatum(datum),
        reference_script: None,
      },
    }

  let transaction =
    transaction.placeholder()
      |> fn(tx) {
          Transaction { ..tx, outputs: [updated_utxo], inputs: [spend_input] }
        }

  let context = ScriptContext { purpose: Spend(spend_ref), transaction }
  eat(datum, redeemer, context)
}
