@echo off
color 2

echo.
echo building ads
spcomp.exe -E -v0 ads.sp            -o"./compiled/ads.smx"

echo.
echo building ammostatus
spcomp.exe -E -v0 ammostatus.sp     -o"./compiled/ammostatus.smx"

echo.
echo building antiafk
spcomp.exe -E -v0 antiafk.sp        -o"./compiled/antiafk.smx"

echo.
echo building anticheat
spcomp.exe -E -v0 anticheat.sp      -o"./compiled/anticheat.smx"

echo.
echo building infiniteweight
spcomp.exe -E -v0 infiniteweight.sp -o"./compiled/infiniteweight.smx"

echo.
echo building noaccessory
spcomp.exe -E -v0 noaccessory.sp    -o"./compiled/noaccessory.smx"

echo.
echo building nomapvote
spcomp.exe -E -v0 nomapvote.sp      -o"./compiled/nomapvote.smx"

echo.
echo building noobprotector
spcomp.exe -E -v0 noobprotector.sp  -o"./compiled/noobprotector.smx"

echo.
echo building stats
spcomp.exe -E -v0 stats.sp          -o"./compiled/stats.smx"

echo.
echo building supplypoint
spcomp.exe -E -v0 supplypoint.sp    -o"./compiled/supplypoint.smx"

echo.
echo building supporter
spcomp.exe -E -v0 supporter.sp      -o"./compiled/supporter.smx"

echo.
pause