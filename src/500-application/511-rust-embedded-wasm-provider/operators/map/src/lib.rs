// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

#![allow(clippy::missing_safety_doc)]

mod custom_wit {
    wit_bindgen::generate!({
        path: "wit/custom.wit",
        world: "custom-impl",
    });

    pub use map::custom::custom::{init, process};
    pub use map::custom::types::{DataModel, Error, ModuleConfiguration};
}

mod map_custom {
    use wasm_graph_sdk::logger::{self, Level};
    use wasm_graph_sdk::macros::map_operator;

    fn decode_and_rescale_init(configuration: ModuleConfiguration) -> bool {
        logger::log(
            Level::Info,
            "module-format/map",
            "Initialization function invoked",
        );

        let custom_config = crate::custom_wit::ModuleConfiguration {
            properties: configuration
                .properties
                .iter()
                .map(|(k, v)| (k.clone(), v.clone()))
                .collect(),
        };
        crate::custom_wit::init(&custom_config)
    }

    #[map_operator(init = "decode_and_rescale_init")]
    fn decode_and_rescale(input: DataModel) -> Result<DataModel, Error> {
        logger::log(
            Level::Info,
            "module-format/map",
            "Map function invoked",
        );
        let (payload, message_opt) = match input {
            DataModel::Message(msg) => {
                let payload = match &msg.payload {
                    BufferOrBytes::Buffer(buf) => buf.read(),
                    BufferOrBytes::Bytes(bytes) => bytes.clone(),
                };
                (payload, Some(msg))
            }
            DataModel::BufferOrBytes(bob) => {
                let payload = match bob {
                    BufferOrBytes::Buffer(buf) => buf.read(),
                    BufferOrBytes::Bytes(bytes) => bytes.clone(),
                };
                (payload, None)
            }
            _ => (vec![], None),
        };

        let custom_input = crate::custom_wit::DataModel { payload };

        let result = crate::custom_wit::process(&custom_input).map_err(|e| {
            let message = match e {
                crate::custom_wit::Error::InvalidArgument(s) => s,
                crate::custom_wit::Error::Internal(s) => s,
            };
            Error { message }
        })?;

        if let Some(msg) = message_opt {
            Ok(DataModel::Message(Message {
                timestamp: msg.timestamp,
                topic: msg.topic,
                payload: BufferOrBytes::Bytes(result.payload),
                properties: msg.properties,
                content_type: msg.content_type,
                schema: msg.schema,
            }))
        } else {
            Ok(DataModel::BufferOrBytes(BufferOrBytes::Bytes(
                result.payload,
            )))
        }
    }
}
