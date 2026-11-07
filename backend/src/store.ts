import { DatabaseSync } from 'node:sqlite';

export interface ScanResult {
  count: number;
  /** Time of the scan before this one, if any. */
  previousAt: number | null;
  /** Distinct clients that have scanned this unit, including this one. */
  distinctClients: number;
  /** Scans of this unit in the last hour, including this one. */
  lastHour: number;
}

/** Scan counters and events. SQLite, one file. */
export class ScanStore {
  private db: DatabaseSync;

  constructor(path: string) {
    this.db = new DatabaseSync(path);
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS scans (
        batch_ref TEXT NOT NULL,
        serial INTEGER NOT NULL,
        client TEXT NOT NULL,
        at INTEGER NOT NULL
      );
      CREATE INDEX IF NOT EXISTS scans_unit ON scans (batch_ref, serial);
    `);
  }

  record(batchRef: string, serial: number, client: string, at = Date.now()): ScanResult {
    const prev = this.db
      .prepare('SELECT MAX(at) AS at FROM scans WHERE batch_ref = ? AND serial = ?')
      .get(batchRef, serial) as { at: number | null };
    this.db
      .prepare('INSERT INTO scans (batch_ref, serial, client, at) VALUES (?, ?, ?, ?)')
      .run(batchRef, serial, client, at);
    const agg = this.db
      .prepare(
        `SELECT COUNT(*) AS count, COUNT(DISTINCT client) AS clients,
                SUM(CASE WHEN at > ? THEN 1 ELSE 0 END) AS hour
         FROM scans WHERE batch_ref = ? AND serial = ?`,
      )
      .get(at - 3_600_000, batchRef, serial) as {
      count: number;
      clients: number;
      hour: number;
    };
    return {
      count: agg.count,
      previousAt: prev.at,
      distinctClients: agg.clients,
      lastHour: agg.hour,
    };
  }

  unitsScanned(batchRef: string): number {
    const row = this.db
      .prepare('SELECT COUNT(DISTINCT serial) AS n FROM scans WHERE batch_ref = ?')
      .get(batchRef) as { n: number };
    return row.n;
  }

  close() {
    this.db.close();
  }
}
