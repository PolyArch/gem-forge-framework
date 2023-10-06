
.PHONY: all
all: protobuf openlibm transform gem5 affinity_alloc
	echo "# Build everything!"

.PHONY: protobuf
protobuf:
	$(info #)
	$(info ######################## Build Protobuf #########################################)
	$(info #)
	cd ${GEM_FORGE_TOP}/lib/protobuf && \
	./autogen.sh && \
	CPPFLAGS=-DGOOGLE_PROTOBUF_NO_RTTI \
		CXXFLAGS=-fPIC \
		./configure \
		--prefix=${GEM_FORGE_TOP}/build \
		--enable-shared=no \
		--with-zlib=yes && \
	make -j ${CORES} install && \
	cd python && \
	python3 setup.py install --user

.PHONY: openlibm
openlibm:
	$(info #)
	$(info ######################## Build Openlibm #########################################)
	$(info #)
	cd ${GEM_FORGE_TOP}/lib/openlibm && \
	make prefix=${GEM_FORGE_TOP}/build -j ${CORES} install

TRANSFORM_COMPILE_COMMANDS=transform/build/compile_commands.json
AFFINITY_ALLOC_COMPILE_COMMANDS=lib/affinity_alloc/build/compile_commands.json
DRAMSIM3_COMPILE_COMMANDS=gem5/ext/dramsim3/DRAMsim3/build/compile_commands.json
GEM5_COMPILE_COMMANDS=gem5/fixed_compile_commands.json
ALL_COMPILE_COMMANDS=compile_commands.json

.PHONY: dramsim3
dramsim3: 
	$(info #)
	$(info ######################## Build GemForge DRAMSIM3 ####################################)
	$(info #)
	cd gem5/ext/dramsim3/DRAMsim3 && \
	mkdir -p build && \
	cd build && \
	cmake .. && \
	make -j ${CORES} && \
	cd ../../../../.. && \
	python combine_compile_commands.py ${ALL_COMPILE_COMMANDS} ${DRAMSIM3_COMPILE_COMMANDS}

.PHONY: clean-dramsim3
clean-dramsim3:
	$(info #)
	$(info ######################## Clean GemForge DRAMSIM3 ####################################)
	$(info #)
	cd gem5/ext/dramsim3/DRAMsim3 && \
	rm -rf build

.PHONY: affinity_alloc
affinity_alloc:
	$(info #)
	$(info ######################## Build Affinity Alloc ###################################)
	$(info #)
	cd lib/affinity_alloc && \
	mkdir -p build && \
	cd build && \
	CC=clang CXX=clang++ cmake .. && \
	make -j ${CORES} && \
	cd ../../.. && \
	python combine_compile_commands.py ${ALL_COMPILE_COMMANDS} ${AFFINITY_ALLOC_COMPILE_COMMANDS} 

.PHONY: transform
transform:
	$(info #)
	$(info ######################## Build GemForge Transforms ##############################)
	$(info #)
	cd transform && \
	mkdir -p build && \
	cd build && \
	cmake .. && \
	make -j ${CORES} && \
	cd ../.. && \
	python combine_compile_commands.py ${ALL_COMPILE_COMMANDS} ${TRANSFORM_COMPILE_COMMANDS} 
    
# CORES=1
.PHONY: gem5.opt
gem5.opt: dramsim3
	$(info #)
	$(info ######################## Build GemForge GEM5 Opt ################################)
	$(info #)
	cd gem5 && \
	bear scons build/X86/gem5.opt --default=X86 PROTOCOL=MESI_Three_Level_Stream -j ${CORES} && \
	python fix_compile_command.py compile_commands.json ${CPATH} > fixed_compile_commands.json && \
	cd .. && \
	python combine_compile_commands.py ${ALL_COMPILE_COMMANDS} ${GEM5_COMPILE_COMMANDS}

.PHONY: gem5.opt-fp
gem5.opt-fp: dramsim3
	$(info #)
	$(info ######################## Build GemForge GEM5 Opt-Fp ############################)
	$(info #)
	cd gem5 && \
	bear scons build/X86/gem5.opt-fp --default=X86 PROTOCOL=MESI_Three_Level_Stream -j ${CORES} && \
	cd ..

.PHONY: gem5.fast
gem5.fast: dramsim3
	$(info #)
	$(info ######################## Build GemForge GEM5 Fast ###############################)
	$(info #)
	cd gem5 && \
	bear scons build/X86/gem5.fast --default=X86 PROTOCOL=MESI_Three_Level_Stream -j ${CORES} && \
	cd ..

.PHONY: gem5
gem5: gem5.fast gem5.opt
	$(info #)
	$(info ######################## Built GemForge GEM5 ####################################)
	$(info #)

PUM_JITTER_FOLDER=build/X86/cpu/gem_forge/accelerator/stream/cache/pum
PUM_JITTER_FAST=${PUM_JITTER_FOLDER}/pum-jitter.fast

.PHONY: pum-jitter
pum-jitter:
	$(info #)
	$(info ######################## Build PUM Jitter #######################################)
	$(info #)
	cd gem5 && \
	bear scons ${PUM_JITTER_FAST} --verbose && \
	python fix_compile_command.py compile_commands.json ${CPATH} > fixed_compile_commands.json && \
	${PUM_JITTER_FAST} && \
	cd .. && \
	python combine_compile_commands.py ${ALL_COMPILE_COMMANDS} ${GEM5_COMPILE_COMMANDS}
