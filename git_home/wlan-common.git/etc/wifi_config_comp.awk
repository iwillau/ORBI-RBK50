BEGIN {
    FS="="
    file1_line=0
    file2_line=0
    wifi_device_exist[0]=0
    wifi_device_exist[1]=0
    wifi_device_exist[2]=0
    wifi_device_name[0]="wifi0"
    wifi_device_name[1]="wifi1"
    wifi_device_name[2]="wifi2"
    wifi_vif_wps_change[0]=0
    wifi_vif_security_change[0]=0
    wifi_vif_other_change[0]=0
    file2_vir_iface[0]=""
}

function is_security_setting(item){
    if (item == "encryption" ||
        item == "ssid" ||
        item == "server" ||
        item == "port" ||
        match(item, "key"))
        return 1
    return 0
}

function is_wps_setting(item){
    if (item == "wps_pin" ||
        item == "ap_setup_locked" ||
        item == "wps_state" ||
        item == "wps_config" ||
        item == "wps_device_name")
        return 1
    return 0
}

function parse_wireless_item(items, status_str){

    item_n = split(items, item, ".")

    # TODO: Right now, only basic item[2] is checked to tell wifi device or vif
    # (virtual interface) is changed, but we can add more case to specify item[3] to
    # provide more detailed information.

    for (i in wireless_type){
        if (item[2] == wireless_type[i]){
            if ( item[3] != "module_reload" && item[3] != "total_change_amount" ){
                wifi_device_change[wireless_type[i]]++
                if (debug)
                    printf "[%-8s] Driver parameter change for item %s\n", status_str, items
            }else
                if (debug)
                    printf "[%-8s] Skiped module_reload or total_change_amount for %s\n", status_str, wireless_type[i]
            # no matter this change is for wifi0 or wifi1, we just calculate once if driver type is same.
            break
        }
    }
}

!wifi_device_exist[0] && $1 ~ /wireless.wifi0/ {
    wifi_device_exist[0]=1
    if (debug >= 2)
        print "WiFi 0 detected by " $0
}

!wifi_device_exist[1] && $1 ~ /wireless.wifi1/ {
    wifi_device_exist[1]=1
    if (debug >= 2)
        print "WiFi 1 detected by " $0
}

!wifi_device_exist[2] && $1 ~ /wireless.wifi2/ {
    wifi_device_exist[2]=1
    if (debug >= 2)
        print "WiFi 2 detected by " $0
}

$2 ~ /wifi[012]$/ {
    item_n = split($1, item, ".")
    wifi_index = substr($2, 5, 1)

    if (item[3] == "device"){
        vif_parent_device[item[2]] = wifi_index
        if (debug >= 2)
            printf "Added %s to WiFi%d\n", item[2], wifi_index
    }
}

$2 ~ /'wifi[012]'$/ {
    item_n = split($1, item, ".")
    wifi_index = substr($2, 6, 1)

    if (item[3] == "device"){
        vif_parent_device[item[2]] = wifi_index
        if (debug >= 2)
            printf "Added %s to WiFi%d\n", item[2], wifi_index
    }
}

$1 ~ /wireless.wifi[012].type$/ {
    item_n = split($1, item, ".")
    wifi_index_n = split($2, wifi_index, "'")

    wireless_type[item[2]] = wifi_index[2]
    if (debug >= 2)
        printf "Added %s to Driver type %s\n", item[2], wireless_type[item[2]]
}

FNR == NR {
    file1[$1]=$0
    file1_all[$1]=$0
    # count line of file 1
    file1_line=NR

    if (debug >= 3)
        print $0
    next
}  

FNR != NR {
    # count line of file 2
    file2_line=FNR
}


$2 ~ /^wifi-iface$/ {
    item_n = split($1, item, ".")

    # if the number of items is 3, then wifi-iface is the value of some option. This
    # kind of case should be ignored.
    if (item_n == 2){
        file2_vir_iface[item[2]] = item[2]
        if (debug >= 2)
            printf "Added virtual interface %s\n", item[2]
    }
}

file1[$1] {
    file2[$1]=$0
    if (file1[$1] != file2[$1]){
        # Case 1: Same items on both files, but value is changed.
        parse_wireless_item($1, "CHANGED")
    }
    delete file1_all[$1]
    next
}

{
    # Case 2: Item exists in file 2, but does not exist in file 1.
    parse_wireless_item($1, "ADDED")
}

END {
    for (x in file1_all){
        # Case 3: Items exists in file 1, but does not exist in file 2.
        parse_wireless_item(x, "DELETED")
    }
    if (debug >= 2){
        printf "Line of file1 = %d, Line of file2 = %d\n", file1_line, file2_line
    }

    driver_type_hit=0
    for (i in wifi_device_change){
        driver_type_hit=1
        wifi_device_change_total += wifi_device_change[i]
        if (wifi_device_change[i] > 0)
            system("uci set wireless."i".module_reload=1")
        else
            system("uci set wireless."i".module_reload=0")
    }
    # this is possible that if no change, wifi_device_change index will be null.
    if (driver_type_hit == 0){
        for (i in wireless_type)
            if (driver_type_hit == 0 && wireless_type[i] != "" ){
                system("uci set wireless."wireless_type[i]".module_reload=0")
                driver_type_hit=1
            }
    }

    for (i in file2_vir_iface){
        if (file2_vir_iface[i] != ""){
            if (debug >= 2){
                printf "WPS reload for [%s] = %d\n", i, wifi_vif_wps_change[i]
                printf "Security reload for [%s] = %d\n", i, wifi_vif_security_change[i]
            }
            wifi_vif_wps_change[i] = wifi_vif_wps_change[i] >= 1? 1:0
            wifi_vif_security_change[i] = wifi_vif_security_change[i] >= 1? 1:0
            system("uci set wireless."i".wps_reload="wifi_vif_wps_change[i])
            system("uci set wireless."i".security_reload="wifi_vif_security_change[i])
        }
    }

    system("uci commit wireless")
}
