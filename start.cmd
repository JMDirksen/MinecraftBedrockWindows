@echo off
title MinecraftBedrock
:loop
start /d server /b /abovenormal /wait bedrock_server.exe
timeout /t 5
goto loop
