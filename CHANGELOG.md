# Changelog

## 0.3.0

* Major rewrite of internals. Should be much easier to implement new features
* Removed `featureName` from `jefe finish`
* Allow project names to differ from repo names

## 0.2.10

* Updated pubspec dependency

## 0.2.9

* Bug fix. Missed case for using `publish_to` property when fetching versions

## 0.2.8

* Support third party pub repos via publish_to pubspec property

## 0.2.7

* Fix to work with normal tags (non annotated) too
* Don't run tests if project doesn't use test package

## 0.2.4

* added `jefe test` which runs `pub run test` on all projects that have a test
dir

* added `dev_dependencies` to the project dependencies that `jefe` manages

## 0.2.3

* support auto update of hosted versions

## 0.2.2

* tighter constraints for exported packages

## 0.2.0

* support for hosted packages

## 0.1.0

* reworked executors to simplify
* made several commands more idempotent so that you can rerun them as needed

## 0.0.1

- Initial version, created by Stagehand
