#!/bin/bash
# print_config.sh
# This script loads a configuration file (config.cfg),
# normalizes each variable assignment (removing spaces around '=' and replacing dashes with underscores in keys),
# evaluates and exports the variable, then prints them.

CONFIG_FILE="./config.cfg"


if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi


# in this loop , also replace <$key> in file templates/dev.tfvars.tpl and put the new file as templates/dev.tfvars
while IFS= read -r line || [ -n "$line" ]; do
    # Trim leading and trailing whitespace
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Skip empty lines and comments
    if [ -z "$trimmed" ] || [[ "$trimmed" == \#* ]]; then
        continue
    fi
    
    # Remove spaces around '=' so that "key   =   value" becomes "key=value"
    assignment=$(echo "$trimmed" | sed 's/[[:space:]]*=[[:space:]]*/=/')
    
    # Check if the line contains '='
    if [[ "$assignment" == *"="* ]]; then
        # Extract the original key (everything before the '=')
        orig_key=$(echo "$assignment" | cut -d '=' -f1)
        # Convert dashes to underscores in the key
        key=$(echo "$orig_key" | tr '-' '_')
        # Extract the value (everything after the '=')
        value=$(echo "$assignment" | cut -d '=' -f2-)
        
        # Validate that the key is now a valid shell variable name
        if [[ "$key" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            # Build a new assignment line and evaluate it
            eval "$key=$value"
            export "$key"
            # echo "$key" "$value"
            sed -i "s|<$key>|$value|g" $DEST_PATH_TERRAFORM
        else
            echo "Skipping invalid variable assignment: $assignment"
        fi
    fi
done < "$CONFIG_FILE"


# # ========================
# # Kubernetes Dashboard Deployment (if enabled)
# # ========================
# if [ "$get_dashboard_access" = true ]; then
#     mkdir -p admin-dashboard

#     # Generate and display a token for the service account
#     echo "Kubernetes Dashboard token is in file admin-dashboard/token.txt"
#     kubectl -n kubernetes-dashboard create token dashboard-admin-sa > admin-dashboard/token.txt

#     # Provide instructions for port-forwarding in a separate terminal
#     echo "To access the dashboard, run the following command in a separate terminal:"
#     echo "kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443" > admin-dashboard/url.txt
# fi

# ========================
# STUNner Gateway Deployment (if enabled)
# ========================
if [ "$add_stunner" = true ]; then
    # Add and update the STUNner Helm repository
    helm repo add stunner https://l7mp.io/stunner
    helm repo update

    # Install the STUNner Gateway Operator via Helm
    helm install stunner-gateway-operator stunner/stunner-gateway-operator \
      --create-namespace \
      --namespace stunner-system
fi


# ========================
# Install jitsi
# ========================
if [ "$add_jitsi" = true ]; then
    cp place_holder/custom_values.yaml values.yaml

    sed -i "s/<realm>/$realm/g" values.yaml

    # Retrieve the public hostname of the Jitsi service
    INGRESSIP=$domaine
    sed -i "s/<public-ingress-ip>/$INGRESSIP/g" values.yaml


    sed -i "s/<gateway-name>/$stunner_gateway_name/g" values.yaml

    sed -i "s/<stunner-public-ip>/$INGRESSIP/g" values.yaml

    # # Install Jitsi using the custom values file
    # helm install $release_name . -f values.yaml -n "$NAMESPACE"
fi