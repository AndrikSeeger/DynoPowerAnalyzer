clc
clear
close all

%% Configuration

% Overall gear ratio between test bench drive shaft and crankshaft
transFac = 3.0*46/21;

% Moment of inertia before the measurement shaft
inertiaMoment = 0.006406; % in kg*m^2

% Maximum RPM variation for power curve calculation
revRange = 0.25; % in rpm

% Path to folder containing measurement files
measPath = "Messdaten";

% Names of the measurement files
files = [
         "Analog - 11.11.2024 14-00-53.30038.csv"; 
         "Analog - 11.11.2024 14-03-11.74541.csv";
         "Analog - 11.11.2024 14-08-16.79412.csv";
         "Analog - 11.11.2024 14-25-01.15012.csv";
         "Analog - 11.11.2024 15-07-34.78143.csv";
         "Analog - 11.11.2024 15-16-03.45482.csv";
         "Analog - 11.11.2024 15-18-13.43112.csv";
         "Analog - 11.11.2024 15-36-51.94659.csv";
         "Analog - 11.11.2024 15-38-11.76318.csv";
         "Analog - 11.11.2024 16-01-15.53369.csv";
         "Analog - 11.11.2024 16-21-06.62823.csv";
         "Analog - 11.11.2024 16-29-49.31321.csv"
         ];

% Description of the engine configurations of the measurement files
description = [
               "HD109, TP On-Off";
               "HD109, Idle"; 
               "HD109, Full Load";
               "HD109, Full Load";
               "HD115, Full Load";
               "HD113, Full Load";
               "HD113, Choke, Full Load";
               "HD107, Full Load";
               "HD107, Choke, Full Load";
               "HD109, External Fan, Full Load";
               "HD109, 5° CA advanced, External Fan, Full Load";
               "HD109, 5° CA retarded, External Fan, Full Load"
               ];

% Configuration warnings
warning('off','MATLAB:table:ModifiedAndSavedVarnames');

% Initialization
measDataRaw = cell(size(files,1),1); 
measDataOpt = cell(size(files,1),1);

%% Load and process measurement data from all files
for i = 1:size(files,1)
    measDataRaw(i,1) = {readtable(strcat(filesep,measPath,filesep,files(i)))}; % Read measurement file    
    measData = measDataRaw{i,1}; % Set current measurement data
    
    measData.Properties.VariableNames = cellfun(@extractColNames, measData.Properties.VariableDescriptions); % Adjust column names
    
    % Standardize column format (format may vary depending on measurement duration)
    if ~iscell(measData.Time_s)
        measData.Time_s = num2cell(measData.Time_s);
    end
   
    measData.Time_s = cellfun(@convTime, measData.Time_s); % Convert time signal to seconds
    sampleTime = mean(diff(measData.Time_s)); % Determine actual sampling rate
    
    % Remove start offsets for measurement number and time signal
    measData.Measurement = measData.Measurement - measData.Measurement(1) + 1;
    measData.Time_s = measData.Time_s - measData.Time_s(1);
    
    % Correct torque signal due to rotational inertia before the sensor
    % M = J * alpha with J = 0.006406 kg*m^2
    measData.("AngularVelocity_rad/s") = 2 * pi * measData.("RPM") / 60; % Calculate angular velocity
    measData.("AngularAcceleration_rad/s^2") = [0;diff(measData.("AngularVelocity_rad/s")) ./ diff(measData.Time_s)]; % Calculate angular acceleration
    inertiaOffset = inertiaMoment * measData.("AngularAcceleration_rad/s^2"); % Calculate resulting inertia torque
    measData.CorrectedTorque_Nm = measData.Torque_Nm + inertiaOffset; % Correct torque signal for inertia
    
    measData.CorrectedBrakePower_kW = 2*pi*measData.("RPM")/60.*measData.CorrectedTorque_Nm/1000; % Calculate corrected brake power in kW
    measData.FilteredBrakePower_kW = optimizeSignal(measData.CorrectedBrakePower_kW, sampleTime); % Filter/smooth power signal
    
    plotPowerSignals(measData.Time_s, measData.CorrectedBrakePower_kW, measData.FilteredBrakePower_kW, 'Filtering Comparison') % Show filter effect
    
    [calcPowerCurveRevs, calcPowerCurvePower] = calcPowerCurve(transFac, revRange, measData.("RPM"), measData.FilteredBrakePower_kW, files(i)); % Calculate full load power curve over RPM
    plotPowerCurve(calcPowerCurveRevs, calcPowerCurvePower, description(i)); % Plot full load power curve over RPM

    measDataOpt(i,1) = {measData}; % Save calculated signal traces
end

%% Function to generate adapted column names
function modColName = extractColNames(orgColName)
    res = regexprep(orgColName,'[\s)]',''); % Remove spaces and closing parentheses
    modColName = {regexprep(res,'(','_')}; % Replace opening parentheses with underscore
end

