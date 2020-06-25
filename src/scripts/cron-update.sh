#!/bin/sh

# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -xe

# Clone the repo into a temporary directory
TMPDIR=$(mktemp -d -t opencovid-$(date +%Y-%m-%d-%H-%M-%S)-XXXX)
git clone https://github.com/open-covid-19/data.git --single-branch -b master "$TMPDIR/opencovid"

# Install dependencies and run the update command in a Docker instance
docker run -v "$TMPDIR/opencovid":/opencovid -w /opencovid -i python:latest /bin/bash -s <<EOF
cd src
# Install locales
apt-get update && apt-get install -yq tzdata locales
locale-gen en_US.UTF-8
locale-gen es_ES.UTF-8
# Install Python dependencies
pip install -r requirements.txt
# Update all the data pipelines
python3 update.py --no-progress
# Get the files ready for publishing
python3 publish.py
EOF

# Upload the outputs to Google Cloud
gsutil -m cp -r "$TMPDIR/opencovid/output/snapshot" gs://covid19-open-data/
gsutil -m cp -r "$TMPDIR/opencovid/output/intermediate" gs://covid19-open-data/
gsutil -m cp -r "$TMPDIR/opencovid/output/public/v2" gs://covid19-open-data/

# Cleanup
rm -rf $TMPDIR