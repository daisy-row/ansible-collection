#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
function usage {
    echo "Usage: renew_ca_tls_cert.sh [-i <component Name>] [-j <component Type>] [-k <action flag>]" 1>&2
    exit 1
}
OPTSTRING=":i:j:k:"
while getopts ${OPTSTRING} opt; do
    case "${opt}" in
        i)
            component_name=${OPTARG}
            ;;
        j)
            component_type=${OPTARG}
            ;;
        k)
            all_flag=${OPTARG}
            ;;
        :)
            echo "Option -${OPTARG} requires an argument."
            usage
            ;;
        ?)
            echo "Invalid option: -${OPTARG}."
            exit 1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))
echo "component_name = ${component_name}"
echo "component_type = ${component_type}"
echo "all_flag = ${all_flag}"
if [ -z "${all_flag}" ]; then
    set -x
    ansible-playbook 30-renew-ca-tls.yml --extra-vars "{\"component_type\":\"${component_type}\",\"component_name\":\"${component_name}\"}"
    set +x
else
    set -x
    ansible-playbook 26-renew-all-ca-tls.yml
    set +x
fi




