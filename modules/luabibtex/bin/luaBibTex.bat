@echo off

set baseFile=%1

lua -l luaBibTex -e main('%baseFile%')
