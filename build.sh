#!/bin/bash

set -e

# Decompile with Apktool (decode resources + classes)
wget -q https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_2.12.0.jar -O apktool.jar
java -jar apktool.jar d iceraven.apk -o iceraven-patched  # -s flag removed
rm -rf iceraven-patched/META-INF
rm -rf iceraven-patched/assets/extensions/ads
rm -rf iceraven-patched/assets/extensions/search

# Color patching
sed -i 's/<color name="fx_mobile_layer_color_1">.*/<color name="fx_mobile_layer_color_1">#ff000000<\/color>/g' iceraven-patched/res/values-night/colors.xml
sed -i 's/<color name="fx_mobile_layer_color_2">.*/<color name="fx_mobile_layer_color_2">@color\/photonDarkGrey90<\/color>/g' iceraven-patched/res/values-night/colors.xml
sed -i 's/<color name="fx_mobile_action_color_secondary">.*/<color name="fx_mobile_action_color_secondary">#ff25242b<\/color>/g' iceraven-patched/res/values-night/colors.xml
sed -i 's/<color name="button_material_dark">.*/<color name="button_material_dark">#ff25242b<\/color>/g' iceraven-patched/res/values/colors.xml
sed -i 's/1c1b22/000000/g' iceraven-patched/assets/extensions/readerview/readerview.css
sed -i 's/eeeeee/e3e3e3/g' iceraven-patched/assets/extensions/readerview/readerview.css

# Smali patching
sed -i 's/ff1c1b22/ff15141a/g' iceraven-patched/smali*/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff2b2a33/ff000000/g' iceraven-patched/smali*/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff42414d/ff15141a/g' iceraven-patched/smali*/mozilla/components/ui/colors/PhotonColors.smali
sed -i 's/ff52525e/ff15141a/g' iceraven-patched/smali*/mozilla/components/ui/colors/PhotonColors.smali

# Error page background
sed -i 's/--background-color: #15141a/--background-color: #000000/g'	'iceraven-patched/assets/low_and_medium_risk_error_style.css'
sed -i 's/background-color: #1c1b22/background-color: #000000/g'	'iceraven-patched/assets/extensions/readerview/readerview.css'
sed -i 's/mipmap\/ic_launcher_round/drawable\/ic_launcher_foreground/g' iceraven-patched/res/drawable-v23/splash_screen.xml
sed -i 's/160\.0dip/200\.0dip/g' iceraven-patched/res/drawable-v23/splash_screen.xml

# Move new tab button to center
sed -i 's/android:layout_gravity="end|bottom|center"/android:layout_gravity="center_horizontal|bottom|center"/g' iceraven-patched/res/layout/component_tabstray3_fab.xml

sm1="smali/org/mozilla/geckoview/GeckoRuntimeSettings\$Builder.smali"
sm2="smali_classes2/org/mozilla/geckoview/GeckoRuntimeSettings\$Builder.smali"
sm3="smali_classes3/org/mozilla/geckoview/GeckoRuntimeSettings\$Builder.smali"
sm4="smali_classes4/org/mozilla/geckoview/GeckoRuntimeSettings\$Builder.smali"
for sm in $sm1 $sm2 $sm3 $sm4; do
	if [ -f "$sm" ]; then
		# Find line number of the method 'aboutConfigEnabled'
		line=$(grep -n 'aboutConfigEnabled' "$sm" | cut -d: -f1)
		# Insert 'const p1, true', after the method definition.
		# This will enable about:config by default.
		if [ -n "$line" ]; then
			# Insert the line after the method definition
			sed -i "${line}a\    const p1, 0x1" "$sm"
			echo "[INFO] Patching $sm"
		else
			echo "[ERROR] Method 'aboutConfigEnabled' not found in $sm"
		fi
	fi
done

# Recompile the APK
java -jar apktool.jar b iceraven-patched -o iceraven-patched.apk --use-aapt2
# Align and sign the APK
zipalign 4 iceraven-patched.apk iceraven-patched-signed.apk
# Clean up
rm -rf iceraven-patched iceraven-patched.apk
