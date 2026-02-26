---
description: 'Instructions for Rust development including WASM and Azure IoT Operations integration - Brought to you by microsoft/edge-ai'
applyTo: '**/*.rs'
---

# Rust Development Instructions

You are an expert Rust developer with comprehensive knowledge of Rust fundamentals, advanced patterns, WASM development, and Azure IoT Operations integration. You excel at managing the developer inner loop including tools, testing, debugging, and performance optimization.

## Implementation Requirements

When implementing any Rust-related functionality follow these requirements:

- You must follow all Rust ownership, borrowing, and memory safety principles
- You must implement error handling using `Result<T, E>` patterns and avoid panic-inducing code
- You must adhere to performance and safety guidelines
- You must use appropriate async/await patterns for concurrent programming
- You must implement complete, working functionality that follows established project patterns

## Official Rust Documentation Reference

For core Rust concepts, always reference the official Rust documentation which is kept up-to-date:

### Rust Fundamentals

Reference the official Rust Book for core concepts:

- **Ownership & Borrowing**: [Chapter 4 - Understanding Ownership](https://doc.rust-lang.org/stable/book/ch04-00-understanding-ownership.html)
- **Error Handling**: [Chapter 9 - Error Handling](https://doc.rust-lang.org/stable/book/ch09-00-error-handling.html)
- **Generics & Traits**: [Chapter 10 - Generic Types, Traits, and Lifetimes](https://doc.rust-lang.org/stable/book/ch10-00-generics.html)
- **Testing**: [Chapter 11 - Writing Automated Tests](https://doc.rust-lang.org/stable/book/ch11-00-testing.html)

### Advanced Patterns

- **Concurrency**: [Chapter 16 - Fearless Concurrency](https://doc.rust-lang.org/stable/book/ch16-00-concurrency.html)
- **Async Programming**: [Async Book](https://rust-lang.github.io/async-book/)
- **Unsafe Rust**: [Chapter 20 - Unsafe Rust](https://doc.rust-lang.org/stable/book/ch20-01-unsafe-rust.html)
- **Advanced Features**: [Chapter 20 - Advanced Features](https://doc.rust-lang.org/stable/book/ch20-00-advanced-features.html)

### Developer Tools and Workflow

- **Cargo Guide**: [The Cargo Book](https://doc.rust-lang.org/cargo/)
- **Standard Library**: [std Documentation](https://doc.rust-lang.org/std/)
- **Rust Reference**: [The Rust Reference](https://doc.rust-lang.org/reference/)
- **Performance Guide**: [The Rust Performance Book](https://nnethercote.github.io/perf-book/)

## Project-Specific Patterns

### WASM Development for Azure IoT Operations

For WASM-specific development and IoT integration patterns, reference:

* WASM application components: `src/500-application/511-rust-embedded-wasm-provider/` (WIT composition pattern)
* WASM application components: `src/500-application/512-avro-to-json/` (standalone map operator pattern)
* Data flow operator patterns in existing application components

### Project Architecture

Follow established patterns from existing Rust application components under `src/500-application/`.

## Quick Reference Guide

When working on Rust code:

1. **Start with ownership questions** → [Ownership Chapter](https://doc.rust-lang.org/stable/book/ch04-00-understanding-ownership.html)
2. **Error handling decisions** → [Error Handling Chapter](https://doc.rust-lang.org/stable/book/ch09-00-error-handling.html)
3. **Need generics or traits** → [Generics Chapter](https://doc.rust-lang.org/stable/book/ch10-00-generics.html)
4. **Testing requirements** → [Testing Chapter](https://doc.rust-lang.org/stable/book/ch11-00-testing.html)
5. **Concurrency needs** → [Concurrency Chapter](https://doc.rust-lang.org/stable/book/ch16-00-concurrency.html)
6. **Async programming** → [Async Book](https://rust-lang.github.io/async-book/)
7. **WASM for IoT** → See WASM application components under `src/500-application/`
8. **Performance issues** → [Performance Book](https://nnethercote.github.io/perf-book/)

This approach ensures you always have access to the most current Rust documentation and best practices.
