# run script as 'sh launch.sh hover:1.0'

REPO='https://github.com/uit-hdl/hovernet-pipeline.git'

# Hover mountpoint location
MOUNTPOINT='/Data'

# Profile by default ['hv_consep', 'hv_pannuke']
PROFILE='hv_consep'

if [ ! -z "$1" ]
then
docker run --shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 \
        --gpus all --rm -it \
        -v ${MOUNTPOINT}/hover_mountpoint/output/:/data/output/ \
        -v ${MOUNTPOINT}/hover_mountpoint/input/:/data/input \
	-e H_PROFILE=${PROFILE} \
        $1 bash -c \
	"git clone ${REPO}; \
	cd hover_net; \
	git fetch --all; git reset --hard origin/master; cd ./src/; \
	bash"
fi

