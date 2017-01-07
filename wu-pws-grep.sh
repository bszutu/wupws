#!/bin/bash

## JH: v1.0 - Weather Underground to pwsweather.com script test
## BKS: v.1.1 - remove dependency for jq and test on busybox so it will run on openwrt

WORKINGDIR=/tmp/pws

# this is to handle busybox to make sure the working directory exist after a reboot
mkdir -p $WORKINGDIR

# Wunderground API key
# Register for a free Stratus plan here: https://www.wunderground.com/weather/api
WUAPI=PutYourWUAPIKeyHere

# Wunderground PWS to pull weather from
# Navigate to your preferred weather station on Weather Underground and pull the pws:XXXXXXXXXX from the URL
# ex. https://www.wunderground.com/cgi-bin/findweather/getForecast?query=pws:KFLLAKEW61&MR=1
# ex. WUPWS would be the query value - "pws:KFLLAKEW61"
#WUPWS="pws:KFLLAKEW53"
WUPWS="pws:StationIDhereAndKeeptheQuotes"

#PWS station ID - sign up and create a station at pwsweather.com
PWSID=PutYourPWSStationIDhere

#PWS password - password for pwsweather.com
PWSPASS=PutYourPWSPasswordHere

#============================================================
#=
#=      NOT NECESSARY TO CHANGE ANY LINES BELOW
#=
#============================================================

# Construct & Execute Weather Underground API call
WUJSON=http://api.wunderground.com/api/$WUAPI/conditions/q/$WUPWS\.json
echo "Grabbing JSON using the following URL: $WUJSON"
echo ""
wget -O $WORKINGDIR/wu.json $WUJSON

# ALL json extractions below REQUIRE the jq cmd line tool - on Ubuntu 'apt-get install jq'
#
# extract observation time and convert to UTC
# jq .current_observation.observation_epoch wu.json |tr -d '"'
# TZ=UTC date -d @1459187921 +'%Y-%m-%d+%H:%M:%S'|sed 's/:/%3A/g'
PWSDATEUTC=$(TZ=UTC date -d @$(grep "observation_epoch" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ",") +'%Y-%m-%d+%H:%M:%S'|sed 's/:/%3A/g')
echo "PWSDATEUTC=$PWSDATEUTC"

# extract winddir
PWSWINDDIR=$(grep "wind_degrees" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ',')
echo "PWSWINDDIR=$PWSWINDDIR"

# extract windspeed
PWSWINDSPEEDMPH=$(grep "wind"_mph $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ',')
echo "PWSWINDSPEEDMPH=$PWSWINDSPEEDMPH"

# extract windgustmph
PWSWINDGUSTMPH=$(grep "wind_gust_mph" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ',')
echo "PWSWINDGUSTMPH=$PWSWINDGUSTMPH"

# extract tempf
PWSTEMPF=$(grep "temp_f" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ',')
echo "PWSTEMPF=$PWSTEMPF"

# extract hourly rainin - Hourly rain in inches
PWSRAININ=$(grep "precip_1hr_in" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ',')
echo "PWSRAININ=$PWSRAININ"


# extract daily rainin - Daily rain in inches
PWSDAILYRAININ=$(grep "precip_today_in" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ',')
echo "PWSDAILYRAININ=$PWSDAILYRAININ"

# extract baromin - Barometric pressure in inches
PWSBAROMIN=$(grep "pressure_in" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ',')
echo "PWSBAROMIN=$PWSBAROMIN"

# extract dewptf - Dew point in degrees f
PWSDEWPTF=$(grep "dewpoint_f" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ',')
echo "PWSDEWPTF=$PWSDEWPTF"

# extract humidity - in percent
PWSHUMIDITY=$(grep "relative_humidity" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ',' |tr -d '%')
echo "PWSHUMIDITY=$PWSHUMIDITY"

# extract solarradiation
PWSSOLARRADIATION=$(grep "solarradiation" $WORKINGDIR/wu.json | cut -d ":" -f 2 | tr -d '"' | tr -d ','|tr -d '-')
echo "PWSSOLARRADIATION=$PWSSOLARRADIATION"

# extract UV
PWSUV=$(grep "UV" $WORKINGDIR/wu.json | cut -d "," -f 1 | cut -d ":" -f 2 | tr -d '"' | tr -d ',')
echo "PWSUV=$PWSUV"

# construct PWS weather POST data string

PWSPOST="ID=$PWSID&PASSWORD=$PWSPASS&dateutc=$PWSDATEUTC&winddir=$PWSWINDDIR&windspeedmph=$PWSWINDSPEEDMPH&windgustmph=$PWSWINDGUSTMPH&tempf=$PWSTEMPF&rainin=$PWSRAININ&dailyrainin=$PWSDAILYRAININ&baromin=$PWSBAROMIN&dewptf=$PWSDEWPTF&humidity=$PWSHUMIDITY&solarradiation=$PWSSOLARRADIATION&UV=$PWSUV&softwaretype=wu_pws_ver1.0&action=updateraw"
#echo $PWSPOST

RESULT=$(wget -O /dev/null --post-data=$PWSPOST http://www.pwsweather.com/pwsupdate/pwsupdate.php)
echo wget -O /dev/null --post-data=$PWSPOST http://www.pwsweather.com/pwsupdate/pwsupdate.php

# retains 10 backup cycles for debugging
rm $WORKINGDIR/wu.json.10
mv $WORKINGDIR/wu.json.9 $WORKINGDIR/wu.json.10
mv $WORKINGDIR/wu.json.8 $WORKINGDIR/wu.json.9
mv $WORKINGDIR/wu.json.7 $WORKINGDIR/wu.json.8
mv $WORKINGDIR/wu.json.6 $WORKINGDIR/wu.json.7
mv $WORKINGDIR/wu.json.5 $WORKINGDIR/wu.json.6
mv $WORKINGDIR/wu.json.4 $WORKINGDIR/wu.json.5
mv $WORKINGDIR/wu.json.3 $WORKINGDIR/wu.json.4
mv $WORKINGDIR/wu.json.2 $WORKINGDIR/wu.json.3
mv $WORKINGDIR/wu.json.1 $WORKINGDIR/wu.json.2
mv $WORKINGDIR/wu.json $WORKINGDIR/wu.json.1
