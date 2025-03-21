#!/bin/bash

PG_REPACK=(
    
    "17,1.5.2"
)

# Check command exist function
_command_exists() {
    type "$1" &> /dev/null
}

if _command_exists docker; then
    DOCKER_BIN=$(which docker)
else
    echo "ERROR: Command 'docker' not found."
    exit 1
fi

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "** Trapped CTRL-C"
    exit 1
}

#${DOCKER_BIN} login -u XXXXX -p YYYYY

for DATA in ${PG_REPACK[@]}; do
    PG_VER=$(echo "${DATA}" | awk -F',' '{print $1}')
    PGREPACK_VER=$(echo "${DATA}" | awk -F',' '{print $2}')
    echo "Docker build image 'pg-repack:${PGREPACK_VER}', postgres v${PG_VER}..."
    ${DOCKER_BIN} build -t cherts/pg-repack:${PGREPACK_VER} --no-cache --progress=plain -f ${PG_VER}/Dockerfile ${PG_VER}
    if [ $? -eq 0 ]; then
	echo "Done build image."
        #echo "Docker push image 'pg-repack:${PGREPACK_VER}'..."
        #${DOCKER_BIN} push cherts/pg-repack:${PGREPACK_VER}
    else
        echo "ERROR: Failed build image 'pg-repack:${PGREPACK_VER}', postgres v${PG_VER}"
        exit 1
    fi
done
