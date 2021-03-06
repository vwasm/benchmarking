# Fill these in with your own system
REPOS_DIR=/home/user/repos/benchmarking
TEST_DIR=$REPOS_DIR/tests
TESTETH_EXEC=$REPOS_DIR/aleth/bin/testeth
HERA_SO=$REPOS_DIR/hera-benchmarking/build/src/libhera.so
PYWEBASSEMBLY_DIR=$REPOS_DIR/pywebassembly
BINARYEN_DIR=$REPOS_DIR/binaryen
BENCHMARKING_DIR=$REPOS_DIR/benchmarking
WASMCEPTION_DIR=$REPOS_DIR/wasmception

# compile each precompile
cd $BENCHMARKING_DIR
$WASMCEPTION_DIR/dist/bin/clang --target=wasm32-unknown-unknown-wasm --sysroot=$WASMCEPTION_DIR/sysroot -O3 -g -o sha256_c_1.wasm -nostartfiles -Wl,--allow-undefined-file=$BENCHMARKING_DIR/source/c_undefined.syms,--demangle,--no-entry,--no-threads -Wl,--export=_main -fvisibility=hidden $BENCHMARKING_DIR/source/sha256_c_1.c
$WASMCEPTION_DIR/dist/bin/clang --target=wasm32-unknown-unknown-wasm --sysroot=$WASMCEPTION_DIR/sysroot -O3 -g -o sha256_c_2.wasm -nostartfiles -Wl,--allow-undefined-file=$BENCHMARKING_DIR/source/c_undefined.syms,--demangle,--no-entry,--no-threads -Wl,--export=_main -fvisibility=hidden $BENCHMARKING_DIR/source/sha256_c_2.c
$WASMCEPTION_DIR/dist/bin/clang --target=wasm32-unknown-unknown-wasm --sysroot=$WASMCEPTION_DIR/sysroot -O3 -g -o sha256_c_3.wasm -nostartfiles -Wl,--allow-undefined-file=$BENCHMARKING_DIR/source/c_undefined.syms,--demangle,--no-entry,--no-threads -Wl,--export=_main -fvisibility=hidden $BENCHMARKING_DIR/source/sha256_c_3.c
$WASMCEPTION_DIR/dist/bin/clang --target=wasm32-unknown-unknown-wasm --sysroot=$WASMCEPTION_DIR/sysroot -O3 -g -o keccak256_c_1.wasm -nostartfiles -Wl,--allow-undefined-file=$BENCHMARKING_DIR/source/c_undefined.syms,--demangle,--no-entry,--no-threads -Wl,--export=_main -fvisibility=hidden $BENCHMARKING_DIR/source/keccak256_c_1.c
$WASMCEPTION_DIR/dist/bin/clang --target=wasm32-unknown-unknown-wasm --sysroot=$WASMCEPTION_DIR/sysroot -O3 -g -o ed25519verify_c_tweetnacl.wasm -nostartfiles -Wl,--allow-undefined-file=$BENCHMARKING_DIR/source/c_undefined.syms,--demangle,--no-entry,--no-threads -Wl,--export=_main -fvisibility=hidden $BENCHMARKING_DIR/source/ed25519verify_c_tweetnacl.c

# For C-language precompiles, use PyWebAssembly to clean them up
cd $PYWEBASSEMBLY_DIR/examples/
python3 ewasmify.py $BENCHMARKING_DIR/sha256_c_1.wasm
python3 ewasmify.py $BENCHMARKING_DIR/sha256_c_2.wasm
python3 ewasmify.py $BENCHMARKING_DIR/sha256_c_3.wasm
python3 ewasmify.py $BENCHMARKING_DIR/keccak256_c_1.wasm
python3 ewasmify.py $BENCHMARKING_DIR/ed25519verify_c_tweetnacl.wasm

