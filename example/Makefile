
SRC=${GEM_FORGE_TOP}/transform/benchmark/GemForgeMicroSuite/omp_dense_mv_blk/omp_dense_mv_blk.c
FLAGS=-O3 -DGEM_FORGE -mavx512f -fopenmp -std=c11 -gline-tables-only 

LLVM_RELEASE=${GEM_FORGE_TOP}/llvm/install-release/bin
CC=${LLVM_RELEASE}/clang
CXX=${LLVM_RELEASE}/clang++
LLVM_DIS=${LLVM_RELEASE}/llvm-dis

GEM_FORGE_TRANSFORM_SO=${GEM_FORGE_TOP}/transform/build/src/libLLVMTDGPass.so

# We use debug version to enable the debug flags.
LLVM_DEBUG=${GEM_FORGE_TOP}/llvm/install-debug/bin
OPT=${LLVM_DEBUG}/opt

GEM5_INC=${GEM_FORGE_TOP}/gem5/include
GEM5_OPS=${GEM_FORGE_TOP}/gem5/util/m5/m5op_x86.S

# Gem Forge requires the bitcode named.
raw.bc: ${SRC}
	${CC} $^ ${FLAGS} -c -emit-llvm -I${GEM5_INC} -o $@
	${OPT} -instnamer $@ -o $@

raw.ll: raw.bc
	${LLVM_DIS} $^ -o $@

INST_UID=inst.uid
TRACE_FUNC=.omp_outlined.
TRACE_FILE=fake.trace

traced.bc: raw.bc
	${OPT} -load=${GEM_FORGE_TRANSFORM_SO} -trace-pass $^ -o $@ -trace-inst-uid-file ${INST_UID} -trace-function ${TRACE_FUNC}
	touch ${TRACE_FILE}

VALID_OUT=valid
VALID_EXTRA=valid/extra
valid.bc: traced.bc raw.bc
	mkdir -p ${VALID_OUT}
	mkdir -p ${VALID_EXTRA}
	${OPT} -load=${GEM_FORGE_TRANSFORM_SO} -valid-execution-pass \
		raw.bc -o $@ \
		-gem-forge-roi-function=${TRACE_FUNC} \
		-gem-forge-inst-uid-file=${INST_UID} \
		-output-datagraph=${VALID_OUT}/fake.0.tdg \
		-output-extra-folder-path=${VALID_EXTRA}
	cp ${VALID_EXTRA}/ex.bc $@

STREAM_OUT=stream
STREAM_EXTRA=stream/extra
stream.bc: traced.bc raw.bc
	mkdir -p ${STREAM_OUT}
	mkdir -p ${STREAM_EXTRA}
	${OPT} -load=${GEM_FORGE_TRANSFORM_SO} -stream-execution-static-pass \
		-stream-pass-choose-strategy=static-outer \
		-stream-pass-allow-aliased-stream \
		-stream-pass-enable-store \
		raw.bc -o $@ \
		-gem-forge-roi-function=${TRACE_FUNC} \
		-gem-forge-inst-uid-file=${INST_UID} \
		-output-datagraph=${STREAM_OUT}/fake.0.tdg \
		-output-extra-folder-path=${STREAM_EXTRA}
	cp ${STREAM_EXTRA}/ex.bc $@

%.o: %.bc
	${CC} -c -O3 -ffp-contract=off $^ -o $@

%.exe: %.o
	${CXX} -static -o $@ $^ -lomp -lpthread -Wl,--no-as-needed -ldl -I${GEM5_INC} ${GEM5_OPS} 

.PHONY: clean
clean:
	rm -f *.bc *.ll *.o *.exe ${INST_UID} *.txt  *.trace

.PHONY: clean-all
clean-all: clean
	rm -rf valid stream

GEM5=${GEM_FORGE_TOP}/gem5/build/X86/gem5.opt
GEM5_CONFIG=${GEM_FORGE_TOP}/gem5/configs/example/gem_forge/run.py

THREADS=64

