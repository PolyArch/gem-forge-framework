echo "#"
echo "######################## Build Protobuf #########################################"
echo "#"
cd $GEM_FORGE_TOP/lib/protobuf
./autogen.sh
CPPFLAGS=-DGOOGLE_PROTOBUF_NO_RTTI \
    CXXFLAGS=-fPIC \
    ./configure \
    --prefix=$GEM_FORGE_TOP/build \
    --enable-shared=no \
    --with-zlib=yes
make -j $CORES
make install
# Build python files.
cd python
python3 setup.py build
cd ../../..

echo "#"
echo "######################## Build GemForge Transforms ##############################"
echo "#"
cd transform
mkdir -p build
cd build
cmake ..
make -j $CORES
cd ../..

echo "#"
echo "######################## Build GemForge GEM5 ####################################"
echo "#"
cd gem5
scons build/X86/gem5.opt --default=X86 PROTOCOL=MESI_Three_Level_Stream 
