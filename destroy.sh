#!/bin/bash
# destroy.sh

# ========================
# Load configuration
# ========================
if [ -f ./config.cfg ]; then
    source ./config.cfg
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

# ========================
# Git branch switching based on environment
# ========================
if [ "$env" == "dev" ]; then
    git switch dev
elif [ "$env" == "prod" ]; then
    git switch main
else
    echo "Unknown enviremenent value: $env. Exiting."
    exit 1
fi

# ========================
# Jitsi Uninstallation (if enabled)
# ========================
if [ "$add_jitsi" = true ]; then
    echo "Uninstalling Jitsi..."
    helm uninstall $release_name -n "$NAMESPACE"
    # rm custom_values.yaml
fi

# ========================
# STUNner Uninstallation (if enabled)
# ========================
if [ "$add_stunner" = true ]; then
    echo "Uninstalling STUNner..."
    helm uninstall stunner-gateway-operator -n stunner-system || true
    kubectl delete namespace stunner-system --ignore-not-found=true
    kubectl delete crd gatewayconfigs.stunner.l7mp.io 2>/dev/null || true
    kubectl delete crd udproutes.stunner.l7mp.io 2>/dev/null || true
fi

# ========================
# Kubernetes Dashboard Uninstallation (if enabled)
# ========================
if [ "$get_dashboard_access" = true ]; then
    echo "Uninstalling Kubernetes Dashboard..."
    # Remove the token and URL files
    rm -rf admin-dashboard 2>/dev/null || true
    echo "Admin dashboard token and associated resources have been deleted."
fi


echo "Cleanup complete!"
