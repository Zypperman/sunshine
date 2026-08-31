#!/usr/bin/env bash
# 1. copy script to some new .sh file i.e. setup-env.sh
# 2. make script executable with below command:
# chmod +x setup-env.sh
# 3. run script with below command:
# ./setup-env.sh
set -e

REPO_URL="https://github.com/Zypperman/sunshine.git"
TEMP_DIR=$(mktemp -d)

# Set this to the name of your actual install script (e.g., setup.sh, bootstrap.sh)
INSTALL_SCRIPT_NAME="install.sh"

echo "=> Cloning dotfiles from Zypperman/sunshine..."
git clone --quiet --depth 1 "$REPO_URL" "$TEMP_DIR"

# 1. Apply the .devcontainer configuration
if [ -d "$TEMP_DIR/.devcontainer" ]; then
    echo "=> Copying .devcontainer configuration to the current repository..."
    # Using cp -a to preserve permissions and internal structure
    cp -a "$TEMP_DIR/.devcontainer" ./.devcontainer
    echo "=> .devcontainer configuration applied successfully."
else
    echo "=> Warning: No .devcontainer directory found in the sunshine repo."
fi

# 2. Trigger the install script
if [ -f "$TEMP_DIR/$INSTALL_SCRIPT_NAME" ]; then
    echo "=> Executing $INSTALL_SCRIPT_NAME..."
    
    # Navigate to the temp dir to run the script in its native context
    cd "$TEMP_DIR"
    chmod +x "$INSTALL_SCRIPT_NAME"
    ./"$INSTALL_SCRIPT_NAME"
    cd - > /dev/null
else
    echo "=> Error: Could not find '$INSTALL_SCRIPT_NAME' in the repository."
    echo "=> If your script has a different name, update the INSTALL_SCRIPT_NAME variable."
fi

# 3. Cleanup
echo "=> Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

echo "=> Setup complete! You can now reopen this project in your Dev Container."