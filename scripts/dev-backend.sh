#!/bin/bash
cd backend
export RUST_LOG=debug
cargo watch -x run
