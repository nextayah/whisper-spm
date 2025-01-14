# CMake generated Testfile for 
# Source directory: /Users/numan/Desktop/tarteel-whisper-to-ggml/whisper.cpp/tests
# Build directory: /Users/numan/Desktop/tarteel-whisper-to-ggml/whisper.cpp/tests
# 
# This file includes the relevant testing commands required for 
# testing this directory and lists subdirectories to be tested as well.
add_test(test-whisper-js "node" "test-whisper.js" "--experimental-wasm-threads")
set_tests_properties(test-whisper-js PROPERTIES  WORKING_DIRECTORY "/Users/numan/Desktop/tarteel-whisper-to-ggml/whisper.cpp/tests" _BACKTRACE_TRIPLES "/Users/numan/Desktop/tarteel-whisper-to-ggml/whisper.cpp/tests/CMakeLists.txt;7;add_test;/Users/numan/Desktop/tarteel-whisper-to-ggml/whisper.cpp/tests/CMakeLists.txt;0;")
