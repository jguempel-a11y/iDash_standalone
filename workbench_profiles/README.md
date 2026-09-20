# Workbench Profiles

This directory stores saved configuration profiles for the VA Import Workbench (`va_dbupdate_workbench.aspx`).

Each `.json` file contains:
- **separator** — The field delimiter used to parse the data file (tab, pipe, comma, or custom)
- **mapping** — A dictionary mapping file column headers to `AssetFileRaw` database column names

## How profiles are created
Click **Save Configuration Profile** on the workbench page after configuring a separator and header mapping.

## How profiles are loaded
Select a profile from the **Load Profile** dropdown on the workbench page, then click **Load**.

## File format
```json
{
  "separator": "|",
  "separatorDisplay": "Pipe (|)",
  "created": "2026-07-11T09:00:00.0000000-07:00",
  "mapping": {
    "ENTRY NUMBER": "ENTRY NUMBER",
    "MANUFACTURER": "MANUFACTURER",
    "EQUIPMENT NAME": "MFGR. EQUIPMENT NAME"
  }
}
```

## Notes
- Profiles are local to this server. They are not synced between VISN servers.
- Deleting a `.json` file from this directory removes it from the dropdown.
- Profile names are auto-generated with the separator type and timestamp.
