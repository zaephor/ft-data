#!/bin/bash
exchange="${1}"
DAYS=${2:-30}

if [[ -z "${exchange}" ]]; then
	echo "Usage: ${0} <exchange> [day count]"
	exit -1
fi

function freqtrade {
	docker run --rm -v "${PWD}/${exchange}:/freqtrade/user_data/data/${exchange}" freqtradeorg/freqtrade:stable $@
}

function pairs {
	echo "Getting market pairs for ${exchange}"
	for x in "${PWD}/${exchange}/pairs.json" "${PWD}/${exchange}/pairs.new.json"; do
		if [[ -e "${x}" ]]; then
			rm "${x}"
		fi
	done
	freqtrade list-pairs --exchange "${exchange}" --print-json --all | tee "${PWD}/${exchange}/pairs.new.json"
	mv "${PWD}/${exchange}/pairs.new.json" "${PWD}/${exchange}/pairs.json"
}
function download {
	echo "Syncing ${exchange} for ${DAYS} days"
	# TODO get more ticker times
	freqtrade download-data --exchange "${exchange}" --days "${DAYS}"
}

pairs
download
