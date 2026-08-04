//! Status and health-event reporting helpers shared across the device endpoint,
//! asset, and dataset lifecycle.
//!
//! The SDK's `report_*_status_if_modified` methods take a `Fn(Option<Result<(), &E>>)
//! -> Option<Result<(), E>>` closure and internally decide whether the candidate
//! status actually differs from what's already reported, skipping the network call
//! when it doesn't. [`report_if_changed`] adapts a single candidate status value
//! into that closure shape.

use azure_iot_operations_connector::AdrConfigError;

/// Builds a closure suitable for any `report_*_status_if_modified` call that
/// reports `new_status` the first time (`current` is `None`) or whenever it
/// differs from the currently reported status, and otherwise reports nothing.
pub fn report_if_changed(
    new_status: Result<(), AdrConfigError>,
) -> impl Fn(Option<Result<(), &AdrConfigError>>) -> Option<Result<(), AdrConfigError>> {
    move |current| {
        let changed = match (current, &new_status) {
            (None, _) => true,
            (Some(Ok(())), Ok(())) => false,
            (Some(Err(current_err)), Err(new_err)) => current_err != new_err,
            _ => true,
        };
        changed.then(|| new_status.clone())
    }
}

/// A healthy status with no configuration error.
pub fn ok_status() -> Result<(), AdrConfigError> {
    Ok(())
}

/// A configuration-error status carrying a human-readable message.
pub fn error_status(message: impl Into<String>) -> Result<(), AdrConfigError> {
    Err(AdrConfigError {
        message: Some(message.into()),
        ..Default::default()
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reports_ok_status_the_first_time() {
        let modify = report_if_changed(ok_status());
        assert_eq!(modify(None), Some(Ok(())));
    }

    #[test]
    fn skips_reporting_when_status_unchanged() {
        let modify = report_if_changed(ok_status());
        assert_eq!(modify(Some(Ok(()))), None);
    }

    #[test]
    fn reports_when_transitioning_from_ok_to_error() {
        let modify = report_if_changed(error_status("boom"));
        assert!(modify(Some(Ok(()))).is_some());
    }

    #[test]
    fn skips_reporting_when_error_message_unchanged() {
        let modify = report_if_changed(error_status("boom"));
        let existing = error_status("boom").unwrap_err();
        assert_eq!(modify(Some(Err(&existing))), None);
    }

    #[test]
    fn reports_when_error_message_changes() {
        let modify = report_if_changed(error_status("new failure"));
        let existing = error_status("old failure").unwrap_err();
        assert!(modify(Some(Err(&existing))).is_some());
    }
}
