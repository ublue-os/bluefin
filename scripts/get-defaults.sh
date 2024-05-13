#!/usr/bin/bash
#shellcheck disable=SC2154

# If image has -dx, assume they want the target to be dx and that version might be $2
if [[ ${image} =~ "-dx" ]]; then
    image=$(cut -d - -f 1 <<< "${image}") 
    version=${target}
    target="dx"
fi

# if no image, bluefin
if [[ -z "${image}" ]]; then
    image="bluefin"
fi

# if no target, base
if [[ -z "${target}" ]]; then
    target="base"

# if $2 is numeric, assume that is version and target is base
elif [[ ${target} =~ ^[0-9]+$ ]]; then
    version=${target}
    target="base"
fi

# if no version, bluefin is GTS, Aurora is Latest
if [[ -z "${version}" ]]; then
    if [[ "${image}" =~ "bluefin" ]]; then
        version=${gts}
    elif [[ "${image}" =~ "aurora" ]]; then
        version=${latest}
    fi
# if gts then convert to just variable ${gts}, same with Latest
elif [[ ${version} =~ "gts" ]]; then
    version=${gts}
elif [[ ${version} =~ "latest" ]]; then
    version=${latest}
fi
