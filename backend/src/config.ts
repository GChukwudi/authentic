export interface Config {
  port: number;
  chain: 'memory' | 'solana';
  rpcUrl: string;
  programId: string;
  relayerKeypair: string; // path to a Solana keypair JSON, or the JSON array itself
  dbPath: string;
  anthropicKey: string | undefined;
  anthropicModel: string;
  maxSkewMs: number;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): Config {
  const chain = env.CHAIN === 'solana' ? 'solana' : 'memory';
  return {
    port: Number(env.PORT ?? 8787),
    chain,
    rpcUrl: env.RPC_URL ?? 'https://api.devnet.solana.com',
    programId: env.PROGRAM_ID ?? '',
    relayerKeypair: env.RELAYER_KEYPAIR ?? '',
    dbPath: env.DB_PATH ?? 'authentic.db',
    anthropicKey: env.ANTHROPIC_API_KEY || undefined,
    anthropicModel: env.ANTHROPIC_MODEL ?? 'claude-haiku-5-5',
    maxSkewMs: Number(env.AUTH_MAX_SKEW_MS ?? 5 * 60 * 1000),
  };
}