%% Function to convert timestamps into a linear time axis in seconds
function numTimeStamp = convTime(timeStamp)
    if ~ischar(timeStamp) % Check time format
        % Time signal is already a float in seconds
        numTimeStamp = timeStamp; 
    else
        % Time signal is in 'minutes:seconds' character format

        % Parse timestamp
        parsedTimeValues = sscanf(timeStamp, '%d:%f'); 
        minutes = parsedTimeValues(1); 
        seconds = parsedTimeValues(2);

        numTimeStamp = minutes * 60 + seconds; % Convert time to seconds
    end
end

%% Function to filter/smooth the time-based power signal
function brakePowerSmoothed = optimizeSignal(brakePowerOrg, sampleTime)   
    % Smoothing: 3x moving median (100 ms) and 1x moving average (100 ms)
    brakePowerMedian1 = movmedian(brakePowerOrg, 0.1/sampleTime); % Moving median (100 ms)
    brakePowerMedian2 = movmedian(brakePowerMedian1, 0.1/sampleTime); % Moving median (100 ms)
    brakePowerMedian3 = movmedian(brakePowerMedian2, 0.1/sampleTime); % Moving median (100 ms)
    brakePowerMedian3Mean1 = movmean(brakePowerMedian3, 0.1/sampleTime); % Moving average (100 ms)

    % Filtering: Butterworth (4th order, 5 Hz)
    [b,a] = butter(4, 5/(1/sampleTime/2), 'low');
    brakePowerButter = filtfilt(b,a,brakePowerOrg);
    
    % Averaging
    brakePowerSmoothed = (brakePowerMedian3Mean1 + brakePowerButter)/2;
end

%% Function to display unfiltered and filtered power signal over time
function plotPowerSignals(time, brakePowerOrg, brakePowerSmoothed, name)
    % Configure plot
    figure;
    breakPowerPlot = axes;
    hold(breakPowerPlot,"on");
    grid(breakPowerPlot,'minor');
    breakPowerPlot.FontSize = 18; 
    xlabel(breakPowerPlot, 'Time in s','FontSize', 24);
    ylabel(breakPowerPlot, 'Power in kW','FontSize', 24);
    title(breakPowerPlot, strcat("Engine Power Over Time – ", name), 'FontSize', 26);  
    
    % Plot unfiltered and filtered power signals over time
    plot(breakPowerPlot, time, brakePowerOrg, LineWidth=0.5);
    plot(breakPowerPlot, time, brakePowerSmoothed, LineWidth=3);   
    legend(breakPowerPlot, 'Unfiltered Power Signal', ['Average of 3x Moving Median (100 ms) + 1x Moving Average (100 ms)' newline 'and Butterworth (4th Order, 5 Hz)'], 'FontSize', 24);

    hold(breakPowerPlot,"off");
end

%% Function to calculate full load power curve over RPM
function [powerCurveRevs, powerCurvePower] = calcPowerCurve(transFac, revRange, revSignal, powerSignal, fileName)    
    % Initialization
    powerCurveRevs = [];
    powerCurvePower = [];
    
    % Calculate full load curve
    for currentRevs = 1:8:max(revSignal)
   
        % Determine max power (full load) for given RPM
        revFitFilter = abs(revSignal-currentRevs)<revRange; % Create filter for RPM values
        revFit = revSignal(revFitFilter); % Get matching RPM values
        powerFit = powerSignal(revFitFilter); % Get associated power values
        [maxPower,maxPowerIdx] = max(powerFit); % Determine maximum power value
        minRevMaxPower = min(revFit(maxPowerIdx)); % Adjust RPM value in case of deviation
    
        % Check RPM deviation
        [val,~] = min(abs(revSignal-currentRevs));
        if(val > 0.25) 
            % No power value found within tolerance range
            disp(strcat(fileName, ": No value for ", num2str(currentRevs), " rpm")); % Output message
        else
            % Power value for RPM found
            powerCurveRevs = [powerCurveRevs;minRevMaxPower]; % Save power value
            powerCurvePower  = [powerCurvePower;maxPower]; % Save RPM value
        end
    end
    
    powerCurveRevs = powerCurveRevs * transFac; % Convert drive shaft speed to engine speed
end

%% Function to display full load power curve over RPM
function plotPowerCurve(revBand, powerBand, measDescription)
    % Configure plot
    figure;
    powerCurvePlot = axes;
    hold(powerCurvePlot,"on");
    grid(powerCurvePlot,'on');
    grid(powerCurvePlot,'minor');
    powerCurvePlot.FontSize = 18; 
    title(powerCurvePlot,'Power Curve', 'FontSize', 26);
    xlabel(powerCurvePlot, 'RPM','FontSize', 24)
    ylabel(powerCurvePlot, 'Power in kW','FontSize', 24)
    colororder("glow12")
    xlim([1000 9000]);
    ylim([1 4.5])

    powerBandSmooth = movmean(powerBand,30); % Smooth for visual display
    plot(powerCurvePlot, revBand, powerBandSmooth, LineWidth=2.0); % Plot full load power curve
    legend(powerCurvePlot, measDescription, 'FontSize', 24); % Label power curve
end
