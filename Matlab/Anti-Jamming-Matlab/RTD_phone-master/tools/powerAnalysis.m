clc; clear all; close all;
fileName = 'H:\��������\��������\ģ������\20151225\SIM3#_RxRec20151225_091250.dat';
YYMMDD =  '20151225';
timeLength = 36000;
[satePara_BDS,satePara_GPS, Position, Time] = readGSV(fileName, YYMMDD, timeLength);
