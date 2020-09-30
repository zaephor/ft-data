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
	freqtrade list-pairs --exchange "${exchange}" --quote BTC ETH USD --print-json > "${PWD}/${exchange}/pairs.new.json"
	mv "${PWD}/${exchange}/pairs.new.json" "${PWD}/${exchange}/pairs.json"
}

function containerCount {
	docker ps -aq | wc -l
}

function download {
	echo "Syncing ${exchange} for ${DAYS} days"
	TICKERS=$(freqtrade list-timeframes --exchange "${exchange}" -1)
	for ticker in ${TICKERS}; do
		while [[ $(containerCount) -ge $(nproc) ]]; do
			sleep 1s
		done
		( freqtrade download-data --exchange "${exchange}" --days "${DAYS}" -t ${ticker} ) &
		sleep 1s
	done
}

pairs
download
