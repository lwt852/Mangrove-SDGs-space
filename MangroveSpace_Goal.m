clear; clc; close all
load('Data_Main.mat')
load("SDG_Results_2001.mat");
load("SDG_Results_2011.mat");

%% Get Names of the SDG indicators
IndicatorNames = Table_Indicators_All.Properties.VariableNames(7:101);
IndicatorNames = string(IndicatorNames)';
% Define the pattern to search for, in this case, "n_sdg" followed by digits
pattern = 'n_sdg(\d+)';
% Extract the numbers that appear after "n_sdg" in each string using regexp
SDGnumbers = regexp(IndicatorNames, pattern, 'tokens');
% Convert the cell array of cell arrays to a simple cell array
SDGnumbers = [SDGnumbers{:}]';
% Convert the cell array of characters to a numeric array
SDGnumbers = cellfun(@str2double, SDGnumbers);
% Initialize output string array
SDGindicators = strings(size(IndicatorNames));
% Loop over input array and extract last string after "_"
for i = 1:numel(IndicatorNames)
    splitString = strsplit(IndicatorNames(i), '_');
    SDGindicators(i) = splitString(end);
end
% Remove "n_sdg" from each string
SDGnumindicators = erase(IndicatorNames, 'n_');
% FINNALLY, create a table for indicator names
Table_IndicatorNames = table(SDGnumbers, SDGindicators, SDGnumindicators, IndicatorNames, ...
    'VariableNames', {'Goal', 'Indicator', 'Goal_Indicator', 'full'});
clear SDGnumbers SDGindicators SDGnumindicators IndicatorNames IndicatorNames i

Table_indicatorFull=join(Table_IndicatorNames,Table_Indicators)

%% Get Names of the Mangrove indicators

Mangrove_Indicators=Mangrove_Indicators_07_16

MangroveIndicatorNames = Mangrove_Indicators.Properties.VariableNames(1:21);
MangroveIndicatorNames=string(MangroveIndicatorNames)';
Table_mangrove_names= table(MangroveIndicatorNames,'VariableNames',{'ISO3C'})

Table_mangrove_names.Goal_Indicator = cellfun(@(x) char(x),Table_mangrove_names.ISO3C,'UniformOutput',false);
Mangrove_names.Goal_Indicator = cellfun(@(x) char(x),Mangrove_names.ISO3C,'UniformOutput',false);

Table_Mangrove_Names=innerjoin(Table_mangrove_names,Mangrove_names,'keys','Goal_Indicator')
Table_Mangrove_Names.Goal=repmat({'m'}, height(Table_Mangrove_Names), 1)
Table_Mangrove_Names.Goal = cellfun(@(x) char(x),Table_Mangrove_Names.Goal,'UniformOutput',false);
Table_Mangrove_Names.full= Table_Mangrove_Names.Goal_Indicator

%% organize and combine the mangrove-SDG table
Table_Mangrove_Names=Table_Mangrove_Names(:,[15 2 4 5 16])
Table_indicatorFull=Table_indicatorFull(:,[1 3 5 6 4]) 
Table_indicatorFull.Goal = num2cell(Table_indicatorFull.Goal)

Table_full=[Table_Mangrove_Names;Table_indicatorFull]
%Table_full=outerjoin(Table_indicatorFull,Table_Mangrove_Names,'keys',{'Goal_Indicator','indicator_name','description'})

%% sort the mangrove-SDG table into the indicator-order
MangroveIndicatorFullNames = Mangrove_Indicators.Properties.VariableNames();

MangroveIndicatorFullNames=string(MangroveIndicatorFullNames)';
Table_mangrove_Fullnames= table(MangroveIndicatorFullNames,'VariableNames',{'full'})

%Table_mangrove_Fullnames.Goal_Indicator = cellfun(@(x) char(x),Table_mangrove_Fullnames.ISO3C,'UniformOutput',false);

Table_full_0716=join(Table_mangrove_Fullnames,Table_full)
%% Export table to Excel file
writetable(Table_full_0716, 'Table_full_07_16.xlsx');
writetable(Table_full_0716, 'Table_full_07_16.csv');

%% get the goal level nodes.
Mangrove_Goals=Mangrove_Goals_07_16
MangroveGoalNames = Mangrove_Goals.Properties.VariableNames;
MangroveGoalNames=string(MangroveGoalNames)';
Table_MangroveGoal=table(MangroveGoalNames,  'VariableNames', {'Id'})
writetable(Table_MangroveGoal, 'MangroveGoalTable_07_16.csv');
%% Get the 2016 data

Table_Goals_2016 = Table_Goals_All(Table_Goals_All.year==2016,:);
Table_Indicators_2016 = Table_Indicators_All(Table_Indicators_All.year==2016,:);
% Check if the country order is correct for the table we just got
is_equal_Table_Goals = strcmp(Table_Regions.country, Table_Goals_2016.country);
is_equal_Table_Indicators = strcmp(Table_Regions.country, Table_Indicators_2016.country);
if min([min(is_equal_Table_Goals), min(is_equal_Table_Indicators)]) ~= 1 % Wrong
    disp("Country order is wrong. Check!")
end

%% get the mangrove data
% Load data from CSV file into a table
loss_2016 = readtable('loss_2016.csv');

%combine SDGs with mangroves

FullTable_Goals_2016=innerjoin(loss_2016,Table_Goals_2016, 'keys','country')
FullTable_Indicators_2016=innerjoin(loss_2016,Table_Indicators_2016, 'keys',{'country'})

%% Get the 2016 data matrix to feed into the function 
% Each column is a goal or indicator
% Each row is a country
RegionGoals_2016 = FullTable_Goals_2016(:,[2 3 10:end]); % For goals
RegionIndicators_2016 = FullTable_Indicators_2016(:,[2 3 9:end]); % For indicators
% Convert table to matrix
RegionGoals_2016 = table2array(RegionGoals_2016);
RegionIndicators_2016 = table2array(RegionIndicators_2016);
%% Calculate the SDG space network! 2016
% Here we could have missing data, but the function can do it!
Net_Goal_ProductSpace_2016 = NetworkSpace(RegionGoals_2016,'Product Space');
Net_Indicator_ProductSpace_2016 = NetworkSpace(RegionIndicators_2016,'Product Space');

% Calculate the correlation network, for possible comparison
Net_Goal_Correlation_2016 = NetworkSpace(RegionGoals_2016,'Correlation');
Net_Indicator_Correlation_2016 = NetworkSpace(RegionIndicators_2016,'Correlation');

% Save the above variables
writematrix(Net_Goal_ProductSpace_2016, "Net_Goal_ProductSpace_2016.csv");
writematrix(Net_Indicator_ProductSpace_2016, "Net_Indicator_ProductSpace_2016.csv");
writematrix(Net_Goal_Correlation_2016, "Net_Goal_Correlation_2016.csv");
writematrix(Net_Indicator_Correlation_2016, "Net_Indicator_Correlation_2016.csv");



















