# Terraform AWS Cloudfront function 🔥

This Terraform module provisions CloudFront functions.

## Table of Contents

- [Introduction](#introduction)
- [Usage](#usage)
- [Inputs](#inputs)
- [Outputs](#outputs)

## Introduction

This Terraform module is designed to create and manage CloudFront functions. CloudFront functions allow you to run JavaScript code in response to CloudFront events, such as requests and responses. This module provides a flexible way to define multiple CloudFront functions with varying configurations.

## Usage

```hcl
module "cloudfront_functions" {
  source = "path/to/cloudfront-functions-module"

  cloudfront_functions = [
    {
      name      = "Function1"
      runtime   = "cloudfront-js-1.0"
      comment   = "Function 1 description"
      publish   = true
      code      = "path/to/function1.js"
      event_type = "viewer-request"
    },
    {
      name      = "Function2"
      runtime   = "cloudfront-js-1.0"
      comment   = "Function 2 description"
      publish   = true
      code      = "path/to/function2.js"
      event_type = "origin-request"
    },
    # Add more CloudFront functions as needed
  ]
}
```
## Inputs

| Name               | Type   | Required/Optional | Description                                      |
| ------------------ | ------ | ------------------ | ------------------------------------------------ |
| `cloudfront_functions` | `list` | **Required**      | List of CloudFront function configurations. See [variable documentation](#variable-cloudfront_functions). |

#### Variable `cloudfront_functions`

| Name         | Type   | Required/Optional | Description                                |
| ------------ | ------ | ------------------ | ------------------------------------------ |
| `name`       | `string` | **Required**      | Name of the CloudFront function.           |
| `runtime`    | `string` | **Required**      | Runtime environment for the function.      |
| `comment`    | `string` | **Required**      | Descriptive comment for the function.      |
| `publish`    | `bool`   | **Required**      | Boolean flag indicating whether to publish the function. |
| `code`       | `string` | **Required**      | Path to the code associated with the function. |
| `event_type` | `string` | **Required**      | Type of CloudFront event triggering the function (e.g., "viewer-request", "origin-request"). |

## Outputs
| Name                    | Description                                          |
| ----------------------- | ---------------------------------------------------- |
| `function_arns`         | ARNs of the CloudFront functions.                    |
| `function_event_types`  | List of event types for CloudFront functions.        |
