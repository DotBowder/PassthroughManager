#!/bin/bash
# Passthrough Manager
# v1


QEMU_DIR="/etc/pve/qemu-server/";
#QEMU_DIR="./qemu-server/";
CONF_FILE="ptm.conf";

OVERWRITE="false";

VMID_PREV="";

while read line; do

	if [[ "$line" != \#* ]] && [[ "" != "$line"  ]]; then
		if [[ "$line" != "VMID	HPCI	NTH	NAME	ATTR" ]]; then

			VMID=$(echo "${line}" | awk -F "\t" '{print $1}');
			HPCI=$(echo "${line}" | awk -F "\t" '{print $2}');
			NTH=$( echo "${line}" | awk -F "\t" '{print $3}');
			NAME=$(echo "${line}" | awk -F "\t" '{print $4}' | awk -F "\"" '{print $2}');
			ATTR=$(echo "${line}" | awk -F "\t" '{print $5}');
			SLOT=$(lspci -nn | grep -F "${NAME}" | head -n $(("${NTH}"+1)) | tail -n 1 | cut -d " " -f 1);

			CUR=$(cat "${QEMU_DIR}/${VMID}.conf" | grep "hostpci${HPCI}: ");
			if [ "" != "$ATTR" ]; then
				ATTR=",${ATTR}";
			fi
			NEW="hostpci${HPCI}: 0000:${SLOT}${ATTR}";

			if [ "false" != "$OVERWRITE" ]; then
				if [ "" == "$CUR" ]; then
					# HostpciX doesn't exist: Append hostpcix to beginning of file.
					echo "$NEW" > "${QEMU_DIR}/tmp_${VMID}.conf";
					cat  "${QEMU_DIR}/${VMID}.conf" >> "${QEMU_DIR}/tmp_${VMID}.conf";
					mv   "${QEMU_DIR}/tmp_${VMID}.conf" "${QEMU_DIR}/${VMID}.conf";
				else
                                	# HostpciX exists: Replace hostpcix with sed.
					cat "${QEMU_DIR}/${VMID}.conf" | sed "s/^hostpci${HPCI}:.*$/${NEW}/g" > "${QEMU_DIR}/tmp_${VMID}.conf";
        	                        mv  "${QEMU_DIR}/tmp_${VMID}.conf" "${QEMU_DIR}/${VMID}.conf";
				fi
			else
				if [ "$VMID" != "$VMID_PREV" ]; then
					echo $VMID.conf;
				fi
				VMID_PREV="$VMID";
				echo $NEW;
			fi

		fi
	fi


done< <(cat ${CONF_FILE});
