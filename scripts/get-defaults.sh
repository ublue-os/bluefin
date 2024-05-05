#!/usr/bin/bash
#shellcheck disable=SC2154

if [[ ${image} =~ "-dx" ]]; then
    image=$(cut -d - -f 1 <<< "${image}") 
    version=${target}
    target="dx"
fi
if [[ -z "${image}" ]]; then
    image="bluefin"
fi
if [[ -z "${target}" ]]; then
    target="base"
elif [[ ${target} =~ ^[0-9]+$ ]]; then
    version=${target}
    target="base"
fi
if [[ -z "${version}" ]]; then
    if [[ "${image}" =~ "bluefin" ]]; then
        version=${gts}
    elif [[ "${image}" =~ "aurora" ]]; then
        version=${latest}
    fi
elif [[ ${version} =~ "gts" ]]; then
    version=${gts}
elif [[ ${version} =~ "latest" ]]; then
    version=${latest}
fi