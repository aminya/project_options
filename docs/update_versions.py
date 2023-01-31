# This script is called by the CI Pipeline on the master branch and on tag releases
#
#

import os
import requests
import json
import re

import argparse

parser = argparse.ArgumentParser(description='Get current versions.js file from the gitlab pages URL and extend the '
                                             'list of available versions with this jus built documentation.')
parser.add_argument('--version_file', metavar='version_file', type=str,
                    help='Path where the current and updated versions.js file should be stored.', required=True)
parser.add_argument('--folder', metavar='folder', type=str,
                    help='Folder name where the version is stored', required=True)
parser.add_argument('--version', metavar='version', type=str,
                    help='Version of the generated documentation', required=True)

args = parser.parse_args()

#var ar_versions = [
#    {
#        version: "master",
#        folder: "master",
#        has_pdf: "true",
#        pdf_name: "master.pdf"
#    },
#    {
#        version: "2.1.0@ar/stable",
#        folder: "2_1_0_ar_stable",
#        has_pdf: "true",
#        pdf_name: "2_1_0_ar_stable.pdf"
#    },
#]

versions = list()

if os.path.exists(args.version_file):
    with open(args.version_file, 'r') as file:
        js_data = file.read()
    if js_data.startswith("var ar_versions = "):
        js_data= js_data[len("var ar_versions = "):]
    versions = json.loads(js_data)

# Get branch name or tag name

ref_exists = False
for v in versions:
    if v['version'] == args.version:
        ref_exists = True
        print("Version already configured. Skipping update!")
        exit(0)

# Version is not yet in list, add it
versions.append({
    'version': args.version,
    'folder': args.folder,
    'has_pdf': False
})

is_semver = re.compile("^v?([0-9\.]+)([^0-9\.]*)?$")

def versionSortFunc(s):
    ma = is_semver.match(s['version'])
    if ma:
        ints = list(ma.group(1).split('.'))
        ints.append(ma.group(2))
        return ints
    else:
        return list(s['version'])

versions.sort(key=versionSortFunc, reverse=True)

new_js = "var ar_versions = " + json.dumps(versions, indent=2)

js_dir = os.path.dirname(args.version_file)
if not os.path.isdir(js_dir):
    os.makedirs (js_dir)
with open(args.version_file, 'w') as filetowrite:
    filetowrite.write(new_js)

print("File updated: " + args.version_file)



