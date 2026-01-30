[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)

# iOS SQLite with Decimal support
Build of SQLite https://www.sqlite.org/ with https://sqlite.org/floatingpoint.html#the_decimal_c_extension statically added. Additionally dynamic loading extensions disabled and metadata and rounding functions enabled.

## Thanks
**SQLite** team and sponsors for amazing database engine.

## Installation
1. In XCode access File->Add Package Dependencies
2. Search for https://github.com/jnitecki/sqlite-decimal-spm
3. Select desired version and Add Package

## Usage
You can view directly decimal specific SQL functionality enabled by this framework on SQLite website: https://sqlite.org/floatingpoint.html#the_decimal_c_extension.

For ilustration of usage via framework, refer to tests in SQLite-Decimal-iOS repository: https://github.com/jnitecki/sqlite-decimal-ios.
