#!/bin/bash

# REPO-DIR: Path for arma3-repository
REPO_DIR=""
# REPO-SSH-URL: Using ssh-URL from Git-Repository
REPO_URL=""
# CONFIGURE BRANCH 
BRANCH=""
# DESTINATION-DIR of mpmissions-directory to *.pbo-files
DEST_DIR=""
# USER to run Arma-Server
ARMA_USER=""
# USERGROUP to run Arma-Server
ARMA_GROUP=""
# SYSTEMD_NAME - Name of Arma3-SystemD-Service
SYSTEMD_NAME=""
# TRUE or FALSE - Restart Arma-Server after restart
AUTO_RESTART=False

restart_server_if_required() {
    if [ "$AUTO_RESTART" = True ]; then
        echo "Restarting Arma3 server..."
        systemctl restart "$SYSTEMD_NAME"
    fi
}

copy_pbo_files() {
    echo "Copy pbo-files to $DEST_DIR"
    cp -R ${REPO_DIR}*.pbo "$DEST_DIR"
    chown -R ${ARMA_USER}:${ARMA_GROUP} $DEST_DIR
}

if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR"

    if [ -d ".git" ]; then
        echo "Check $BRANCH for changes..."
        git fetch origin $BRANCH

        CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

        if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
            echo "Switch to $BRANCH..."
            git checkout $BRANCH
        fi

        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse @{u})

        if [ "$LOCAL" = "$REMOTE" ]; then
            echo "No changes detected for branch $BRANCH"
        else
            echo "Changes for $BRANCH found, running deployment..."
            git pull

            if [ "$(ls -A ${REPO_DIR}*.pbo 2>/dev/null)" ]; then
                copy_pbo_files
                restart_server_if_required
            else
                echo "No .pbo files in $REPO_DIR found."
            fi
        fi
    else
        echo "Directory is not a valid GIT-Repository, deleting the directory..."
        mv "$REPO_DIR" "${REPO_DIR}_backup_$(date +%Y%m%d%H%M%S)"
        git clone --branch $BRANCH "$REPO_URL" "$REPO_DIR"

        if [ "$(ls -A ${REPO_DIR}*.pbo 2>/dev/null)" ]; then
            copy_pbo_files
            restart_server_if_required
        else
            echo "No .pbo files in $REPO_DIR found."
        fi
    fi
else
    echo "Directory does not exist, cloning repository..."
    git clone --branch $BRANCH "$REPO_URL" "$REPO_DIR"

    if [ "$(ls -A ${REPO_DIR}*.pbo 2>/dev/null)" ]; then
        copy_pbo_files
        restart_server_if_required
    else
        echo "No .pbo files in $REPO_DIR found."
    fi
fi

echo "Operation completed. Have fun and play hard but fair!"
