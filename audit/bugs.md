# Bugs and Issues

## From PAGES_REAL_API_STATUS.md
- **Contact Form Attachment Missing:** The endpoint for uploading an attachment exists in the portal (`contact/upload/attachment`), but the current build sends the form without an attachment.
- **Alert Configurations Validation:** Activation requires email/phone in the mobile dialog; this needs to be validated with the actual account responses for each alert type.
- **Index Transmission Timing:** The payload is taken from the real EMSYS row and sent to `transmitere/add`; this must be tested only during a period when the portal allows index transmission.
- **Unused API Placeholder:** `ApiACIRepository` still contains TODOs for the future official API and is not used in the current build.

## From THREAT_MODEL.md
- **Missing TLS Pinning:** Temporarily accepted due to certificate rotation and Cloudflare usage, but poses a risk.
- **Reliance on Internal REST Endpoints:** Accepted usage of EMSYS internal REST endpoints until an official ACIlfov API is published.
