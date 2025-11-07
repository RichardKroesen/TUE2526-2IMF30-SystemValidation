
INPUT = TrafficLightController_spec.mcrl2
PROPERTIES = properties
OUT = build

# Options: jitty, jittyc, jittyp
# I recommend using jitty or jittyc
REWRITER=jitty
# Options: pbessolve pbessolvesymbolic
SOLVER=pbessolve

# Some things can be multithreaded
# Do that, lol
CORES = $(shell nproc)

include render.mk

.PHONY: lts lps graph view sim clean build-properties verify-properties

BASE_INPUT = $(basename $(INPUT))

graph: $(OUT)/$(BASE_INPUT).lts
	QT_QPA_PLATFORM=$(RENDERER) ltsgraph $^

view: $(OUT)/$(BASE_INPUT).lts
	QT_QPA_PLATFORM=$(RENDERER) ltsgraph $^

sim: $(OUT)/$(BASE_INPUT).lps
	QT_QPA_PLATFORM=$(RENDERER) lpsxsim $^

lts: $(OUT)/$(BASE_INPUT).lts
lps: $(OUT)/$(BASE_INPUT).opt.lps

build-properties: $(patsubst %.mcf,$(OUT)/%.pbes,$(shell ls $(PROPERTIES)))

verify-properties: $(patsubst %.mcf,$(OUT)/%.status,$(shell ls $(PROPERTIES)))
	echo ""; \
	for FILE in $^; do \
		echo "PROPERTY $$(basename $$FILE .status) EVALUATES TO -> $$(cat $$FILE)"; \
	done

verify-%: $(OUT)/%.status
	@echo ""
	@echo "PROPERTY $* EVALUATES TO -> $(shell cat $^)"
	@echo ""

show-counter-%: $(OUT)/%.pbes.evidence.lts
	QT_QPA_PLATFORM=$(RENDERER) ltsgraph $^

$(OUT)/%.pbes.evidence.lts $(OUT)/%.status: $(OUT)/$(BASE_INPUT).lts $(OUT)/%.pbes
	@mkdir -p $(OUT)
	$(SOLVER) -v \
		--rewriter=$(REWRITER) \
		--in=pbes \
		--threads=$(CORES) \
		--file=$< $(OUT)/$*.pbes > $@

$(OUT)/%.pbes: $(OUT)/$(BASE_INPUT).lts $(PROPERTIES)/%.mcf
	@mkdir -p $(OUT)
	lts2pbes -v \
		--counter-example \
		--preprocess-modal-operators \
		--formula=$(PROPERTIES)/$*.mcf $< $@

#$(OUT)/$(BASE_INPUT).lts: $(OUT)/$(BASE_INPUT).opt.lps
$(OUT)/$(BASE_INPUT).lts: $(OUT)/$(BASE_INPUT).lps
	@mkdir -p $(OUT)
	#lps2lts -v --cached --confluence $^ $@
	lps2lts -v --cached --confluence $^ $@

$(OUT)/$(BASE_INPUT).opt.lps: $(OUT)/$(BASE_INPUT).lps
	@mkdir -p $(OUT)
	lpsconfcheck -v \
		--rewriter=$(REWRITER) \
		--counter-example \
		--induction \
		--check-all $^ $@

$(OUT)/$(BASE_INPUT).lps: $(INPUT)
	@mkdir -p $(OUT)
	mcrl22lps -v \
		--rewriter=$(REWRITER) \
		--lin-method=stack $^ $@

clean:
	rm -r $(OUT)

