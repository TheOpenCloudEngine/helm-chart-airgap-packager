#!/usr/bin/env bash

. "$(dirname "$0")/config.sh"

rm -rf ${OUTPUT_DIR}
echo "Deleted ${OUTPUT_DIR}"

rm -rf ${CHART_DIR}
echo "Deleted ${CHART_DIR}"

rm -rf ${IMAGES_DIR}
echo "Deleted ${IMAGES_DIR}"

