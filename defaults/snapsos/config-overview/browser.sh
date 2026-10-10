STRING="$1"

KEY=$(echo "$STRING" | cut -d '=' -f1 )

if [ "$KEY" == "bind" ]; then
    KEY=$(echo "$STRING" | cut -d ',' -f 1,2,3 | sed 's/bindl/bind/' | sed 's/binds/bind/' | sed 's/bindr/bind/' | sed 's/binds/bind/' | sed 's/bindp/bind/' | sed 's|=.*,.*,|=MOD,KEY,|g' | sed 's/ //g' )
fi


LINK=$(cat ~/.config/snapsos/config-overview/options.list | grep " $KEY "  | cut -d '|' -f4)

firefox --new-tab $LINK
