import { AccessToken, DefaultAzureCredential } from '@azure/identity'
import sql from 'mssql'

const FABRIC_WORKSPACE_ID = process.env.FABRIC_WORKSPACE_ID
const FABRIC_LAKEHOUSE_ID = process.env.FABRIC_LAKEHOUSE_ID
const FABRIC_LAKEHOUSE_DATABASE = process.env.FABRIC_LAKEHOUSE_DATABASE ?? 'RoboticsOntologyLH'

const SQL_SCOPE = 'https://database.windows.net/.default'
const FABRIC_SCOPE = 'https://api.fabric.microsoft.com/.default'

// Recreate the pool before the SQL access token expires.
const TOKEN_REFRESH_SKEW_MS = 5 * 60_000

const credential = new DefaultAzureCredential({
  tenantId: process.env.AZURE_TENANT_ID,
})

let cachedSqlHost: string | undefined
let pool: sql.ConnectionPool | undefined
let sqlTokenExpiresOn = 0

async function getAccessToken(scope: string): Promise<AccessToken> {
  const accessToken = await credential.getToken(scope)
  if (!accessToken) {
    throw new Error(`Failed to acquire an access token for scope ${scope}`)
  }
  return accessToken
}

async function resolveSqlHost(): Promise<string> {
  if (cachedSqlHost) {
    return cachedSqlHost
  }

  const explicit = process.env.FABRIC_SQL_ENDPOINT
  if (explicit) {
    cachedSqlHost = explicit
    return cachedSqlHost
  }

  if (!FABRIC_WORKSPACE_ID || !FABRIC_LAKEHOUSE_ID) {
    throw new Error(
      'FABRIC_SQL_ENDPOINT, or both FABRIC_WORKSPACE_ID and FABRIC_LAKEHOUSE_ID, are required to resolve the lakehouse SQL endpoint',
    )
  }

  const { token } = await getAccessToken(FABRIC_SCOPE)
  const url = `https://api.fabric.microsoft.com/v1/workspaces/${FABRIC_WORKSPACE_ID}/lakehouses/${FABRIC_LAKEHOUSE_ID}`
  const response = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  })
  if (!response.ok) {
    throw new Error(`Fabric lakehouse lookup failed: ${response.status} ${response.statusText}`)
  }

  const body = (await response.json()) as {
    properties?: { sqlEndpointProperties?: { connectionString?: string } }
  }
  const host = body.properties?.sqlEndpointProperties?.connectionString
  if (!host) {
    throw new Error('Fabric lakehouse response did not include properties.sqlEndpointProperties.connectionString')
  }

  cachedSqlHost = host
  return cachedSqlHost
}

async function getPool(): Promise<sql.ConnectionPool> {
  const now = Date.now()
  if (pool?.connected && now < sqlTokenExpiresOn - TOKEN_REFRESH_SKEW_MS) {
    return pool
  }

  if (pool) {
    await pool.close().catch(() => undefined)
    pool = undefined
  }

  const host = await resolveSqlHost()
  const accessToken = await getAccessToken(SQL_SCOPE)
  sqlTokenExpiresOn = accessToken.expiresOnTimestamp

  pool = await new sql.ConnectionPool({
    server: host,
    port: 1433,
    database: FABRIC_LAKEHOUSE_DATABASE,
    options: { encrypt: true, trustServerCertificate: false },
    authentication: {
      type: 'azure-active-directory-access-token',
      options: { token: accessToken.token },
    },
  }).connect()

  return pool
}

export interface RobotRecord {
  Id: string
  Name: string
  Description: string | null
}

export interface RobotPoseRecord {
  Robot: string
  X: number
  Y: number
  Z: number
  Roll: number
  Pitch: number
  Yaw: number
  Timestamp: string | null
}

export async function listRobots(): Promise<RobotRecord[]> {
  const conn = await getPool()
  const result = await conn
    .request()
    .query<RobotRecord>('SELECT Id, Name, Description FROM dbo.robot ORDER BY Name')
  return result.recordset
}

export async function getRobotPose(robotName: string): Promise<RobotPoseRecord | undefined> {
  const conn = await getPool()
  const result = await conn
    .request()
    .input('robotName', sql.NVarChar, robotName)
    .query<RobotPoseRecord>(
      `SELECT r.Name AS Robot, p.X, p.Y, p.Z, p.Roll, p.Pitch, p.Yaw, p.Timestamp
       FROM dbo.robot r
       JOIN dbo.robot_posemeasure rel ON rel.FromId = r.Id
       JOIN dbo.posemeasure p ON p.Id = rel.ToId
       WHERE r.Name = @robotName`,
    )
  return result.recordset[0]
}
