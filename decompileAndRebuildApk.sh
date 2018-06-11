#!/bin/bash

str=$1
size=${#str}
suff=4
size=$((size - suff))
app=$(echo $str | cut -c 1-$size)
echo $app

echo "Decompiling apk file..."
apktool d $str -f

if [ -d "$app" ]; then
    echo "Rebuilding apk file..."
    apktool build $app
    dist="$app/dist/"
    cd $dist

    outapk="out.apk"
    if [ -f $outapk ]; then
        rm $outapk
        echo "$outapk previous version removed."
    fi

    echo "Aligning apk file..."
    align=$(zipalign -f -v 4 $str $outapk)
    rm $str
    substring="Verification successful"
    if [[ "$align" =~ $substring ]]; then
        echo "$outapk aligned."
	echo "Signing apk file..."
        sign=$(jarsigner -tsa http://timestamp.comodoca.com/rfc3161 -sigalg SHA1withRSA -digestalg SHA1 -keystore keystore.jks -storepass storepass $outapk keyAlias)
	substring="jar signed."
	if [[ "$sign" =~ $substring ]]; then
            echo "$outapk signed"
        fi
    fi
    echo "Coping new apk to initial folder..."
    finalapk=$app"_Rebuild.apk"
    cd ../..
    cp $dist$outapk $finalapk
    echo "The rebuilt apk is"
    realpath $finalapk
else
    echo "Usage: decompileAndRebuildApk.sh apkfile"
fi
