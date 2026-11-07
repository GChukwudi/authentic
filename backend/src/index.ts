import { buildApp } from './app.js';
import { MemoryChain } from './chain/memory.js';
import { SolanaChain } from './chain/solana.js';
import { loadConfig } from './config.js';
import { ScanStore } from './store.js';

const config = loadConfig();
const chain = config.chain === 'solana' ? SolanaChain.fromConfig(config) : new MemoryChain();
const store = new ScanStore(config.dbPath);
const app = buildApp({ config, chain, store });

await app.listen({ port: config.port, host: '0.0.0.0' });
console.log(`authentic backend on :${config.port} (chain: ${config.chain})`);
