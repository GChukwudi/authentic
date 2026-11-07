// One-time: creates the registry account with the relayer as admin.
//   CHAIN=solana RELAYER_KEYPAIR=./relayer.json npm run init-registry
import { loadConfig } from '../src/config.js';
import { SolanaChain } from '../src/chain/solana.js';

const config = loadConfig();
const chain = SolanaChain.fromConfig({ ...config, chain: 'solana' });
await chain.initialize();
console.log('registry initialised on', config.rpcUrl);
