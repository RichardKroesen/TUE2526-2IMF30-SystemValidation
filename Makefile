
INPUT = TrafficLightController_spec.mcrl2
PROPERTIES = properties
OUT = build

# Some things can be multithreaded
# Do that, lol
CORES = $(shell nproc)

include render.mk

.PHONY: lts graph view sim clean build-properties verify-properties

BASE_INPUT = $(basename $(INPUT))

graph: $(OUT)/$(BASE_INPUT).lts
	QT_QPA_PLATFORM=$(RENDERER) ltsgraph $^

view: $(OUT)/$(BASE_INPUT).lts
	QT_QPA_PLATFORM=$(RENDERER) ltsgraph $^

sim: $(OUT)/$(BASE_INPUT).lps
	QT_QPA_PLATFORM=$(RENDERER) lpsxsim $^

lts: $(OUT)/$(BASE_INPUT).lts

build-properties: $(patsubst %.mcf,$(OUT)/%.pbes,$(shell ls $(PROPERTIES)))

verify-properties: $(patsubst %.mcf,$(OUT)/%.status,$(shell ls $(PROPERTIES)))
	for FILE in $^; do \
		echo ""; \
		echo "PROPERTY $$(basename $$FILE .status) EVALUATES TO -> $$(cat $$FILE)"; \
		echo ""; \
	done

verify-%: $(OUT)/%.status
	@echo ""
	@echo "PROPERTY $* EVALUATES TO -> $(shell cat $^)"
	@echo ""

show-counter-%: $(OUT)/%.pbes.evidence.lts
	QT_QPA_PLATFORM=$(RENDERER) ltsgraph $^

$(OUT)/%.pbes.evidence.lts $(OUT)/%.status: $(OUT)/$(BASE_INPUT).lts $(OUT)/%.pbes
	pbessolve -v --in=pbes --threads=$(CORES) --file=$< $(OUT)/$*.pbes > $@

$(OUT)/%.pbes: $(OUT)/$(BASE_INPUT).lts $(PROPERTIES)/%.mcf
	lts2pbes -v --counter-example --formula=$(PROPERTIES)/$*.mcf $< $@

$(OUT)/$(BASE_INPUT).lts: $(OUT)/$(BASE_INPUT).opt.lps
	@mkdir -p $(OUT)
	lps2lts -v --confluence $^ $@

$(OUT)/$(BASE_INPUT).opt.lps: $(OUT)/$(BASE_INPUT).lps
	lpsconfcheck -v --induction --check-all $^ $@

$(OUT)/$(BASE_INPUT).lps: $(INPUT)
	@mkdir -p $(OUT)
	mcrl22lps -v --lin-method=stack $^ $@

clean:
	rm -r $(OUT)

