# AWS Route53 Module

## Description

This Terraform module manages Route53 records in a specified Route53 hosted zone.

## Variables

| Variable            | Type           | Required/Optional | Description                                               |
| ------------------- | -------------- | ----------------- | --------------------------------------------------------- |
| `zone_name`         | String         | Required          | The name of the Route53 hosted zone.                       |
| `alias_records`     | Map of Any      | Optional          | A map of alias records to be created. Defaults to an empty map. |
| `non_alias_records` | Map of Any      | Optional          | A map of non-alias records to be created. Defaults to an empty map. |

## Alias Records Structure

For each entry in the `alias_records` map, the following structure is expected:

| Key               | Type           | Description                                       |
| ----------------- | -------------- | ------------------------------------------------- |
| `type`            | String         | The record type (e.g., "A", "CNAME").              |
| `record_value`    | Map of Any      | The value for the alias record. See below for the expected structure. |


## Non-Alias Records Structure

For each entry in the `non_alias_records` map, the following structure is expected:

| Key               | Type           | Description                                       |
| ----------------- | -------------- | ------------------------------------------------- |
| `type`            | String         | The record type (e.g., "A", "CNAME").              |
| `ttl`             | Number         | The time to live (TTL) for the record.             |
| `record_value`    | Any            | The value for the non-alias record.                |

## Outputs

| Output                  | Description                                       |
| ----------------------- | ------------------------------------------------- |
| `alias-records`         | The created alias records.                        |
| `non-alias-records`     | The created non-alias records. 