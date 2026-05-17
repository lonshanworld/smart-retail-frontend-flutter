# Business Central Frontend (Flutter)

Business Central is a multi-portal retail management platform for merchants, shops, staff, and admins.

This repository contains the Flutter frontend application used to run POS workflows, inventory operations, invoices, offline sync, reporting views, and Bluetooth thermal printing.

## Project Overview

Business Central is designed for real retail operations where reliability, speed, and offline support matter.

Key goals:
- Manage products, stock, invoices, and sales from one system
- Support multi-role portals (merchant, shop, staff, admin, public)
- Work with unstable internet using offline-first flows
- Print vouchers/invoices directly to Bluetooth thermal printers
- Provide a path for AI-assisted features in both online and offline contexts

## Current Capabilities

- Multi-portal Flutter app with role-based modules
- POS sale flow with voucher print and PDF download
- Invoice detail, PDF generation, and Bluetooth print
- Printer settings for:
	- Paper width (40mm, 58mm, 80mm)
	- Font scaling
	- Print width percentage
	- Custom voucher header lines
- Bluetooth support:
	- Classic Bluetooth
	- BLE mode (configurable service/characteristic)
- Inventory and catalog management screens
- Offline sync handling and queue-based operations

## Repository Context

In the full workspace, this frontend is paired with a Go backend service under a separate folder.

- Frontend: this folder
- Backend: smart-retail-backend

The frontend communicates with backend APIs and also maintains local app state/preferences for printer behavior and offline workflows.

## Tech Stack

- Flutter (Dart)
- GetX for state management/routing/dependency handling
- SharedPreferences for local settings persistence
- Bluetooth libraries for classic and BLE thermal printer integration
- PDF and print rasterization packages for invoice/voucher output

## AI Direction and Vector Search Plan

This project is moving toward hybrid AI features for retail assistance.

Planned direction:
- Offline/local vector index on device using SQLite vector extension (sqlite-vec style approach)
- Optional cloud embeddings for high-quality vector generation
- Local similarity search for speed and offline availability
- Optional online vector store for centralized/global knowledge

### Is this architecture possible?

Yes. A hybrid pattern is valid and commonly used:

1. Send text to a cloud embedding API when needed
2. Store returned vectors locally on device
3. Generate query embedding (cloud or local model)
4. Run nearest-neighbor search locally for fast retrieval

Benefits:
- Cost efficiency: embed once, search locally many times
- Better latency for on-device retrieval
- Stronger offline experience
- Better privacy for locally indexed data

For online vector storage, popular options include managed services such as Pinecone, Weaviate Cloud, Qdrant Cloud, or pgvector-based infrastructure, depending on budget, scale, and operational preference.

Note: This README documents direction and architecture intent only. No AI vector code changes are introduced in this update.

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK (bundled with Flutter)
- Android Studio or VS Code with Flutter tooling
- Device/emulator for testing (Bluetooth tests require a physical device)

### Install Dependencies

Run from this folder:

flutter pub get

### Run App

flutter run

### Build

Common scripts and platform folders are included for portal builds and deployment packaging.

Examples:
- build-all-portals scripts
- platform-specific build scripts for admin/merchant/staff/public portals

## Printing Notes

- Thermal print output is generated through a unified voucher template path for consistency
- Footer spacing and tear-safe blank area are intentionally included to reduce text loss
- Voucher header lines are configurable in printer settings and stored locally

## Development Status

This codebase is under active development and operational tuning.

Recent focus areas include:
- Voucher/invoice print layout refinement
- Better font and width controls
- Improved item-column spacing and alignment
- Better offline/print reliability

## License

Internal project repository. Add formal license text here when publishing.
