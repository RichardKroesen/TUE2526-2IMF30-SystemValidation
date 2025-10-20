INPUT = TrafficLightController_spec.mcrl2
PROPERTIES = properties
OUT = build

# Some things can be multithreaded
# Do that, lol
CORES = $(shell nproc)

include render.mk

.PHONY: lts graph view sim clean build-properties verify-properties verify-counts verify-summary

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

$(OUT)/%.status: $(OUT)/$(BASE_INPUT).lts $(OUT)/%.pbes
	pbessolve -v --in=pbes --threads=$(CORES) --file=$< $(OUT)/$*.pbes > $@

$(OUT)/%.pbes: $(OUT)/$(BASE_INPUT).lts $(PROPERTIES)/%.mcf
	lts2pbes -v --counter-example --formula=$(PROPERTIES)/$*.mcf $< $@

$(OUT)/$(BASE_INPUT).lts: $(OUT)/$(BASE_INPUT).opt.lps
	@mkdir -p $(OUT)
	lps2lts --confluence $^ $@

$(OUT)/$(BASE_INPUT).opt.lps: $(OUT)/$(BASE_INPUT).lps
	lpsconfcheck --induction --check-all $^ $@

$(OUT)/$(BASE_INPUT).lps: $(INPUT)
	@mkdir -p $(OUT)
	mcrl22lps $^ $@

clean:
	rm -r $(OUT)

# New target: counts true/false and fails if any false found
verify-counts: verify-properties
	@TRUE_COUNT=`grep -h -x true $(OUT)/*.status 2>/dev/null | wc -l`; \
	FALSE_COUNT=`grep -h -x false $(OUT)/*.status 2>/dev/null | wc -l`; \
	TOTAL=`expr $$TRUE_COUNT + $$FALSE_COUNT`; \
	echo ""; \
	echo "Total properties checked: $$TOTAL"; \
	echo "  true : $$TRUE_COUNT"; \
	echo "  false: $$FALSE_COUNT"; \
	if [ $$FALSE_COUNT -gt 0 ]; then \
	  echo ""; \
	  echo "Failed properties:"; \
	  for f in $(OUT)/*.status; do \
	    if [ -f $$f ] && grep -q -x false $$f 2>/dev/null; then \
	      echo " - $$(basename $$f .status)"; \
	    fi; \
	  done; \
	  exit 1; \
	else \
	  echo "All properties hold."; \
	fi

# Lighter summary that doesn't fail (optional)
verify-summary: verify-properties
	@TRUE_COUNT=`grep -h -x true $(OUT)/*.status 2>/dev/null | wc -l`; \
	FALSE_COUNT=`grep -h -x false $(OUT)/*.status 2>/dev/null | wc -l`; \
	TOTAL=`expr $$TRUE_COUNT + $$FALSE_COUNT`; \
	echo ""; \
	echo "Total properties checked: $$TOTAL"; \
	echo "  true : $$TRUE_COUNT"; \
	echo "  false: $$FALSE_COUNT"
