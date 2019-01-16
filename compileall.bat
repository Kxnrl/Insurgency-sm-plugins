@echo off
color 2

echo.
echo building ammostatus
spcomp.exe -E -v0 ammostatus.sp     -o"./compiled/ammostatus.smx"

echo.
echo building antiafk
spcomp.exe -E -v0 antiafk.sp        -o"./compiled/antiafk.smx"

echo.
echo building nomapvote
spcomp.exe -E -v0 nomapvote.sp      -o"./compiled/nomapvote.smx"

echo.
echo building noobprotector
spcomp.exe -E -v0 noobprotector.sp      -o"./compiled/noobprotector.smx"

echo.
pause