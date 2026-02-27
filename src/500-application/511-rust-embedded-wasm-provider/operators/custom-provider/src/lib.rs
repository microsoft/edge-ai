// Copyright (c) Microsoft Corporation.
// Licensed under the MIT License.

#![allow(clippy::missing_safety_doc)]

wit_bindgen::generate!({
    path: "wit/custom.wit",
    world: "custom-provider",
});

use exports::map::custom::custom::{DataModel, Error, Guest, ModuleConfiguration};
use wasm_graph_sdk::logger::{self, Level};

struct CustomProvider;

impl Guest for CustomProvider {
    fn init(configuration: ModuleConfiguration) -> bool {
        logger::log(
            Level::Info,
            "module-custom/provider",
            "Initialization function invoked",
        );
        for (key, value) in &configuration.properties {
            let _ = (key, value);
        }
        true
    }

    fn process(message: DataModel) -> Result<DataModel, Error> {
        logger::log(
            Level::Info,
            "module-custom/provider",
            "Process function invoked",
        );
        Ok(DataModel {
            payload: message.payload,
        })
    }
}

export!(CustomProvider);