O8_SIM=--llvm-store-queue-size=32 \
	--llvm-mcpat=0 \
	--caches \
	--l2cache \
	--gem-forge-num-active-cpus=1 \
	--gem-forge-cache-load-ports=6 \
	--gem-forge-cache-store-ports=4 \
	--link-width-bits=256 \
	--llc-select-low-bit=6 \
	--cpu-type=DerivO3CPU \
	--llvm-issue-width=8 \
	--gem-forge-enable-func-acc-tick \
	--prog-interval=10000 \
	--tlb-timing-se \
	--l1tlb-size=64 \
	--l1tlb-assoc=8 \
	--l2tlb-size=2048 \
	--l2tlb-assoc=16 \
	--l2tlb-hit-lat=8 \
	--walker-se-lat=16 \
	--walker-se-port=2 \
	--num-cpus=64 \
	--num-dirs=4 \
	--num-l2caches=64 \
	--mesh-rows=8 \
	--ruby \
	--access-backing-store \
	--network=garnet2.0 \
	--garnet-enable-multicast \
	--router-latency=2 \
	--link-latency=1 \
	--mem-channels=2 \
	--mem-size=16GB \
	--topology=MeshDirCorners_XY \
	--routing-YX \
	--l1i_size=32kB \
	--l1i_assoc=8 \
	--l1d_size=32kB \
	--l1d_lat=8 \
	--l1d_mshrs=8 \
	--l1d_assoc=8 \
	--l1_5d_size=256kB \
	--l1_5d_assoc=16 \
	--l1_5d_mshrs=16 \
	--l2_lat=16 \
	--l2_size=1MB \
	--l2_assoc=16 \
	--l3_lat=20 \
	--fast-forward=-1 \
	--options=${THREADS}

.PHONY: valid.o8.sim
valid.o8.sim: valid.exe
	${GEM5} \
		--outdir=${VALID_OUT}/o8 \
		--stats-file=text://stats.txt?dumpAll=False \
		--listener-mode=off \
		${GEM5_CONFIG} \
		--cmd=$^ \
		${O8_SIM}

.PHONY: valid.o8-pf.sim
valid.o8-pf.sim: valid.exe
	${GEM5} \
		--outdir=${VALID_OUT}/o8-pf \
		--stats-file=text://stats.txt?dumpAll=False \
		--listener-mode=off \
		${GEM5_CONFIG} \
		--cmd=$^ \
		${O8_SIM} \
		--gem-forge-prefetcher=bingo \
		--gem-forge-l2-prefetcher=stride \
		--gem-forge-l2-prefetch-dist=16 \

.PHONY: stream.o8.sim
stream.o8.sim: stream.exe
	cp $^ ${STREAM_EXTRA}/
	${GEM5} \
		--outdir=${STREAM_OUT}/o8 \
		--stats-file=text://stats.txt?dumpAll=False \
		--listener-mode=off \
		${GEM5_CONFIG} \
		--cmd=${STREAM_EXTRA}/$^ \
		${O8_SIM} \
		--gem-forge-stream-engine-enable \
		--gem-forge-stream-engine-total-run-ahead-bytes=2048 \
		--gem-forge-stream-engine-enable-lsq \
		--gem-forge-stream-engine-enable-coalesce \
		--gem-forge-stream-engine-throttling=global 

.PHONY: stream.o8-float.sim
stream.o8-float.sim: stream.exe
	cp $^ ${STREAM_EXTRA}/
	${GEM5} \
		--outdir=${STREAM_OUT}/o8-float \
		--stats-file=text://stats.txt?dumpAll=False \
		--listener-mode=off \
		${GEM5_CONFIG} \
		--cmd=${STREAM_EXTRA}/$^ \
		${O8_SIM} \
		--gem-forge-stream-engine-enable \
		--gem-forge-stream-engine-total-run-ahead-bytes=2048 \
		--gem-forge-stream-engine-enable-lsq \
		--gem-forge-stream-engine-enable-coalesce \
		--gem-forge-stream-engine-throttling=global \
		--gem-forge-stream-engine-enable-float \
		--gem-forge-stream-engine-mlc-stream-buffer-init-num-entries=32 \
		--gem-forge-stream-engine-float-policy=smart \
		--gem-forge-stream-engine-enable-float-indirect \
		--gem-forge-stream-engine-enable-float-subline \
		--gem-forge-stream-engine-enable-float-advance-migrate \
		--gem-forge-stream-engine-llc-stream-max-infly-request=16 \
		--llc-select-low-bit=10 \

.PHONY: sim-all
sim-all: valid.o8.sim valid.o8-pf.sim stream.o8.sim stream.o8-float.sim
	echo "Simulation all done!"
