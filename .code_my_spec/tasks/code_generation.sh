#!/bin/bash
# Code generation script — produced by CodeMySpec code_generation task
# Re-run on a fresh Phoenix project to reproduce this scaffold.

set -e

# Authentication (LiveView): registration, login, session management
mix phx.gen.auth Users User users --live

# Multi-tenant accounts: accounts, members, invitations (requires auth)
mix cms_gen.accounts

# OAuth integrations: encrypted token storage, OAuth state store (requires auth)
mix cms_gen.integrations

# OAuth providers (one per provider; feedback widget requires codemyspec)
mix cms_gen.integration_provider CodeMySpec codemyspec

# Feedback widget with screenshot capture (requires integrations + codemyspec provider)
mix cms_gen.feedback_widget
