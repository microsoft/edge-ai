# Secrets Store

## Overview

As part of the AI flagship development cycles it is also important to consider security of secrets that are used in the project. This document describes how we maintain sensitive data like clientId, certs and secrets.

## KeyVault Inventory

KeyVault **kv-ai-on-edge-azdo** is the underlying Azure subscription is used to maintain all the secrets for the project.

## Azure DevOps Library/Variable Group

The KeyVault is linked to a Azure DevOps Variable Group **ai-on-edge-secrets** which makes the secrets available and accessible to the Azure DevOps Pipelines.
