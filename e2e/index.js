import { Trie } from '@aiken-lang/merkle-patricia-forestry';

const trie = new Trie();

const items = [
    { 
      key: 'apple', 
      value: {
        color: 'red',
        taste: 'sweet',
        image: '🍎',
        eaten: false,
      }
    },
    {
      key: 'banana', 
      value: {
        color: 'yellow',
        taste: 'sweet',
        image: '🍌',
        eaten: false,
      }
    },
    {
      key: 'cherry',
      value: {
        color: 'red',
        taste: 'sweet',
        image: '🍒',
        eaten: false,
      }
    },
    {
      key: 'date',
      value: {
        color: 'brown',
        taste: 'sweet',
        image: '🪀',
        eaten: false,
      }
    },
    {
      key: 'elderberry',
      value: {
        color: 'purple',
        taste: 'sour',
        image: '🫐',
        eaten: false,
      }
    },
    {
      key: 'fig',
      value: {
        color: 'purple',
        taste: 'sweet',
        image: '🫒',
        eaten: false,
      }
    },
    {
      key: 'grape',
      value: {
        color: 'green',
        taste: 'sweet',
        image: '🍇',
        eaten: false,
      }
    },
    {
      key: 'honeydew',
      value: {
        color: 'green',
        taste: 'sweet',
        image: '🍈',
        eaten: false,
      }
    },
    {
      key: 'kiwi',
      value: {
        color: 'brown',
        taste: 'sour',
        image: '🥝',
        eaten: false,
      }
    },
    {
      key: 'lemon',
      value: {
        color: 'yellow',
        taste: 'sour',
        image: '🍋',
        eaten: false,
      }
    },
    {
      key: 'mango',
      value: {
        color: 'orange',
        taste: 'sweet',
        image: '🥭',
        eaten: false,
      }
    },
    {
      key: 'nectarine',
      value: {
        color: 'orange',
        taste: 'sweet',
        image: '🍑',
        eaten: false,
      }
    },
    {
      key: 'orange',
      value: {
        color: 'orange',
        taste: 'sweet',
        image: '🍊',
        eaten: false,
      }
    },
    {
      key: 'pear',
      value: {
        color: 'green',
        taste: 'sweet',
        image: '🍐',
        eaten: false,
      }
    },
  ];
  
await items.reduce(async (trie, { key, value }) => {
  console.log("key", key);
  console.log("value", Buffer.from(JSON.stringify(value), 'utf-8').toString('hex'));
  return (await trie).insert(key, Buffer.from(JSON.stringify(value), 'utf-8'));
}, trie);

// apple -> buffer of value

await trie.fetchChildren(10);

const proofApple = await trie.prove('apple');
const proofAppleJson = proofApple.toJSON();
const proofAppleCbor = proofApple.toCBOR();
const proofAppleAiken = proofApple.toAiken();

// address1 -> { amount: 100, claimed: false }
// address2 -> { amount: 100, claimed: false }

console.log("Trie:");
console.log(Buffer.from(trie.hash, 'hex').toString('hex'));
console.log(trie);
console.log("====================================\n");

console.log("Proof verification for apple:");
console.log(proofApple.verify().equals(trie.hash));
console.log("====================================\n");

console.log("JSON proof:");
console.log(proofAppleJson);
console.log("====================================\n");

console.log("CBOR proof:");
console.log(proofAppleCbor.toString('hex'));
console.log("====================================\n");

console.log("Aiken proof:");
console.log(proofAppleAiken);
console.log("====================================\n");

// Update the value of apple
const updatedValue = {
  color: 'red',
  taste: 'sweet',
  image: '🍎',
  eaten: true,
};

await trie.delete('apple');
await trie.insert('apple', Buffer.from(JSON.stringify(updatedValue), 'utf-8'));

const proofAppleUpdated = await trie.prove('apple');
const proofAppleUpdatedJson = proofAppleUpdated.toJSON();
const proofAppleUpdatedCbor = proofAppleUpdated.toCBOR();
const proofAppleUpdatedAiken = proofAppleUpdated.toAiken();

console.log("====================================\n");
console.log("Trie after update:");
console.log(Buffer.from(trie.hash, 'hex').toString('hex'));
console.log(trie);
console.log("====================================\n");

console.log("Proof verification for apple after update:");
console.log(proofAppleUpdated.verify().equals(trie.hash));
console.log("====================================\n");

console.log("JSON proof after update:");
console.log(proofAppleUpdatedJson);
console.log("====================================\n");

console.log("CBOR proof after update:");
console.log(proofAppleUpdatedCbor.toString('hex'));
console.log("====================================\n");

console.log("Aiken proof after update:");
console.log(proofAppleUpdatedAiken);
console.log("====================================\n");