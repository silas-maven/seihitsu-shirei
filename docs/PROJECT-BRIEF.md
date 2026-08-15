# Project brief — Seihitsu Shirei

## Product

A private macOS-native AI HUD: a menu-bar controlled, borderless floating panel that can be positioned over work without appearing in ordinary screenshots or screen shares where the operating system exposes a supported exclusion mechanism.

## Design requirements

- Native Swift/AppKit/SwiftUI implementation for reliable macOS window control.
- An always-on-top, transparent or borderless panel with drag, resize, and click-through modes.
- Fast summon/hide via a global hotkey and a menu-bar control surface.
- Provider-neutral AI layer: OpenAI, Anthropic, Gemini, and local inference endpoints.
- Screen context only through explicitly permitted OCR, clipboard, or accessibility APIs.

## Non-goals for the first build

- Commercial release, marketing, multi-user accounts, billing, analytics, or cloud-hosted collaboration.
- Guaranteed invisibility in every capture scenario. Behaviour depends on the active macOS capture API and sharing path.

## Status

Scaffold only. Architecture and implementation are intentionally deferred.
