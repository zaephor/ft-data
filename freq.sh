#!/bin/bash
action="${1}"
exchange="${2}"
ARG="${3}"

if [[ -z "${action}" || -z "${exchange}" ]]; then
	echo "Usage: ${0} <action> <exchange> [action-args]"
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

function update {
	if [[ -z "${ARG}" ]]; then
		ARG=30
	fi
	echo "Syncing ${exchange} for ${ARG} days"
	TICKERS=$(freqtrade list-timeframes --exchange "${exchange}" -1)
	for ticker in ${TICKERS}; do
		while [[ $(containerCount) -ge $(nproc) ]]; do
			sleep 1s
		done
		( freqtrade download-data --exchange "${exchange}" --days "${ARG}" -t ${ticker} ) &
		sleep 1s
	done
}

function backfill {
	if [[ -z "${ARG}" ]]; then
		ARG="20190101-"
	fi
	CONTAINER_LIMIT=$(( $(nproc) * 2 ))
	echo "Syncing ${exchange} for ${ARG} days"
	TICKERS=$(freqtrade list-timeframes --exchange "${exchange}" -1)
	for ticker in ${TICKERS}; do
		while [[ $(containerCount) -ge ${CONTAINER_LIMIT} ]]; do
			sleep 1s
		done
		( freqtrade download-data --exchange "${exchange}" --timerange "${ARG}" -t ${ticker} ) &
		sleep 1s
	done
}


pairs

case ${action} in
	"update")
		update
		;;
	"backfill")
		backfill
		;;
	*)
		echo "What?"
		;;
esac