# use binaryen to convert each .wasm to .wat
cd $BENCHMARKING_DIR
$BINARYEN_DIR/build/bin/wasm-dis sha256_c_1_ewasmified.wasm > sha256_c_1.wat
$BINARYEN_DIR/build/bin/wasm-dis sha256_c_2_ewasmified.wasm > sha256_c_2.wat
$BINARYEN_DIR/build/bin/wasm-dis sha256_c_3_ewasmified.wasm > sha256_c_3.wat
$BINARYEN_DIR/build/bin/wasm-dis keccak256_c_1_ewasmified.wasm > keccak256_c_1.wat
$BINARYEN_DIR/build/bin/wasm-dis ed25519verify_c_tweetnacl_ewasmified.wasm > ed25519verify_c_tweetnacl.wat

# create a filler for each .wat precompile
cd $BENCHMARKING_DIR
python3 ewasm_precompile_filler_generator.py sha256_c_1 sha256_c_1.wat source/sha256.dat
python3 ewasm_precompile_filler_generator.py sha256_c_2 sha256_c_2.wat source/sha256.dat
python3 ewasm_precompile_filler_generator.py sha256_c_3 sha256_c_3.wat source/sha256.dat
python3 ewasm_precompile_filler_generator.py keccak256_c_1 keccak256_c_1.wat source/keccak256.dat
python3 ewasm_precompile_filler_generator.py ed25519verify_c_tweetnacl ed25519verify_c_tweetnacl.wat source/ed25519.dat


# put fillers into the fillers directory
cp *.yml $TEST_DIR/src/GeneralStateTestsFiller/stEWASMTests/

# create dummy lllc which may be needed by testeth
printf '#!/usr/bin/env bash\necho 1' > lllc
chmod +x lllc
PATH=$PATH:.

# fill each test
ETHEREUM_TEST_PATH=$TEST_DIR $TESTETH_EXEC -t GeneralStateTests/stEWASMTests -- --filltests --vm $HERA_SO --evmc engine=binaryen --singlenet "Byzantium" --singletest sha256_c_1
ETHEREUM_TEST_PATH=$TEST_DIR $TESTETH_EXEC -t GeneralStateTests/stEWASMTests -- --filltests --vm $HERA_SO --evmc engine=binaryen --singlenet "Byzantium" --singletest sha256_c_2
ETHEREUM_TEST_PATH=$TEST_DIR $TESTETH_EXEC -t GeneralStateTests/stEWASMTests -- --filltests --vm $HERA_SO --evmc engine=binaryen --singlenet "Byzantium" --singletest sha256_c_3
ETHEREUM_TEST_PATH=$TEST_DIR $TESTETH_EXEC -t GeneralStateTests/stEWASMTests -- --filltests --vm $HERA_SO --evmc engine=binaryen --singlenet "Byzantium" --singletest keccak256_c_1
ETHEREUM_TEST_PATH=$TEST_DIR $TESTETH_EXEC -t GeneralStateTests/stEWASMTests -- --filltests --vm $HERA_SO --evmc engine=binaryen --singlenet "Byzantium" --singletest ed25519verify_c_tweetnacl

# save filled tests into our repo for others to use
cp $TEST_DIR/GeneralStateTests/stEWASMTests/sha256_c_1.json $BENCHMARKING_DIR/filled/
cp $TEST_DIR/GeneralStateTests/stEWASMTests/sha256_c_2.json $BENCHMARKING_DIR/filled/
cp $TEST_DIR/GeneralStateTests/stEWASMTests/sha256_c_3.json $BENCHMARKING_DIR/filled/
cp $TEST_DIR/GeneralStateTests/stEWASMTests/keccak256_c_1.json $BENCHMARKING_DIR/filled/
cp $TEST_DIR/GeneralStateTests/stEWASMTests/ed25519verify_c_tweetnacl.json $BENCHMARKING_DIR/filled/

# clean up
rm *.wasm *.wat *.yml lllc
