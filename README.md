# Scheduled Report Emailer for Business Central

![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg) ![Business Central 25+](https://img.shields.io/badge/Business%20Central-25%2B-0B7E8A) ![AL](https://img.shields.io/badge/language-AL-5C2D91)

**Email any Business Central report as PDF, Excel or Word on a schedule. One setup page, no code per report.**

<!-- DEMO: record a 30-60 second screen capture, save it as docs/images/demo.gif, then replace this comment with:
![Demo](docs/images/demo.gif) -->

> **Free and open source.** Want it installed, hosted or changed to fit your process? [Midstream Integrations](https://www.MidstreamIntegrations.com) does that. [Book a 20-minute call](https://midstreamintegrations.com/contact).

## Why

Every company has someone who opens Business Central each Monday just to run a few reports and email them. When that person is out, nobody gets them. Most "scheduled report" add-ons cover a fixed list of reports; this one works with any report, standard or custom.

## What it does

- Works with **any report**, including reports from other extensions.
- **Saves the report's options and filters** with each entry, using the report's own request page.
- **PDF, Excel or Word** attachments.
- Recipients, subject (with today's date), HTML body and file name per entry.
- **Send Now** to test; **Create Job Queue Entry** to schedule it with BC's own Job Queue, so it runs as often as you like.
- Last sent time and result on every entry; failures show up in the Job Queue log.

## Setup

1. Search for **Scheduled Report Emails** and add an entry: report, recipients (semicolon-separated), subject, body, output format.
2. Choose **Set Report Options** and fill in the request page as usual; the options are saved with the entry.
3. Choose **Send Now** to check the email.
4. Choose **Create Job Queue Entry**, set the schedule on the card, and set it to **Ready**.

Saved options are stored as entered, so a fixed date stays fixed. For rolling periods, use a report that works out its own dates, or update the options when the period changes. Excel and Word output need a report layout that supports them.

## Install

**From a release (no build tools needed)**
1. Download the `.app` file from the latest [release](../../releases).
2. In Business Central, open **Extension Management** → **Manage** → **Upload Extension** and select the file.
3. Assign the permission set listed below to the people who use it.

**From source**
1. Clone this repo and open `ScheduledReportEmailer` in VS Code with the [AL Language extension](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al).
2. Put your sandbox name and tenant ID in `.vscode/launch.json`, then run **AL: Download Symbols**.
3. Press **F5** to publish to your sandbox.

Always test in a sandbox before you install in production.

## Technical details

| | |
|---|---|
| Object ID range | 50190–50209 |
| Object prefix | `MID` |
| Dependencies | Base Application, System Application |
| Permission set(s) | `MID SCHED REPORTS` |
| Business Central | Online, version 25 or later |

## Need help, or something this doesn't do?

[Midstream Integrations](https://www.MidstreamIntegrations.com) builds and supports Business Central extensions and integrations. We can:

- install and set up this app in your tenant and show your team how to use it
- change it to fit your process: fields, reports, layouts, approval rules
- build the integration you actually need: APIs, EDI, OCR, Python services, and connections between Business Central and the other systems you run

**[Book a 20-minute call](https://midstreamintegrations.com/contact)** · intro@MidstreamIntegrations.com

## Contributing

Issues and pull requests are welcome; see [CONTRIBUTING](https://github.com/Midstream-Integrations/.github/blob/main/CONTRIBUTING.md).
Found a security problem? Please follow the [security policy](https://github.com/Midstream-Integrations/.github/blob/main/SECURITY.md) instead of opening a public issue.

## License

[MIT](LICENSE) © Midstream Integrations
