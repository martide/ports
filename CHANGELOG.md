# Changelog for Ports

## [Unreleased] (2024-06-25)

- Use UNLOCODE raw data instead of manually compiled csv to prevent unnecessary encoding
- Remove ports without country or location
- Convert `port.name` to valid string
- Remove mix project package.files to use default project directory instead

## v0.1.2 (2024-06-21)

- Update code list source to v2023-2

## v0.1.1 (2021-01-20)

- Change csv parser from [csv](https://github.com/beatrichartz/csv) to [nimble_csv](https://github.com/dashbitco/nimble_csv)
- Include files in `priv/data` to package
- Load lists during compilation time for faster response
