#!/bin/bash

# Compile unpub_web and copy files to unpub
cd unpub_web
webdev build
cd ..
dart unpub/tool/pre_publish.dart
