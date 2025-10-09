
INPUT = TrafficLightController_spec.mcrl2
OUT = build

include render.mk

.PHONY: lts graph view sim clean

BASE_INPUT = $(basename $(INPUT))

graph: $(OUT)/$(BASE_INPUT).lts
	QT_QPA_PLATFORM=$(RENDERER) ltsgraph $^

view: $(OUT)/$(BASE_INPUT).lts
	QT_QPA_PLATFORM=$(RENDERER) ltsgraph $^

sim: $(OUT)/$(BASE_INPUT).lps
	QT_QPA_PLATFORM=$(RENDERER) lpsxsim $^

lts: $(OUT)/$(BASE_INPUT).lts

$(OUT)/$(BASE_INPUT).lts: $(OUT)/$(BASE_INPUT).lps
	mkdir -p $(OUT)
	echo $@
	lps2lts $^ $@

$(OUT)/$(BASE_INPUT).lps: $(INPUT)
	mkdir -p $(OUT)
	echo $@
	mcrl22lps $^ $@

clean:
	rm -r $(OUT)

