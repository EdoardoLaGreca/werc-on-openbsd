# Testing

Unless you'd like to contribute to the development, ignore this document.

A test script, namely `test.sh`, automates the testing of the setup and unsetup scripts. The test script contains three main functions:

- `init`, which performs all the preliminary tasks
- `setup`, which runs the setup script and collects information about changes in the filesystem
- `unsetup`, which is the same as `setup` but with the unsetup script

The behavior of the test script is similar to that of the setup and unsetup scripts: functions can be called by specifying them as command line arguments. However, there is one little difference, which is that running the script without arguments is no different from not running the script at all. This behavior is a choice which, in theory, should reduce careless testing. 

