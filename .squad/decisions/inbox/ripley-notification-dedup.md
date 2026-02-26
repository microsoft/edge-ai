# Decision: Notification Deduplication via Table Storage

**Author:** Ripley (Infra Developer)
**Date:** 2026-02-26
**Status:** Implemented

## Context

The existing Logic App used `splitOn` on the Event Hub trigger, which fired a separate workflow run for every event. This flooded the Teams channel with duplicate notifications for the same leak device.

## Decision

Replace `splitOn` with a `For_Each` loop that checks Azure Table Storage for an existing active leak session before posting to Teams. Only new leaks trigger a notification; existing leaks get their session counters updated.

A second Logic App provides an HTTP endpoint to close active leak sessions, with a "Close Leak" link embedded in the initial Teams notification.

## Key Implementation Details

- Table `leaksessions` on the existing storage account (from `cloud_data` module)
- PartitionKey = `source_device`, RowKey = `active`
- `For_Each` with `operationOptions = "Sequential"` prevents race conditions
- `Get_Active_Leak` action: 404 → new leak (insert + notify), 200 → existing leak (update counters)
- Close Logic App: HTTP GET trigger, deletes table entity, posts closure summary to Teams
- Close callback URL obtained via `azapi_resource_action` calling `listCallbackUrl`
- Both Logic Apps share the same API connections but have independent managed identities

## Consequences

- Teams notifications are deduplicated per device — one alert per leak, not per event
- Operators can close leaks via a single click in the Teams notification
- New dependency on `storage_account` variable from `cloud_data` module
- Table Storage API connection requires managed identity authentication
