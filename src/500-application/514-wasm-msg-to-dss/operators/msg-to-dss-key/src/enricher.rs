use serde_json::{json, Value};
use wasm_graph_sdk::macros::map_operator;
use wasm_graph_sdk::state_store;

#[map_operator]
fn pallet_correlator_enricher(input: DataModel) -> Result<DataModel, Error> {
    let DataModel::Message(ref message) = input else {
        return Ok(input);
    };

    let payload = match &message.payload {
        BufferOrBytes::Buffer(buffer) => buffer.read(),
        BufferOrBytes::Bytes(bytes) => bytes.clone(),
    };

    let json_str = match std::str::from_utf8(&payload) {
        Ok(s) => s,
        Err(e) => return Err(Error { message: format!("UTF-8 error: {}", e) }),
    };
    let mut consumption: Value = match serde_json::from_str(json_str) {
        Ok(v) => v,
        Err(e) => return Err(Error { message: format!("JSON parse error: {}", e) }),
    };

    // Extract pallet_ids array
    let pallet_ids: Vec<String> = consumption
        .get("pallet_ids")
        .and_then(|v: &Value| v.as_array())
        .map(|arr: &Vec<Value>| arr.iter().filter_map(|v: &Value| v.as_str().map(String::from)).collect())
        .unwrap_or_default();

    let event_timestamp_str = consumption
        .get("event_timestamp")
        .and_then(|v: &Value| v.as_str())
        .unwrap_or("")
        .to_string();

    let mut all_found = true;
    let mut pallets_info = Vec::new();

    for pallet_id in &pallet_ids {
        let key = format!("pallet:{}", pallet_id);
        match state_store::get(key.as_bytes(), None) {
            Ok(resp) => match resp.response {
                Some(bytes) => {
                    if let Ok(creation_str) = std::str::from_utf8(&bytes) {
                        if let Ok(creation) = serde_json::from_str::<Value>(creation_str) {
                            let production_date = creation
                                .get("production_date")
                                .and_then(|v: &Value| v.as_str())
                                .unwrap_or("");

                            let (aging_days, aging_hours) =
                                compute_aging(production_date, &event_timestamp_str);

                            pallets_info.push(json!({
                                "pallet_id": pallet_id,
                                "production_date": production_date,
                                "production_machine": creation.get("machine_id").and_then(|v: &Value| v.as_str()).unwrap_or(""),
                                "quality_grade": creation.get("quality_grade").and_then(|v: &Value| v.as_str()).unwrap_or(""),
                                "version_code": creation.get("version_code").and_then(|v: &Value| v.as_str()).unwrap_or(""),
                                "production_quantity_kg": creation.get("quantity_kg").and_then(|v: &Value| v.as_f64()).unwrap_or(0.0),
                                "aging_days": aging_days,
                                "aging_hours": aging_hours,
                            }));
                        } else {
                            all_found = false;
                            pallets_info.push(json!({ "pallet_id": pallet_id, "found": false }));
                        }
                    } else {
                        all_found = false;
                        pallets_info.push(json!({ "pallet_id": pallet_id, "found": false }));
                    }
                }
                None => {
                    all_found = false;
                    pallets_info.push(json!({ "pallet_id": pallet_id, "found": false }));
                }
            },
            Err(_) => {
                all_found = false;
                pallets_info.push(json!({ "pallet_id": pallet_id, "found": false }));
            }
        }
    }

    let any_found = pallets_info.iter().any(|p| p.get("found").is_none());
    let status = if all_found {
        "correlated"
    } else if any_found {
        "partial"
    } else {
        "uncorrelated"
    };

    consumption["correlation"] = json!({
        "status": status,
        "pallets": pallets_info,
    });

    // Serialize enriched JSON and create new message
    let enriched_bytes = match serde_json::to_vec(&consumption) {
        Ok(b) => b,
        Err(e) => return Err(Error { message: format!("JSON serialize error: {}", e) }),
    };

    // Build a new Message with enriched payload, preserving original metadata
    let topic = match &message.topic {
        BufferOrBytes::Buffer(buffer) => BufferOrBytes::Bytes(buffer.read()),
        BufferOrBytes::Bytes(bytes) => BufferOrBytes::Bytes(bytes.clone()),
    };

    let content_type = message.content_type.as_ref().map(|ct| match ct {
        BufferOrString::Buffer(buffer) => BufferOrString::String(String::from_utf8_lossy(&buffer.read()).into_owned()),
        BufferOrString::String(s) => BufferOrString::String(s.clone()),
    });

    let user_props = message.properties.user_properties.iter().map(|(k, v)| {
        let key = match k {
            BufferOrString::Buffer(buf) => BufferOrString::String(String::from_utf8_lossy(&buf.read()).into_owned()),
            BufferOrString::String(s) => BufferOrString::String(s.clone()),
        };
        let val = match v {
            BufferOrString::Buffer(buf) => BufferOrString::String(String::from_utf8_lossy(&buf.read()).into_owned()),
            BufferOrString::String(s) => BufferOrString::String(s.clone()),
        };
        (key, val)
    }).collect();

    let new_message = Message {
        timestamp: Timestamp {
            timestamp: message.timestamp.timestamp,
            counter: message.timestamp.counter,
            node_id: match &message.timestamp.node_id {
                BufferOrString::Buffer(buf) => BufferOrString::String(String::from_utf8_lossy(&buf.read()).into_owned()),
                BufferOrString::String(s) => BufferOrString::String(s.clone()),
            },
        },
        topic,
        content_type,
        payload: BufferOrBytes::Bytes(enriched_bytes),
        properties: MessageProperties { user_properties: user_props },
        schema: None,
    };

    Ok(DataModel::Message(new_message))
}

/// Compute aging between two ISO 8601 date strings.
/// Uses manual parsing to avoid chrono dependency (WASM compatibility — DR-01).
/// Returns (aging_days, aging_hours). Returns (0, 0) on parse failure.
fn compute_aging(production_date: &str, event_timestamp: &str) -> (i64, i64) {
    let prod_date = &production_date.get(..10).unwrap_or("");
    let event_date = &event_timestamp.get(..10).unwrap_or("");

    let prod_days = parse_date_to_days(prod_date);
    let event_days = parse_date_to_days(event_date);

    match (prod_days, event_days) {
        (Some(p), Some(e)) => {
            let days = e - p;
            let prod_hour = parse_hour(production_date);
            let event_hour = parse_hour(event_timestamp);
            let hours = days * 24 + (event_hour - prod_hour);
            (days, hours)
        }
        _ => (0, 0),
    }
}

fn parse_date_to_days(date_str: &str) -> Option<i64> {
    let parts: Vec<&str> = date_str.split('-').collect();
    if parts.len() != 3 { return None; }
    let year: i64 = parts[0].parse().ok()?;
    let month: i64 = parts[1].parse().ok()?;
    let day: i64 = parts[2].parse().ok()?;
    Some(year * 365 + (year / 4) - (year / 100) + (year / 400) + month * 30 + day)
}

fn parse_hour(timestamp: &str) -> i64 {
    timestamp
        .find('T')
        .and_then(|t_pos| timestamp.get(t_pos + 1..t_pos + 3))
        .and_then(|h| h.parse::<i64>().ok())
        .unwrap_or(0)
}
