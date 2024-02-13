#! /bin/bash
DIR='/mnt/docker/antrean-layanan-php/sources'
ROOT_DIR='/mnt/docker/antrean-layanan-php'
BRANCH='production'
APPNAME='Antrean Layanan'
CONTAINER_NAME='antrean-layanan-php'

if git -C "${DIR}" fetch origin "${BRANCH}" && 
[ `git -C "${DIR}" rev-list HEAD...origin/"${BRANCH}" --count` != 0 ]
then
    echo "new update available.."
    #git -C "${DIR}" pull origin  "${BRANCH}" &&
    git -C "${DIR}" reset --hard origin/"${BRANCH}"
    echo "-------------------------------" &&
    cd "${ROOT_DIR}" &&
    sleep 2 &&
    echo Check if container ${CONTAINER_NAME} is running? &&
    sleep 2 &&
    if [ "$(docker inspect -f '{{.State.Running}}' ${CONTAINER_NAME} 2>/dev/null)" = "true" ]; 
        then 
            echo Container ${CONTAINER_NAME} is online; 
            docker build . --build-arg DOC_ROOT=sources -t app/antrean-layanan-php:latest &&
            docker tag app/antrean-layanan-php:latest registry1.rsabhk.co.id:5080/rsabhk/antrean-layanan-php:latest &&
            docker push registry1.rsabhk.co.id:5080/rsabhk/antrean-layanan-php:latest &&
            sleep 1 &&
            docker-compose down && 
            sleep 2 &&
            docker-compose up -d --build &&
            echo "docker $APPNAME update!!" &&
            # docker-compose restart &&
            sleep 2
        else 
            echo Container ${CONTAINER_NAME} is offline &&
            echo Bring up container ${CONTAINER_NAME} &&
            docker-compose up -d --build &&
            echo "Container ${CONTAINER_NAME} is online"
    fi
else
    echo "no new update" &&
    if [ "$(docker inspect -f '{{.State.Running}}' ${CONTAINER_NAME} 2>/dev/null)" = "true" ]; 
        then 
            echo Container ${CONTAINER_NAME} is online; 
            sleep 1
        else 
            echo Container ${CONTAINER_NAME} is offline &&
            echo Bring up container ${CONTAINER_NAME} &&
            docker-compose up -d --build &&
            echo "Container ${CONTAINER_NAME} is online"
    fi
    sleep 1
fi

