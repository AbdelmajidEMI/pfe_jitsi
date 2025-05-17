# -------- variables (override at call-time: `make NAME=demo`) ------------
.DEFAULT_GOAL := template

# convert NAME to a valid helm release name
NAME       ?= huawei
SAFE_NAME := $(shell echo $(NAME) | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g;s/^-|-$//')
NAMESPACE  ?= jitsi
OUTFILE    ?= abd.yaml
VALUES     ?= values.yaml     # path to custom values file

NS_FLAGS  := $(if $(NAMESPACE),-n $(NAMESPACE))
VAL_FLAGS := $(if $(VALUES),-f $(VALUES))
OUT_FLAGS := $(if $(OUTFILE),> $(OUTFILE))

# ---------------------------- targets ------------------------------------
.PHONY: template tamplate package

# render the chart into YAML
template:
	helm template $(NS_FLAGS) $(VAL_FLAGS) --release-name $(NAME) . $(OUT_FLAGS)

# common miss-typing -> just run the real target
tamplate: template

# create a chart archive (.tgz)
package:
	helm package .


# helm template -n jitsi -f custom_values.yaml      --release-name huawei  . > abd.yaml